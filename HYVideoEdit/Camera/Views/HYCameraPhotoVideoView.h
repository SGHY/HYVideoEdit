//
//  HYCameraPhotoVideoView.h
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//  点击拍照长按录制视频控件

#import <UIKit/UIKit.h>
@protocol HYCameraRecordingDelegate <NSObject>
@optional
/** 录制视频开始 **/
- (void)startRecordingVideoAtPoint:(CGPoint)point;
/** 录制视频中 point为手指坐标 **/
- (void)recordingDidUpdateProgress:(double)progress andPoint:(CGPoint)point;
/** 录制视频结束 **/
- (void)finishedRecordingVideo;
/** 拍照 **/
- (void)takingPicture;
@end
@interface HYCameraPhotoVideoView : UIView
@property (weak, nonatomic) id<HYCameraRecordingDelegate> recordingDelegate;
@end
