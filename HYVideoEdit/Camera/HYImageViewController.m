//
//  HYImageViewController.m
//  HYCamera
//
//  Created by 上官惠阳 on 2018/7/22.
//  Copyright © 2018年 leve. All rights reserved.
//

#import "HYImageViewController.h"

@interface HYImageViewController ()
@property (strong, nonatomic) UIImageView *imageView;
@end

@implementation HYImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.imageView];

    [self createReturnBack];
}
- (void)viewDidAppear:(BOOL)animated
{
    self.imageView.image = self.image;
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
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    }
    return _imageView;
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
