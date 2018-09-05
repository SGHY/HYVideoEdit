//
//  UIAlertView+HYBlock.h
//  HYCategoriesDemo
//
//  Created by BigDataAi on 2018/5/11.
//  Copyright © 2018年 BigDataAi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (HYBlock)

typedef void(^UIAlertViewHYCallBackBlock)(NSInteger buttonIndex);

@property (nonatomic, copy) UIAlertViewHYCallBackBlock hy_alertViewCallBackBlock;

+ (void)hy_alertWithCallBackBlock:(UIAlertViewHYCallBackBlock)alertViewCallBackBlock
                            title:(NSString *)title message:(NSString *)message
                 cancelButtonName:(NSString *)cancelButtonName
                otherButtonTitles:(NSString *)otherButtonTitles, ...NS_REQUIRES_NIL_TERMINATION;

@end
