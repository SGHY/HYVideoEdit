//
//  HYVideoEditManager.h
//  HYVideoEdit
//
//  Created by 上官惠阳 on 2018/8/31.
//  Copyright © 2018年 上官惠阳. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HYVideoEditManager : NSObject
+ (HYVideoEditManager *)share;

/**
 视频裁剪
 @param videoUrl 视频URL
 @param fromTime 从视频哪一秒开始裁剪
 @param cutterDuration 裁取视频的长度 单位为秒
 @param completeBlock 裁剪结束回调
 */
-(void)videoCutterVideoUrl:(NSURL *)videoUrl fromTime:(CGFloat)fromTime cutterDuration:(CGFloat)cutterDuration complete:(void (^)(NSURL *exportURL, id error))completeBlock;

/**
 视频合并
 @param videoUrls 视频url数组
 @param completeBlock 合并视频结束回调
 */
-(void)videoMergeVideoUrls:(NSArray <NSURL *>*)videoUrls complete:(void (^)(NSURL *exportURL, id error))completeBlock;


/**
 视频添加背景音乐
 @param videoUrl 视频URL
 @param audioUrl 背景音乐URL
 @param completeBlock 添加背景音乐结束回调
 */
- (void)videoAddBackgroundMusicVideoUrl:(NSURL *)videoUrl audioUrl:(NSURL *)audioUrl complete:(void (^)(NSURL *exportURL, id error))completeBlock;
/**
 添加简单的水印
 @param videoUrl 视频URL
 @param completeBlock 结束回调
 */
- (void)videoAddWatermarkVideoUrl:(NSURL *)videoUrl complete:(void (^)(NSURL *exportURL, id error))completeBlock;
@end
