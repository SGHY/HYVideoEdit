//
//  HYCameraViewController.m
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
/****
 自定义相机
 捕捉会话-AVCaptureSession
 捕捉输入-AVCaptureDeviceInput
 捕捉预览-AVCaptureVideoPreviewLayer/OpenGL ES
 捕捉连接-AVCaptureConnection
 拍照-AVCaptureStillImageOutput
 音频-AVCaptureAudioDataOutput
 视频-AVCaptureVideoDataOutput
 生成视频文件-AVAssetWriter、AVAssetWriterInput
 写入相册-ALAssetsLibrary、PHPhotoLibrary
 操作相机
 转换摄像头
 补光
 闪光灯
 聚焦
 曝光
 自动聚焦/曝光
 
 视频重力——Video gravity AVAssetWriterInputPixelBufferAdaptor
 视频方向问题——Orientation
 **/

#import "HYCameraViewController.h"
#import "HYMotionManager.h"
#import "HYCameraView.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "UIView+HYFrame.h"
#import "UIView+HYAlert.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "HYImageViewController.h"
#import "HYVideoPlayerViewController.h"

#define ISIOS9 __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
@interface HYCameraViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate,HYCameraViewDelegate>
// 会话
@property (strong, nonatomic) AVCaptureSession *session;
// 输入
@property (strong, nonatomic) AVCaptureDeviceInput      *deviceInput;
// 输出
@property (strong, nonatomic) AVCaptureConnection       *videoConnection;
@property (strong, nonatomic) AVCaptureConnection       *audioConnection;
@property (strong, nonatomic) AVCaptureVideoDataOutput  *videoOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutput;
// 视频
@property (strong, nonatomic) NSURL                     *movieURL;
@property (strong, nonatomic) AVAssetWriter             *movieWriter;
@property (strong, nonatomic) AVAssetWriterInput        *movieAudioInput;
@property (strong, nonatomic) AVAssetWriterInput        *movieVideoInput;
// 当前输入设备
@property (strong, nonatomic) AVCaptureDevice *activeCamera;
// 不活跃的设备(这里指前摄像头或后摄像头，不包括外接输入设备)
@property (strong, nonatomic) AVCaptureDevice *inactiveCamera;
// 视频播放方向
@property (assign, nonatomic) AVCaptureVideoOrientation  referenceOrientation;

@property (strong, nonatomic) HYMotionManager *motionManager;

@property (strong, nonatomic) HYCameraView *cameraView;
@end

