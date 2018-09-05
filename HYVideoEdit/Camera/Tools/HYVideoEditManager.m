//
//  HYVideoEditManager.m
//  HYVideoEdit
//
//  Created by 上官惠阳 on 2018/8/31.
//  Copyright © 2018年 上官惠阳. All rights reserved.
//

#import "HYVideoEditManager.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
@interface HYVideoEditManager ()
@property (nonatomic, copy) void (^completeBlock)(NSURL *exportURL, id error);
@end
@implementation HYVideoEditManager
+ (HYVideoEditManager *)share
{
    static HYVideoEditManager *editManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        editManager = [[HYVideoEditManager alloc] init];
    });
    return editManager;
}
#pragma mark -- 视频裁剪
-(void)videoCutterVideoUrl:(NSURL *)videoUrl fromTime:(CGFloat)fromTime cutterDuration:(CGFloat)cutterDuration complete:(void (^)(NSURL *exportURL, id error))completeBlock
{
    if (!videoUrl) {
        NSLog(@"视频url不能为空");
        return;
    }
    self.completeBlock = completeBlock;
    //1 — AVURLAsset此类主要用于获取媒体信息，包括视频、声音等
    AVAsset *videoAsset = [AVAsset assetWithURL:videoUrl];

    //视频总时长
    int videoSeconds = ceil(videoAsset.duration.value/videoAsset.duration.timescale);
    if (fromTime > videoSeconds) {
        NSLog(@"开始时间超过视频总长了");
        return;
    }
    if (fromTime + cutterDuration > videoSeconds) {
        NSLog(@"开始时间加裁取时长总和超过视频总时长了");
        return;
    }

    //2 - 创建AVMutableComposition对象来添加视频音频资源的AVMutableCompositionTrack
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

    NSError *error = nil;

    //这块是裁剪,rangtime .前面的是开始时间,后面是裁剪多长 (我这裁剪的是从第fromTime秒开始裁剪，裁剪cutterDuration秒时长.)
    //视频频采集通道
    AVAssetTrack * videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //3 - 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
    AVMutableCompositionTrack *videoTrack;
    if (videoAssetTrack) {
        videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];

        [videoTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(fromTime, 30), CMTimeMakeWithSeconds(cutterDuration, 30)) ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];
    }else{
        NSLog(@"该视频有问题");
        return;
    }

    //音频通道 不光视频要裁剪声音也要裁剪
    AVMutableCompositionTrack * audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //音频采集通道
    AVAssetTrack * audioAssetTrack;
    if (audioTrack) {
        audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];

        [audioTrack insertTimeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(fromTime, 30), CMTimeMakeWithSeconds(cutterDuration, 30)) ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
    }

    AVMutableVideoComposition *mainCompositionInst = [self videoCompositionVideoTrack:videoTrack videoAssetTrack:videoAssetTrack];

    [self videoExportComosition:mixComposition videoComposition:mainCompositionInst quality:AVAssetExportPresetHighestQuality];
}
#pragma mark -- 视频合并
-(void)videoMergeVideoUrls:(NSArray <NSURL *>*)videoUrls complete:(void (^)(NSURL *exportURL, id error))completeBlock
{
    if (videoUrls.count < 2) {
        NSLog(@"视频必须在两个或两个以上");
        return;
    }
    // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    // 2 - Video track
    AVMutableCompositionTrack *videoTrack;

    AVMutableCompositionTrack *audioTrack;

    for (NSInteger i = videoUrls.count - 1;i >= 0;i --) {
        NSURL *videoUrl = videoUrls[i];
        if (![videoUrl isKindOfClass:[NSURL class]]) {
            NSLog(@"videoUrls数组里面必须是NSURL类型");
            return;
        }
        AVAsset *asset = [AVAsset assetWithURL:videoUrl];
        AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVAssetTrack *audioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];

        if (videoAssetTrack) {
            if (!videoTrack) {
                videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
            }
            [self videoCompositionVideoTrack:videoTrack videoAssetTrack:videoAssetTrack];

            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];
        }else{
            NSLog(@"该视频有问题");
            return;
        }
        if (audioAssetTrack) {
            if (!audioTrack) {
                audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            }
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
        }
    }

    self.completeBlock = completeBlock;

    [self videoExportComosition:mixComposition videoComposition:nil quality:AVAssetExportPresetHighestQuality];
}
#pragma mark -- 视频添加背景音乐
- (void)videoAddBackgroundMusicVideoUrl:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl complete:(void (^)(NSURL *exportURL, id error))completeBlock
{
    self.completeBlock = completeBlock;

    //视频 声音 来源
    NSURL * videoInputUrl = videoUrl;
    NSURL * audioInputUrl = audioUrl;

    //创建可变的音视频组合
    AVMutableComposition * comosition = [AVMutableComposition composition];

    // 视频通道 枚举 kCMPersistentTrackID_Invalid = 0
    AVMutableCompositionTrack * videoTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];

    //视频采集
    AVURLAsset * videoAsset = [[AVURLAsset alloc] initWithURL:videoInputUrl options:nil];

    //视频时间范围
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);

    //视频采集通道
    AVAssetTrack * videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];

    //把采集轨道数据加入到可变轨道中
    [videoTrack insertTimeRange:videoTimeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];

    //声音采集
    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:audioInputUrl options:nil];

    //因为视频较短 所以直接用了视频的长度 如果想要自动化需要自己写判断
    CMTimeRange audioTimeRange = videoTimeRange;

    //音频通道
    AVMutableCompositionTrack * audioTrack = [comosition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

    //音频采集通道
    AVAssetTrack * audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];

    //加入合成轨道中
    [audioTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];

    AVMutableVideoComposition *videoComposition = [self videoCompositionVideoTrack:videoTrack videoAssetTrack:videoAssetTrack];

    [self videoExportComosition:comosition videoComposition:videoComposition quality:AVAssetExportPresetHighestQuality];
}
#pragma mark -- 添加简单的水印
- (void)videoAddWatermarkVideoUrl:(NSURL *)videoUrl complete:(void (^)(NSURL *exportURL, id error))completeBlock
{
    self.completeBlock = completeBlock;

    //1 创建AVAsset实例 AVAsset包含了video的所有信息 self.videoUrl输入视频的路径
    AVAsset *videoAsset = [AVAsset assetWithURL:videoUrl];
    //2 创建AVMutableComposition实例. apple developer 里边的解释 【AVMutableComposition is a mutable subclass of AVComposition you use when you want to create a new composition from existing assets. You can add and remove tracks, and you can add, remove, and scale time ranges.】
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

    //3 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];

    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:videoAssetTrack
                         atTime:kCMTimeZero error:nil];

    AVMutableCompositionTrack *aduioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *aduioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    [aduioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:aduioAssetTrack atTime:kCMTimeZero error:nil];

    AVMutableVideoComposition *mainCompositionInst = [self videoCompositionVideoTrack:videoTrack videoAssetTrack:videoAssetTrack];

    //简单的水印
    [self applyVideoEffectsToComposition:mainCompositionInst size:mainCompositionInst.renderSize];

    [self videoExportComosition:mixComposition videoComposition:mainCompositionInst quality:AVAssetExportPresetHighestQuality];
}
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);

    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];

    CALayer *overlayLayer = [CALayer layer];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    [parentLayer addSublayer:overlayLayer];

    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFont:@"Helvetica-Bold"];
    [subtitle1Text setFontSize:36];
    [subtitle1Text setFrame:CGRectMake(0, 0, size.width, 100)];
    [subtitle1Text setString:@"哈哈  这是水印"];
    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor redColor] CGColor]];
    [overlayLayer addSublayer:subtitle1Text];

    CALayer *imageLayer = [[CALayer alloc] init];
    imageLayer.contents = (id)[UIImage imageNamed:@"colorDetailImage"].CGImage;
    imageLayer.frame = CGRectMake((size.width - 80)/2, (size.height-80)/2, 80, 80);
    [overlayLayer addSublayer:imageLayer];

    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}
