//
//  ViewController.m
//  PDSocketManager
//
//  Created by Macintosh HD on 2017/8/21.
//  Copyright © 2017年 Macintosh HD. All rights reserved.
//

#import "ViewController.h"
#import "KLSocketManager.h"
#import "Test.pbobjc.h"

@interface ViewController () <KLSocketManagerDelegate>



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (IBAction)connectDidClicked:(id)sender {
    [[KLSocketManager shareInstance] socketConnectHost];
}

- (IBAction)sendDidClicked:(id)sender {
    GetUser *user = [[GetUser alloc] init];
    user.command = Commands_Reply;
    user.openid = @"3";
    [[KLSocketManager shareInstance] socketWriteData:[user data] andDelegate:self];
}

- (NSData *)getData {
    return [NSData new];
}

/** 接收数据成功 */
- (void)socketRequstBackResultData:(NSData *)resultData {
    
}

/** 连接失败 */
- (void)socketRequstFail {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