@implementation HYCameraViewController
{
    BOOL                       _readyToRecordVideo;
    BOOL                       _readyToRecordAudio;
    BOOL                       _recording;
    dispatch_queue_t           _movieWritingQueue;
}
- (void)dealloc{
    NSLog(@"dealloc ------- %@",self);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //设定一些默认值
    self.movieURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"movie.mov"]];
    self.motionManager = [[HYMotionManager alloc] init];
    self.referenceOrientation = AVCaptureVideoOrientationPortrait;
    
    self.cameraView = [[HYCameraView alloc] initWithFrame:self.view.bounds];
    self.cameraView.delegate = self;
    [self.view addSubview:self.cameraView];
    
    NSError *error;
    [self setupSession:&error];
    if (!error) {
        [self.cameraView.previewView setCaptureSession:self.session];
        [self startCaptureSession];
    }else{
        [self.view showErrorAlert:error];
    }

    [self createReturnBack];
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
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
#pragma mark - -相关配置
/// 会话
- (void)setupSession:(NSError **)error{
    _session = [[AVCaptureSession alloc]init];
    _session.sessionPreset = AVCaptureSessionPresetHigh;
    
    [self setupSessionInputs:error];
    [self setupSessionOutputs:error];
}
/// 输入
- (void)setupSessionInputs:(NSError **)error{
    // 视频输入
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    if (videoInput) {
        if ([_session canAddInput:videoInput]){
            [_session addInput:videoInput];
        }
    }
    _deviceInput = videoInput;
    
    // 音频输入
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:error];
    if ([_session canAddInput:audioIn]){
        [_session addInput:audioIn];
    }
}
/// 输出
- (void)setupSessionOutputs:(NSError **)error{
    dispatch_queue_t captureQueue = dispatch_queue_create("com.cc.captureQueue", DISPATCH_QUEUE_SERIAL);
    
    // 视频输出
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    [videoOut setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [videoOut setSampleBufferDelegate:self queue:captureQueue];
    if ([_session canAddOutput:videoOut]){
        [_session addOutput:videoOut];
    }
    _videoOutput = videoOut;
    _videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    // 音频输出
    AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
    [audioOut setSampleBufferDelegate:self queue:captureQueue];
    if ([_session canAddOutput:audioOut]){
        [_session addOutput:audioOut];
    }
    _audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
    
    // 静态图片输出
    AVCaptureStillImageOutput *imageOutput = [[AVCaptureStillImageOutput alloc] init];
    imageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    if ([_session canAddOutput:imageOutput]) {
        [_session addOutput:imageOutput];
    }
    _imageOutput = imageOutput;
}
/// 音频源数据写入配置
- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription{
    size_t aclSize = 0;
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
    NSData *currentChannelLayoutData = aclSize > 0 ? [NSData dataWithBytes:currentChannelLayout length:aclSize] : [NSData data];
    NSDictionary *audioCompressionSettings = @{AVFormatIDKey: [NSNumber numberWithInteger: kAudioFormatMPEG4AAC],
                                               AVSampleRateKey: [NSNumber numberWithFloat: currentASBD->mSampleRate],
                                               AVChannelLayoutKey: currentChannelLayoutData,
                                               AVNumberOfChannelsKey: [NSNumber numberWithInteger: currentASBD->mChannelsPerFrame],
                                               AVEncoderBitRatePerChannelKey: [NSNumber numberWithInt: 64000]};
    
    if ([_movieWriter canApplyOutputSettings:audioCompressionSettings forMediaType: AVMediaTypeAudio]){
        _movieAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType: AVMediaTypeAudio outputSettings:audioCompressionSettings];
        _movieAudioInput.expectsMediaDataInRealTime = YES;
        if ([_movieWriter canAddInput:_movieAudioInput]){
            [_movieWriter addInput:_movieAudioInput];
        } else {
            [self.view showErrorAlert:_movieWriter.error];
            return NO;
        }
    } else {
        [self.view showErrorAlert:_movieWriter.error];
        return NO;
    }
    return YES;
}

