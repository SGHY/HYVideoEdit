//
//  HYCameraViewController.h
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HYCameraViewController : UIViewController
@property (nonatomic, copy) void (^completeRecordBlock)(NSURL *movieURL);
@property (nonatomic, copy) void (^completeTakeBlock)(UIImage *image);
@end
