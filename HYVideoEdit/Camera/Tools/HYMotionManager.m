//
//  HYMotionManager.m
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import "HYMotionManager.h"
#import <CoreMotion/CoreMotion.h>

@interface HYMotionManager ()
/** 设备运动管理器**/
@property (strong, nonatomic) CMMotionManager *motionManager;
@end

@implementation HYMotionManager
- (void)dealloc
{
    [self.motionManager stopDeviceMotionUpdates];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.deviceMotionUpdateInterval = 0.05f;
        if (!self.motionManager.deviceMotionAvailable) {
            self.motionManager = nil;
            return self;
        }
        __weak typeof(self) weakSelf = self;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf dealWithDiveceMotion:motion];
            });
        }];
    }
    return self;
}
- (void)dealWithDiveceMotion:(CMDeviceMotion *)motion
{
    double x = motion.gravity.x;
    double y = motion.gravity.y;
    //手机水平放    x:0 y:0 z:屏幕朝上-1、屏幕朝下1
    //手机竖向垂直放 x:0 y:摄像头朝上-1、摄像头朝下1 z:0
    //手机横向垂直放 x:开关键朝上-1、开关键朝下1 y:0 z:0
    if (fabs(y) > fabs(x)) {
        if (y >= 0) {
            self.deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            self.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
        }else{
            self.deviceOrientation = UIDeviceOrientationPortrait;
            self.videoOrientation = AVCaptureVideoOrientationPortrait;
        }
    }else {
        if (x >= 0) {
            self.deviceOrientation = UIDeviceOrientationLandscapeRight;
            self.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
        }else{
            self.deviceOrientation = UIDeviceOrientationLandscapeLeft;
            self.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
        }
    }
}
@end
