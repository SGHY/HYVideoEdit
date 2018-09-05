//
//  HYCameraView.h
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//  在这里自定义相机样式

#import <UIKit/UIKit.h>
#import "HYCameraPreview.h"

@class HYCameraView;
@protocol HYCameraViewDelegate <NSObject>
@optional;
/*  转换摄像头 */
-(void)swicthCameraAction:(HYCameraView *)cameraView fail:(void(^)(NSError *error))fail;
/*  闪光灯 */
-(void)flashLightAction:(HYCameraView *)cameraView fail:(void(^)(NSError *error))fail;
/*  补光 */
-(void)torchLightAction:(HYCameraView *)cameraView fail:(void(^)(NSError *error))fail;
/*  聚焦 */
-(void)focusAction:(HYCameraView *)cameraView point:(CGPoint)point fail:(void(^)(NSError *error))fail;
/*  曝光 */
-(void)exposAction:(HYCameraView *)cameraView point:(CGPoint)point fail:(void(^)(NSError *error))fail;
/*  自动聚焦曝光 */
-(void)autoFocusAndExposureAction:(HYCameraView *)cameraView fail:(void(^)(NSError *error))fail;
/*  取消 */
-(void)cancelAction:(HYCameraView *)cameraView;
/*  拍照 */
-(void)takePhotoAction:(HYCameraView *)cameraView;
/*  停止录制视频 */
-(void)stopRecordVideoAction:(HYCameraView *)cameraView;
/*  开始录制视频 */
-(void)startRecordVideoAction:(HYCameraView *)cameraView;
/* 改变拍摄类型*/
-(void)didChangeTypeAction:(HYCameraView *)cameraView type:(NSInteger)type;
@end

@interface HYCameraView : UIView
@property(nonatomic, weak) id <HYCameraViewDelegate> delegate;
@property (strong, nonatomic, readonly) HYCameraPreview *previewView;
@end


