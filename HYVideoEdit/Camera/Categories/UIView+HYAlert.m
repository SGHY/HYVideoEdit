//
//  UIView+HYAlert.m
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import "UIView+HYAlert.h"
#import <objc/runtime.h>
#import "UIView+HYFrame.h"

#define KEY_CC_ALERT_VIEW "UIView.AlertController"

@implementation UIView (HYAlert)
@dynamic alertController;

-(UIAlertController *)alertController{
    NSObject * obj = objc_getAssociatedObject(self, KEY_CC_ALERT_VIEW);
    if (obj && [obj isKindOfClass:[UIAlertController class]]){
        return (UIAlertController *)obj;
    }
    return nil;
}

-(void)setAlertController:(UIAlertController *)alertController
{
    if (nil == alertController){ return; }
    objc_setAssociatedObject(self, KEY_CC_ALERT_VIEW, alertController, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}

-(void)hideAlert{
    if (self.alertController) {
        [self.alertController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - 弹出框
- (void)showErrorAlert:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showAlertView:error.localizedDescription ok:nil cancel:nil];
    });
}

-(void)showAlertView:(NSString *)message ok:(void(^)(UIAlertAction * action))ok cancel:(void(^)(UIAlertAction * action))cancel{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        !cancel ? : cancel(action) ;
    }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        !ok ? : ok(action) ;
    }];
    [alertController addAction:okAction];
    [self.viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Private methods
-(void)findLabel:(UIView*)view succ:(void(^)(UIView *label))succ
{
    for (UIView* subView in view.subviews)
    {
        if ([subView isKindOfClass:[UILabel class]]) {
            if (succ) {
                succ(subView);
            }
        }
        [self findLabel:subView succ:succ];
    }
}
@end
