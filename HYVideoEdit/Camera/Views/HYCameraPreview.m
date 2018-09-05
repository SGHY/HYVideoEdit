//
//  HYCameraPreview.m
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import "HYCameraPreview.h"

@implementation HYCameraPreview
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //AVCaptureVideoPreviewLayer(捕捉预览)：它是CALayer的子类，可被用于自动显示相机产生的实时图像。previewLayer支持视频重力概念，可以控制视频内容渲染的缩放和拉伸效果
        [(AVCaptureVideoPreviewLayer *)self.layer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
    return self;
}
- (AVCaptureSession *)captureSession
{
    return [(AVCaptureVideoPreviewLayer *)self.layer session];
}
- (void)setCaptureSession:(AVCaptureSession *)captureSession
{
    [(AVCaptureVideoPreviewLayer *)self.layer setSession:captureSession];
}
#pragma mark --将屏幕坐标系的点转换为previewLayer坐标系的点
- (CGPoint)captureDevicePointOfInterestForPoint:(CGPoint)point
{
    return [(AVCaptureVideoPreviewLayer *)self.layer captureDevicePointOfInterestForPoint:point];
}
// 使该view的layer方法返回AVCaptureVideoPreviewLayer对象
+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}
@end