/// 视频源数据写入配置
- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
{
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    NSUInteger numPixels = dimensions.width * dimensions.height;
    CGFloat bitsPerPixel = numPixels < (640 * 480) ? 4.05 : 11.0;
    NSDictionary *compression = @{AVVideoAverageBitRateKey: [NSNumber numberWithInteger: numPixels * bitsPerPixel],
                                  AVVideoMaxKeyFrameIntervalKey: [NSNumber numberWithInteger:30]};
    NSDictionary *videoCompressionSettings = @{AVVideoCodecKey: AVVideoCodecH264,
                                               AVVideoWidthKey: [NSNumber numberWithInteger:dimensions.width],
                                               AVVideoHeightKey: [NSNumber numberWithInteger:dimensions.height],
                                               AVVideoCompressionPropertiesKey: compression};
    
    if ([_movieWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]){
        _movieVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        _movieVideoInput.expectsMediaDataInRealTime = YES;
        _movieVideoInput.transform = [self transformFromCurrentVideoOrientationToOrientation:self.referenceOrientation];
        if ([_movieWriter canAddInput:_movieVideoInput]){
            [_movieWriter addInput:_movieVideoInput];
        } else {
            [self.view showErrorAlert:_movieWriter.error];
            return NO;
        }
    } else {
        [self.view showErrorAlert:_movieWriter.error];
        return NO;
    }
    return YES;
}
#pragma mark - -会话控制
// 开启捕捉
- (void)startCaptureSession{
    if (!_movieWritingQueue) {
        _movieWritingQueue = dispatch_queue_create("Movie.Writing.Queue", DISPATCH_QUEUE_SERIAL);
    }
    if (!_session.isRunning){
        [_session startRunning];
    }
}
// 停止捕捉
- (void)stopCaptureSession{
    if (_session.isRunning){
        [_session stopRunning];
    }
}
#pragma mark -- 获取当前活跃的摄像头
- (AVCaptureDevice *)activeCamera{
    return _deviceInput.device;
}
#pragma mark -- 获取不活跃的摄像头
- (AVCaptureDevice *)inactiveCamera{
    AVCaptureDevice *device = nil;
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1) {
        if ([self activeCamera].position == AVCaptureDevicePositionBack) {
            device = [self cameraWithPosition:AVCaptureDevicePositionFront];
        } else {
            device = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
    }
    return device;
}
#pragma mark -- 获取前置或后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}
#pragma mark -- 一些相机功能
#pragma mark -- 拍照
-(void)takePictureImage{
    AVCaptureConnection *connection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = [self currentVideoOrientation];
    }
    //__weak typeof(self) weakSelf = self;
    [_imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        if (error) {
            [self.view showErrorAlert:error];
            return;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [[UIImage alloc]initWithData:imageData];

//        HYImageViewController *imageVc = [[HYImageViewController alloc] init];
//        imageVc.image = image;
//        [weakSelf presentViewController:imageVc animated:NO completion:nil];

        [self dismissViewControllerAnimated:YES completion:^{
            if (self.completeTakeBlock) {
                self.completeTakeBlock([image copy]);
            }
        }];
    }];
}
#pragma mark - -录制视频
// 开始录制
- (void)startRecording{
    [self removeFile:self.movieURL];
    dispatch_async(_movieWritingQueue, ^{
        if (!self.movieWriter) {
            NSError *error;
            self.movieWriter = [[AVAssetWriter alloc] initWithURL:self.movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
            if (error) {
                [self.view showErrorAlert:error];
            }
        }
        _recording = YES;
    });
}

// 停止录制
- (void)stopRecording{
    _recording = NO;
    _readyToRecordVideo = NO;
    _readyToRecordAudio = NO;

    dispatch_async(_movieWritingQueue, ^{
        [self.movieWriter finishWritingWithCompletionHandler:^(){
            if (self.movieWriter.status == AVAssetWriterStatusCompleted) {
//                dispatch_sync(dispatch_get_main_queue(), ^{
//                    [self.view showAlertView:@"是否保存到相册" ok:^(UIAlertAction *act) {
//                        [self saveMovieToCameraRoll];
//                    } cancel:nil];
//                });

//                HYVideoPlayerViewController *playerVc = [[HYVideoPlayerViewController alloc] init];
//                playerVc.mediaURL = self.movieURL;
//                [self.navigationController pushViewController:playerVc animated:YES];

                [self dismissViewControllerAnimated:YES completion:^{
                    if (self.completeRecordBlock) {
                        self.completeRecordBlock([self.movieURL copy]);
                    }
                }];

            } else {
                [self.view showErrorAlert:self.movieWriter.error];
            }
            self.movieWriter = nil;
        }];
    });
}
#pragma mark - -转换摄像头
- (id)switchCameras{
    NSError *error;
    AVCaptureDevice *videoDevice = [self inactiveCamera];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (videoInput) {
//        AVCaptureFlashMode flashMode = [self flashMode];
        
        // 转换摄像头
        [_session beginConfiguration];
        [_session removeInput:_deviceInput];
        if ([_session canAddInput:videoInput]) {
            [_session addInput:videoInput];
            _deviceInput = videoInput;
        } else {
            [_session addInput:_deviceInput];
        }
        [_session commitConfiguration];
        
        // 完成后需要重新设置视频输出链接
        _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // 如果后置转前置，系统会自动关闭手电筒，如果之前打开的，需要更新UI
        if (videoDevice.position == AVCaptureDevicePositionFront) {
//            [self.cameraView changeTorch:NO];
        }
        
        // 前后摄像头的闪光灯不是同步的，所以在转换摄像头后需要重新设置闪光灯
//        [self changeFlash:flashMode];
        
        return nil;
    }
    return error;
}
#pragma mark - -聚焦
- (id)focusAtPoint:(CGPoint)point{
    AVCaptureDevice *device = self.activeCamera;
    BOOL supported = [device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus];
    if (supported){
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.focusPointOfInterest = point;
            device.focusMode = AVCaptureFocusModeAutoFocus;
            [device unlockForConfiguration];
        }
        return error;
    }
    return [self errorWithMessage:@"设备不支持聚焦" code:407];
}
#pragma mark - -曝光
static const NSString *CameraAdjustingExposureContext;
- (id)exposeAtPoint:(CGPoint)point{
    AVCaptureDevice *device = [self activeCamera];
    if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.exposurePointOfInterest = point;
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            if ([device isExposureModeSupported:AVCaptureExposureModeLocked]) {
                [device addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:&CameraAdjustingExposureContext];
            }
            [device unlockForConfiguration];
        }
        return error;
    }
    return [self errorWithMessage:@"设备不支持曝光" code:405];
}
#pragma mark - -自动聚焦、曝光
- (id)resetFocusAndExposureModes{
    AVCaptureDevice *device = [self activeCamera];
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    BOOL canResetFocus = [device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode];
    BOOL canResetExposure = [device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode];
    CGPoint centerPoint = CGPointMake(0.5f, 0.5f);
    NSError *error;
    if ([device lockForConfiguration:&error]) {
        if (canResetFocus) {
            device.focusMode = focusMode;
            device.focusPointOfInterest = centerPoint;
        }
        if (canResetExposure) {
            device.exposureMode = exposureMode;
            device.exposurePointOfInterest = centerPoint;
        }
        [device unlockForConfiguration];
    }
    return error;
}
#pragma mark - -闪光灯
- (BOOL)cameraHasFlash{
    return [[self activeCamera] hasFlash];
}

