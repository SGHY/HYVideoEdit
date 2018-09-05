//
//  UIView+HYAlert.h
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (HYAlert)
@property(nonatomic, strong ,readonly)UIAlertController *alertController;
// 弹出框
-(void)showErrorAlert:(NSError *)error;

-(void)showAlertView:(NSString *)message ok:(void(^)(UIAlertAction * action))ok cancel:(void(^)(UIAlertAction * action))cancel;

-(void)hideAlert;
@end
