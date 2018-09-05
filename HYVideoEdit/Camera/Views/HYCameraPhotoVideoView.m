//
//  HYCameraPhotoVideoView.m
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import "HYCameraPhotoVideoView.h"
#import "HYCameraRecordingView.h"

#define KCircleLineWidth 5.0f

@interface HYCameraPhotoVideoView ()
/** 拍照录视频按钮*/
@property (strong, nonatomic) UIButton *contentBtn;
/** 控制视频录制的定时器*/
@property (strong, nonatomic) NSTimer *timer;
/** 视频录制进度**/
@property (assign, nonatomic) CGFloat recordProgress;
/** 视频录制进度视图**/
@property (strong, nonatomic) HYCameraRecordingView *recordingView;
@end
@implementation HYCameraPhotoVideoView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIButton *contentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        contentBtn.frame = self.bounds;
        contentBtn.backgroundColor = [UIColor clearColor];
        contentBtn.layer.cornerRadius = CGRectGetWidth(frame)/2;
        contentBtn.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8].CGColor;
        contentBtn.layer.borderWidth = KCircleLineWidth;
        contentBtn.exclusiveTouch = YES;
        [contentBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
        [contentBtn setImage:[UIImage imageNamed:@"home_white_36px"] forState:UIControlStateNormal];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        longPress.minimumPressDuration = 0.5;
        [contentBtn addGestureRecognizer:longPress];
        [self addSubview:contentBtn];
        self.contentBtn = contentBtn;
    }
    return self;
}
#pragma mark --视频录制进度条
- (HYCameraRecordingView *)recordingView
{
    if (!_recordingView) {
        _recordingView = [[HYCameraRecordingView alloc] initWithFrame:self.bounds];
    }
    return _recordingView;
}
- (void)clickAction:(UIButton *)btn
{
    //拍照
    if(_recordingDelegate && [_recordingDelegate respondsToSelector:@selector(takingPicture)]){
        [_recordingDelegate takingPicture];
    }
}
- (void)longPressAction:(UILongPressGestureRecognizer *)longPress
{
    UIView *inView;
    if ([_recordingDelegate isKindOfClass:[UIView class]]) {
        inView = (UIView *)_recordingDelegate;
    }else if ([_recordingDelegate isKindOfClass:[UIViewController class]]){
        inView = [(UIViewController *)_recordingDelegate view];
    }
    CGPoint point = [longPress locationInView:inView];
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self startRecord];
        if (_recordingDelegate && [_recordingDelegate respondsToSelector:@selector(startRecordingVideoAtPoint:)]) {
            [_recordingDelegate startRecordingVideoAtPoint:point];
        }
    }
    if (longPress.state == UIGestureRecognizerStateChanged) {
        if (_recordingDelegate && [_recordingDelegate respondsToSelector:@selector(recordingDidUpdateProgress:andPoint:)]) {
            [_recordingDelegate recordingDidUpdateProgress:self.recordingView.progress andPoint:point];
        }
    }
    if (longPress.state == UIGestureRecognizerStateEnded) {
        [self storRecord];
    }
}
#pragma mark --开始录制视频
- (void)startRecord
{
    self.recordProgress = 0;
    [UIView animateWithDuration:1.5 animations:^{
        self.transform = CGAffineTransformScale(self.transform,1.3,1.3);
    }completion:^(BOOL finished){
    }];
    self.recordingView.frame = self.contentBtn.bounds;
    [self addSubview:self.recordingView];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}
#pragma mark --停止录制视频
- (void)storRecord
{
    if(!_timer) return;
    if (_recordingDelegate && [_recordingDelegate respondsToSelector:@selector(finishedRecordingVideo)]) {
        [_recordingDelegate finishedRecordingVideo];
    }
    self.transform = CGAffineTransformScale(self.transform,1/1.3,1/1.3);
    [self.recordingView removeFromSuperview];
    self.recordProgress = self.recordingView.progress;
    self.recordingView.progress = 0;
    [_timer invalidate];
    _timer = nil;
}
- (void)timerAction
{
    self.recordingView.progress += 0.001;
    if (self.recordingView.progress >= 1) {
        [self storRecord];
        NSLog(@"完成");
    }
}
@end
