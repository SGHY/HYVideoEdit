//
//  HYCameraPreview.h
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//  捕捉预览

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface HYCameraPreview : UIView
/** 捕捉会话**/
@property (strong, nonatomic) AVCaptureSession *captureSession;
/***将屏幕坐标系的点转换为previewLayer坐标系的点**/
- (CGPoint)captureDevicePointOfInterestForPoint:(CGPoint)point;
@end
