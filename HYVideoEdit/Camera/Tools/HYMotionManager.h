//
//  HYMotionManager.h
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface HYMotionManager : NSObject
/** 设备取向**/
@property (assign, nonatomic) UIDeviceOrientation deviceOrientation;
/** 视频取向**/
@property (assign, nonatomic) AVCaptureVideoOrientation videoOrientation;
@end