- (AVCaptureFlashMode)flashMode{
    return [[self activeCamera] flashMode];
}

- (id)changeFlash:(AVCaptureFlashMode)flashMode{
    if (![self cameraHasFlash]) {
        return [self errorWithMessage:@"不支持闪光灯" code:401];
    }
    // 如果手电筒打开，先关闭手电筒
    if ([self torchMode] == AVCaptureTorchModeOn) {
        [self setTorchMode:AVCaptureTorchModeOff];
    }
    return [self setFlashMode:flashMode];
}

- (id)setFlashMode:(AVCaptureFlashMode)flashMode{
    AVCaptureDevice *device = [self activeCamera];
    if ([device isFlashModeSupported:flashMode]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }
        return error;
    }
    return [self errorWithMessage:@"不支持闪光灯" code:401];
}
#pragma mark - -补光开启手电筒
- (BOOL)cameraHasTorch {
    return [[self activeCamera] hasTorch];
}

- (AVCaptureTorchMode)torchMode {
    return [[self activeCamera] torchMode];
}

- (id)changeTorch:(AVCaptureTorchMode)torchMode{
    if (![self cameraHasTorch]) {
        return [self errorWithMessage:@"不支持手电筒" code:403];
    }
    // 如果闪光灯打开，先关闭闪光灯
    if ([self flashMode] == AVCaptureFlashModeOn) {
        [self setFlashMode:AVCaptureFlashModeOff];
    }
    return [self setTorchMode:torchMode];
}

