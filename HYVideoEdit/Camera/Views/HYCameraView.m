//
//  HYCameraView.m
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import "HYCameraView.h"
#import "HYCameraPhotoVideoView.h"
#import "UIView+HYFrame.h"
#import "UIView+HYAlert.h"

@interface HYCameraView ()<HYCameraRecordingDelegate>
@property (strong, nonatomic) HYCameraPreview *previewView;
@property (strong, nonatomic) HYCameraPhotoVideoView *photoVideoView;
/** 聚焦动画view**/
@property(nonatomic, strong) UIView *focusView;
/** 曝光动画view**/
@property(nonatomic, strong) UIView *exposureView;
@end
@implementation HYCameraView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.previewView = [[HYCameraPreview alloc]initWithFrame:self.bounds];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
        doubleTap.numberOfTapsRequired = 2;
        [self.previewView addGestureRecognizer:tap];
        [self.previewView addGestureRecognizer:doubleTap];
        [self.previewView addSubview:self.focusView];
        [self.previewView addSubview:self.exposureView];
        [tap requireGestureRecognizerToFail:doubleTap];
        [self addSubview:self.previewView];
        
        self.photoVideoView = [[HYCameraPhotoVideoView alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame)-64)/2, CGRectGetHeight(frame)-90, 64, 64)];
        self.photoVideoView.recordingDelegate = self;
        [self.previewView addSubview:self.photoVideoView];
    }
    return self;
}
-(UIView *)focusView{
    if (_focusView == nil) {
        _focusView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 150, 150.0f)];
        _focusView.backgroundColor = [UIColor clearColor];
        _focusView.layer.borderColor = [UIColor yellowColor].CGColor;
        _focusView.layer.borderWidth = 1.0f;
        _focusView.hidden = YES;
    }
    return _focusView;
}
-(UIView *)exposureView{
    if (_exposureView == nil) {
        _exposureView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 150, 150.0f)];
        _exposureView.backgroundColor = [UIColor clearColor];
        _exposureView.layer.borderColor = [UIColor whiteColor].CGColor;
        _exposureView.layer.borderWidth = 1.0f;
        _exposureView.hidden = YES;
    }
    return _exposureView;
}
#pragma mark -- 单击聚焦
- (void)tapAction:(UITapGestureRecognizer *)tap
{
    if ([_delegate respondsToSelector:@selector(focusAction:point:fail:)]) {
        CGPoint point = [tap locationInView:self.previewView];
        [self runFocusAnimation:self.focusView point:point];
        [_delegate focusAction:self point:[self.previewView captureDevicePointOfInterestForPoint:point] fail:^(NSError *error) {
            [self showErrorAlert:error];
        }];
    }
}
#pragma mark -- 双击切换摄像头
- (void)doubleTapAction:(UITapGestureRecognizer *)tap
{
    if ([_delegate respondsToSelector:@selector(swicthCameraAction:fail:)]) {
        [_delegate swicthCameraAction:self fail:^(NSError *error) {
            [self showErrorAlert:error];
        }];
    }
}
#pragma mark -- HYCameraRecordingDelegate
- (void)takingPicture
{
    if ([_delegate respondsToSelector:@selector(takePhotoAction:)]) {
        [_delegate takePhotoAction:self];
    }
}
- (void)startRecordingVideoAtPoint:(CGPoint)point
{
    if ([_delegate respondsToSelector:@selector(startRecordVideoAction:)]) {
        [_delegate startRecordVideoAction:self];
    }
}
- (void)finishedRecordingVideo
{
    if ([_delegate respondsToSelector:@selector(stopRecordVideoAction:)]) {
        [_delegate stopRecordVideoAction:self];
    }
    
}
#pragma mark -- 聚焦、曝光动画
-(void)runFocusAnimation:(UIView *)view point:(CGPoint)point{
    view.center = point;
    view.hidden = NO;
    [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
    } completion:^(BOOL complete) {
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            view.hidden = YES;
            view.transform = CGAffineTransformIdentity;
        });
    }];
}
#pragma mark -- 自动聚焦、曝光动画
- (void)runResetAnimation {
    self.focusView.center = CGPointMake(self.previewView.width/2, self.previewView.height/2);
    self.exposureView.center = CGPointMake(self.previewView.width/2, self.previewView.height/2);;
    self.exposureView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
    self.focusView.hidden = NO;
    self.focusView.hidden = NO;
    [UIView animateWithDuration:0.15f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.focusView.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
        self.exposureView.layer.transform = CATransform3DMakeScale(0.7, 0.7, 1.0);
    } completion:^(BOOL complete) {
        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.focusView.hidden = YES;
            self.exposureView.hidden = YES;
            self.focusView.transform = CGAffineTransformIdentity;
            self.exposureView.transform = CGAffineTransformIdentity;
        });
    }];
}
@end
