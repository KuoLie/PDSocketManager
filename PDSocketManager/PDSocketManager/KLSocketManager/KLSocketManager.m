//
//  KLSocketManager.m
//  PDSocketManager
//
//  Created by Macintosh HD on 2017/8/23.
//  Copyright © 2017年 Macintosh HD. All rights reserved.
//

#import "KLSocketManager.h"
#import "GCDAsyncSocket.h"
#import "GCDAsyncUdpSocket.h"
#import "Test.pbobjc.h"

#define KLSocketHost @"你的socket地址"
#define KLSocketPort 8000
#define KLSocketTimerTime 60
#define KLSocketTimerTag 200

/** socket断开状态 */
typedef enum : NSUInteger {
    /** 超时 */
    KLSocketOffLineOutTime,
    KLSocketOffLineByUser,
    KLSocketOffLineHome,
} KLSocketetOffLineType;

@interface KLSocketManager () <GCDAsyncSocketDelegate>

/** socket */
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

/** 服务器地址 */
@property (nonatomic, strong) NSString *socketHost;

/** 端口号 */
@property (nonatomic, assign) uint16_t socketPort;

/** 心跳计时器 */
@property (nonatomic, strong) NSTimer *socketTimer;

/** socket状态 */
@property (nonatomic, assign) KLSocketetOffLineType offlineType;

/** socket回调标识 */
@property (nonatomic, assign) NSInteger socketTag;

/** socket重连次数限定 */
@property (nonatomic, assign) NSInteger reconnectCount;

/** socket回调存储 */
@property (nonatomic, strong) NSMutableDictionary *socketDic;

/**
 心跳连接
 */
- (void)socketTimerConnectSocket;

- (void)startTimer;

@end

@implementation KLSocketManager

+ (KLSocketManager *)shareInstance{
    static KLSocketManager *manager = nil;
    static dispatch_once_t onceSocketToken;
    dispatch_once(&onceSocketToken, ^{
        manager = [[KLSocketManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.socketHost = KLSocketHost;
        self.socketPort = KLSocketPort;
        self.socketTag = 1;
        self.offlineType = KLSocketOffLineOutTime;
        self.reconnectCount = 1;
//        [self socketConnectHost];
    }
    return self;
}

// 连接
- (void)socketConnectHost{
    if (self.clientSocket.isConnected) {
        return;
    }
    [self cutOffSocket];
    self.offlineType = KLSocketOffLineOutTime;
    // 连接ip 端口
    NSError *error;
    [self.clientSocket connectToHost:self.socketHost onPort:self.socketPort viaInterface:nil withTimeout:-1 error:&error];
    NSLog(@"%@", error);
}

// 断开
- (void)cutOffSocket{
    [self.clientSocket disconnectAfterReadingAndWriting];
    if (self.socketTimer) {
        [self.socketTimer invalidate];
        self.socketTimer = nil;
    }
}

// 心跳
- (void)socketTimerConnectSocket {
    GetUser *user = [[GetUser alloc] init];
    user.openid = @"1";
    [self.clientSocket writeData:[user data] withTimeout:-1 tag:KLSocketTimerTag];
}

// 开始心跳
- (void)startTimer {
    if (self.socketTimer) {
        [self.socketTimer invalidate];
        self.socketTimer = nil;
    }
    self.socketTimer = [NSTimer scheduledTimerWithTimeInterval:KLSocketTimerTime target:self selector:@selector(socketTimerConnectSocket) userInfo:nil repeats:YES];
    [self.socketTimer fire];//执行
    [[NSRunLoop currentRunLoop] addTimer:self.socketTimer forMode:NSRunLoopCommonModes];
    [[NSRunLoop currentRunLoop] run];
}

/**
 向服务器发送数据
 */
- (void)socketWriteData:(NSData *)data andDelegate:(id <KLSocketManagerDelegate>)delegate {
    if (!self.clientSocket.isConnected) {
        [delegate socketRequstFail];
        return;
    }
    self.socketTag = self.socketTag > 1000000 ? 1 : self.socketTag + 1;
    NSLog(@"%zd", data.length);
    [self.clientSocket writeData:data withTimeout:-1 tag:self.socketTag];
}

#pragma mark - GCDAsyncSocketDelegate 
/** 已经连接 */
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"已经连接  %@", host);
    self.reconnectCount = 1;
    if (self.socketDic.count > 0) {
        for (NSString *key in self.socketDic.allKeys) {
            id <KLSocketManagerDelegate>delegate = self.socketDic[key];
            if ([delegate respondsToSelector:@selector(getData)]) {
                NSData *data = [delegate getData];
                [self.clientSocket writeData:data withTimeout:-1 tag:key.integerValue];
            }
        }
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startTimer) object:nil];
    [self performSelector:@selector(startTimer) withObject:nil afterDelay:KLSocketTimerTime];
}

/** 连接断开 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    // 先判断网络，网络不好情况下不重连
    
    // 不是用户主动断开就重连
    if (self.offlineType != KLSocketOffLineByUser) {
        if (self.reconnectCount > 64) {
            self.offlineType = KLSocketOffLineOutTime;
            [self.socketDic removeAllObjects];
        } else {
            self.reconnectCount *= 2;
            [self socketConnectHost];
        }
    }
}

/** 读取服务器数据 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSError *error;
    UserProfile *pro = [[UserProfile alloc] initWithData:data error:&error];
    
    // 继续监听
    [self.clientSocket readDataWithTimeout:-1 tag:KLSocketTimerTag];
}

/** 写入完成的回调 */
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    [self.clientSocket readDataWithTimeout:-1 tag:tag];
}

#pragma mark - 获取当前时间
- (NSData *)currentDatedata {
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"YYYY/MM/dd hh:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:currentDate];
    return [dateString dataUsingEncoding:NSUTF8StringEncoding];
}

- (GCDAsyncSocket *)clientSocket {
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _clientSocket;
}

- (NSMutableDictionary *)socketDic {
    if (!_socketDic) {
        _socketDic = [[NSMutableDictionary alloc] init];
    }
    return _socketDic;
}

@end