- (id)setTorchMode:(AVCaptureTorchMode)torchMode{
    AVCaptureDevice *device = [self activeCamera];
    if ([device isTorchModeSupported:torchMode]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            device.torchMode = torchMode;
            [device unlockForConfiguration];
        }
        return error;
    }
    return [self errorWithMessage:@"不支持手电筒" code:403];
}
#pragma mark - -HYCameraViewDelegate
// 聚焦
-(void)focusAction:(HYCameraView *)cameraView point:(CGPoint)point fail:(void (^)(NSError *))fail{
    id error = [self focusAtPoint:point];
    if(error&&fail){
        fail(error);
    }
}
// 曝光
-(void)exposAction:(HYCameraView *)cameraView point:(CGPoint)point fail:(void (^)(NSError *))fail{
    id error = [self exposeAtPoint:point];
    if(error&&fail){
        fail(error);
    }
}
// 自动聚焦、曝光
-(void)autoFocusAndExposureAction:(HYCameraView *)cameraView fail:(void (^)(NSError *))fail{
    id error = [self resetFocusAndExposureModes];
    if(error&&fail){
        fail(error);
    }
}
// 转换摄像头
- (void)swicthCameraAction:(HYCameraView *)cameraView fail:(void (^)(NSError *))fail{
    id error = [self switchCameras];
    if(error&&fail){
        fail(error);
    }
}
// 闪光灯
-(void)flashLightAction:(HYCameraView *)cameraView fail:(void (^)(NSError *))fail{
    id error = [self changeFlash:[self flashMode] == AVCaptureFlashModeOn?AVCaptureFlashModeOff:AVCaptureFlashModeOn];
    if(error&&fail){
        fail(error);
    }
}
// 手电筒
-(void)torchLightAction:(HYCameraView *)cameraView fail:(void (^)(NSError *))fail{
    id error =  [self changeTorch:[self torchMode] == AVCaptureTorchModeOn?AVCaptureTorchModeOff:AVCaptureTorchModeOn];
    if(error&&fail){
        fail(error);
    }
}
// 取消拍照
- (void)cancelAction:(HYCameraView *)cameraView{
    
}
// 转换类型
-(void)didChangeTypeAction:(HYCameraView *)cameraView type:(NSInteger)type{
    
}
// 拍照
- (void)takePhotoAction:(HYCameraView *)cameraView{
    [self takePictureImage];
}
// 开始录像
-(void)startRecordVideoAction:(HYCameraView *)cameraView{
    [self startRecording];
}
// 停止录像
-(void)stopRecordVideoAction:(HYCameraView *)cameraView{
    [self stopRecording];
}
#pragma mark - -输出代理
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (_recording && _movieWriter) {
        CFRetain(sampleBuffer);
        dispatch_async(_movieWritingQueue, ^{
            if (connection == self.videoConnection){
                if (!_readyToRecordVideo){
                    _readyToRecordVideo = [self setupAssetWriterVideoInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                }
                if ([self inputsReadyToRecord]){
                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
                }
            } else if (connection == self.audioConnection){
                if (!_readyToRecordAudio){
                    _readyToRecordAudio = [self setupAssetWriterAudioInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                }
                if ([self inputsReadyToRecord]){
                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
                }
            }
            CFRelease(sampleBuffer);
        });
    }
}
- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType{
    if (_movieWriter.status == AVAssetWriterStatusUnknown){
        if ([_movieWriter startWriting]){
            [_movieWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        } else {
            [self.view showErrorAlert:_movieWriter.error];
        }
    }
    if (_movieWriter.status == AVAssetWriterStatusWriting){
        if (mediaType == AVMediaTypeVideo){
            if (!_movieVideoInput.readyForMoreMediaData){
                return;
            }
            if (![_movieVideoInput appendSampleBuffer:sampleBuffer]){
                [self.view showErrorAlert:_movieWriter.error];
            }
        } else if (mediaType == AVMediaTypeAudio){
            if (!_movieAudioInput.readyForMoreMediaData){
                return;
            }
            if (![_movieAudioInput appendSampleBuffer:sampleBuffer]){
                [self.view showErrorAlert:_movieWriter.error];
            }
        }
    }
}
- (BOOL)inputsReadyToRecord{
    return _readyToRecordVideo && _readyToRecordAudio;
}
#pragma mark - -Private methods
- (NSError *)errorWithMessage:(NSString *)text code:(NSInteger)code  {
    NSDictionary *desc = @{NSLocalizedDescriptionKey: text};
    NSError *error = [NSError errorWithDomain:@"com.cc.camera" code:code userInfo:desc];
    return error;
}
// 获取视频旋转矩阵
- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation{
    CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
    CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:self.motionManager.videoOrientation];
    CGFloat angleOffset;
    if ([self activeCamera].position == AVCaptureDevicePositionBack) {
        angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    } else {
        angleOffset = videoOrientationAngleOffset - orientationAngleOffset + M_PI_2;
    }
    CGAffineTransform transform = CGAffineTransformMakeRotation(angleOffset);
    return transform;
}

// 获取视频旋转角度
- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation{
    CGFloat angle = 0.0;
    switch (orientation){
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    return angle;
}
// 保存视频
- (void)saveMovieToCameraRoll{
    if (ISIOS9) {
        [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
            if (status != PHAuthorizationStatusAuthorized) return;
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetCreationRequest *videoRequest = [PHAssetCreationRequest creationRequestForAsset];
                [videoRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:self.movieURL options:nil];
            } completionHandler:^( BOOL success, NSError * _Nullable error ) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.view hideAlert];
                });
                success?:[self.view showErrorAlert:error];
            }];
        }];
    } else {
        ALAssetsLibrary *lab = [[ALAssetsLibrary alloc]init];
        [lab writeVideoAtPathToSavedPhotosAlbum:_movieURL completionBlock:^(NSURL *assetURL, NSError *error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.view hideAlert];
            });
            !error?:[self.view showErrorAlert:error];
        }];
    }
}
// 移除文件
- (void)removeFile:(NSURL *)fileURL{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = fileURL.path;
    if ([fileManager fileExistsAtPath:filePath]){
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success){
            [self.view showErrorAlert:error];
        } else {
            NSLog(@"删除视频文件成功");
        }
    }
}
// 当前设备取向
- (AVCaptureVideoOrientation)currentVideoOrientation{
    return self.motionManager.videoOrientation;
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
