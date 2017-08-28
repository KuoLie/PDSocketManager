//
//  KLSocketManager.h
//  PDSocketManager
//
//  Created by Macintosh HD on 2017/8/23.
//  Copyright © 2017年 Macintosh HD. All rights reserved.
//

#import <Foundation/Foundation.h>

/** socket通讯数据接收 */
@protocol KLSocketManagerDelegate <NSObject>

/** 接收数据成功 */
- (void)socketRequstBackResultData:(NSData *)resultData;

/** 连接失败 */
- (void)socketRequstFail;

/** 获取data */
- (NSData *)getData;

@end
@interface KLSocketManager : NSObject

+ (KLSocketManager *)shareInstance;

/**
 socket连接
 */
- (void)socketConnectHost;

/**
 socket断开 (被视为用户主动断开socket，不会自动重连)
 */
- (void)cutOffSocket;

/**
 向服务器发送数据 并指定代理
 */
-(void)socketWriteData:(NSData *)data andDelegate:(id <KLSocketManagerDelegate>)delegate;

@end