#pragma mark -- private
#pragma mark -- 视频导出 AVAssetExportPresetHighestQuality,AVAssetExportPresetMediumQuality,AVAssetExportPresetLowQuality
- (void)videoExportComosition:(AVMutableComposition *)comosition videoComposition:(AVMutableVideoComposition *)mainCompositionInst quality:(NSString *)quality
{
    //合成之后的输出路径
    NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"HYVideo-%d.mov",arc4random() % 1000]];
    //混合后的视频输出路径
    NSURL *outPutUrl = [NSURL fileURLWithPath:outPutPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
    }
    //创建输出
    AVAssetExportSession * assetExport = [[AVAssetExportSession alloc] initWithAsset:comosition presetName:quality];
    assetExport.outputURL = outPutUrl;//输出路径
    assetExport.outputFileType = AVFileTypeQuickTimeMovie;//输出类型
    assetExport.shouldOptimizeForNetworkUse = YES;//是否优化   不太明白
    if (mainCompositionInst) {
        assetExport.videoComposition = mainCompositionInst;
    }
    [assetExport exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self complete:assetExport];
        });
    }];
}
- (void)complete:(AVAssetExportSession*)session {
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        if (self.completeBlock) {
            self.completeBlock(outputURL, nil);
            self.completeBlock = nil;
        }
    }else if (session.status == AVAssetExportSessionStatusFailed){
        if (self.completeBlock) {
            self.completeBlock(nil, session.error);
            self.completeBlock = nil;
        }
    }
}
#pragma mark -- 矫正视频角度
- (AVMutableVideoComposition *)videoCompositionVideoTrack:(AVMutableCompositionTrack *)videoTrack videoAssetTrack:(AVAssetTrack *)videoAssetTrack
{
#warning test
    //3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAssetTrack.asset.duration);

    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_ =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_ = UIImageOrientationDown;
    }
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:videoAssetTrack.asset.duration];

    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];

    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];

    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);

    return mainCompositionInst;
#warning test end 如果没有这段代码，合成后的视频会旋转90度
}
@end
