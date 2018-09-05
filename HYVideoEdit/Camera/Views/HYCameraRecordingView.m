//
//  HYCameraRecordingView.m
//  HYCamera
//
//  Created by leve on 2018/6/13.
//  Copyright © 2018年 leve. All rights reserved.
//

#import "HYCameraRecordingView.h"

#define KCircleLineWidth 5.0f
@implementation HYCameraRecordingView
{
    UIView *_middleView;
}
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        UIView *middleView = [[UIView alloc] initWithFrame:CGRectMake(10, 10, CGRectGetWidth(frame)-20, CGRectGetHeight(frame)-20)];
        middleView.layer.cornerRadius = CGRectGetWidth(middleView.frame)/2;
        middleView.backgroundColor = [UIColor whiteColor];
        [self addSubview:middleView];
        _middleView = middleView;
    }
    return self;
}
- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect
{
    //路径
    UIBezierPath *path = [[UIBezierPath alloc] init];
    //线宽
    path.lineWidth = KCircleLineWidth;
    //颜色
    [[UIColor greenColor] set];
    //拐角
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    //半径
    CGFloat radius = (MIN(rect.size.width, rect.size.height) - KCircleLineWidth) * 0.5;
    //画弧（参数：中心、半径、起始角度(3点钟方向为0)、结束角度、是否顺时针）
    [path addArcWithCenter:(CGPoint){rect.size.width * 0.5, rect.size.height * 0.5} radius:radius startAngle:M_PI * 1.5 endAngle:M_PI * 1.5 + M_PI * 2 * _progress clockwise:YES];
    //连线
    [path stroke];
}
@end
