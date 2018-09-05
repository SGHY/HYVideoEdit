//
//  HYVideoPlayerViewController.m
//  HYCamera
//
//  Created by 上官惠阳 on 2018/7/22.
//  Copyright © 2018年 leve. All rights reserved.
//

#import "HYVideoPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface HYVideoPlayerViewController ()
@property (strong, nonatomic)AVPlayer *myPlayer;//播放器
@property (strong, nonatomic)AVPlayerItem *item;//播放单元
@property (strong, nonatomic)AVPlayerLayer *playerLayer;//播放界面（layer）
@property (strong, nonatomic)NSURL *cutterUrl;
@end

@implementation HYVideoPlayerViewController
- (void)dealloc
{
    NSLog(@"dealloc-----------------%@",self);
}
- (void)viewDidLoad {
    [super viewDidLoad];

    //初始化一个播放单元
    self.item = [AVPlayerItem playerItemWithURL:self.mediaURL];

    //初始化一个播放器对象
    self.myPlayer = [AVPlayer playerWithPlayerItem:self.item];

    //初始化一个播放器的Layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.myPlayer];
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.playerLayer];

    [self createReturnBack];
}
- (void)viewDidAppear:(BOOL)animated
{
    //开始播放
    [self.myPlayer play];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self.myPlayer pause];
}
- (void)createReturnBack
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(10,10,44,44);
    [btn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)backAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
