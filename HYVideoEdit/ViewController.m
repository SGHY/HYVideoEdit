//
//  ViewController.m
//  HYVideoEdit
//
//  Created by 上官惠阳 on 2018/8/31.
//  Copyright © 2018年 上官惠阳. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIAlertView+HYBlock.h"
#import "UIAlertController+HYBlocks.h"
#import "HYCameraViewController.h"
#import "HYVideoPlayerViewController.h"
#import "UIView+HYFrame.h"
#import "UIView+HYAlert.h"
#import "HYVideoEditManager.h"

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic, strong) UIButton *seleteBtn;
@property (nonatomic, strong) UIButton *editBtn;

@property (strong, nonatomic)AVPlayer *myPlayer;//播放器
@property (strong, nonatomic)AVPlayerItem *item;//播放单元
@property (strong, nonatomic)AVPlayerLayer *playerLayer;//播放界面（layer）
@property (strong, nonatomic) NSURL *mediaURL;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mediaURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"qidong" ofType:@"mp4"]];

    //初始化一个播放单元
    self.item = [AVPlayerItem playerItemWithURL:self.mediaURL];

    //初始化一个播放器对象
    self.myPlayer = [AVPlayer playerWithPlayerItem:self.item];

    //初始化一个播放器的Layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.myPlayer];
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.playerLayer];

    [self.myPlayer play];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.seleteBtn];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.editBtn];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self.myPlayer pause];
}
#pragma mark -- Property
- (UIButton *)seleteBtn {
    if (!_seleteBtn) {
        _seleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _seleteBtn.bounds = CGRectMake(0.f, 0.f, 85.f, 35.f);
        _seleteBtn.center = self.view.center;
        _seleteBtn.backgroundColor = [UIColor orangeColor];
        _seleteBtn.layer.cornerRadius = 10.f;
        _seleteBtn.titleLabel.font = [UIFont systemFontOfSize:15.f];
        [_seleteBtn setTitle:@"视频选取" forState:UIControlStateNormal];
        [_seleteBtn addTarget:self action:@selector(seleteClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _seleteBtn;
}
- (void)seleteClick:(UIButton *)btn
{
    [UIAlertView hy_alertWithCallBackBlock:^(NSInteger buttonIndex) {
        NSLog(@"%ld",(long)buttonIndex);
        if (buttonIndex == 1) {
            [self seleteFromCamera];
        }else if (buttonIndex == 2){
            [self selectFromPhotosAlbum];
        }
    } title:@"选取视频" message:nil cancelButtonName:@"取消" otherButtonTitles:@"相机",@"相册",nil];
}
- (UIButton *)editBtn
{
    if (!_editBtn) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(self.view.width - 80,25,60,30);
        btn.backgroundColor = [UIColor orangeColor];
        [btn setTitle:@"编辑" forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:15];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.masksToBounds = YES;
        btn.layer.cornerRadius = 10;
        [btn addTarget:self action:@selector(editAction:) forControlEvents:UIControlEventTouchUpInside];
        _editBtn = btn;
    }

    return _editBtn;
}
- (void)editAction:(UIButton *)btn
{
    [UIAlertController showActionSheetInViewController:self withTitle:@"编辑视频" message:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@[@"视频裁剪",@"视频拼接",@"添加背景音乐",@"添加水印"] popoverPresentationControllerBlock:^(UIPopoverPresentationController * _Nonnull popover) {
        popover.sourceView = self.view;
        popover.sourceRect = btn.frame;
    } tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
        if (buttonIndex == 2) {
            //视频裁剪
            [self.myPlayer pause];
            [[HYVideoEditManager share] videoCutterVideoUrl:self.mediaURL fromTime:2 cutterDuration:2 complete:^(NSURL *exportURL, NSError *error) {
                if(error){
                    [self.view showErrorAlert:error];
                    return ;
                }
                AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:exportURL];
                [self.myPlayer replaceCurrentItemWithPlayerItem:playItem];
                [self.myPlayer play];
            }];
        }else if (buttonIndex == 3){
            //视频拼接
            [self.myPlayer pause];
            NSString *path = [[NSBundle mainBundle] pathForResource:@"qidong" ofType:@"mp4"];
            NSURL *url = [NSURL fileURLWithPath:path];
            NSArray *videoUrls = @[url,self.mediaURL];
            [[HYVideoEditManager share] videoMergeVideoUrls:videoUrls complete:^(NSURL *exportURL, id error) {
                if(error){
                    [self.view showErrorAlert:error];
                    return ;
                }

                AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:exportURL];
                [self.myPlayer replaceCurrentItemWithPlayerItem:playItem];
                [self.myPlayer play];
            }];
        }else if (buttonIndex == 4){
            //添加背景音乐
            [self.myPlayer pause];
            NSString *path = [[NSBundle mainBundle] pathForResource:@"月半弯" ofType:@"mp3"];
            NSURL *url = [NSURL fileURLWithPath:path];
            [[HYVideoEditManager share] videoAddBackgroundMusicVideoUrl:self.mediaURL audioUrl:url complete:^(NSURL *exportURL, id error) {
                if(error){
                    [self.view showErrorAlert:error];
                    return ;
                }

                AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:exportURL];
                [self.myPlayer replaceCurrentItemWithPlayerItem:playItem];
                [self.myPlayer play];
            }];
        }else if(buttonIndex == 5){
            [self.myPlayer pause];
            [[HYVideoEditManager share] videoAddWatermarkVideoUrl:self.mediaURL complete:^(NSURL *exportURL, id error) {
                if(error){
                    [self.view showErrorAlert:error];
                    return ;
                }

                AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:exportURL];
                [self.myPlayer replaceCurrentItemWithPlayerItem:playItem];
                [self.myPlayer play];
            }];
        }
    }];
}
-(void)selectFromPhotosAlbum
{
    UIImagePickerController *picker=[[UIImagePickerController alloc] init];

    picker.delegate=self;
    picker.allowsEditing=NO;
    picker.videoMaximumDuration = 10.0;//视频最长长度
    picker.videoQuality = UIImagePickerControllerQualityTypeMedium;//视频质量

    //媒体类型：@"public.movie" 为视频  @"public.image" 为图片
    //这里只选择展示视频
    picker.mediaTypes = [NSArray arrayWithObjects:@"public.movie", nil];

    picker.sourceType= UIImagePickerControllerSourceTypeSavedPhotosAlbum;

    [self presentViewController:picker animated:YES completion:nil];
}
- (void)seleteFromCamera
{
    HYCameraViewController *cameraVc = [[HYCameraViewController alloc] init];
    __weak typeof(self) weakSelf = self;
    cameraVc.completeRecordBlock = ^(NSURL *movieURL) {
        weakSelf.mediaURL = movieURL;
        AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:movieURL];
        [weakSelf.myPlayer replaceCurrentItemWithPlayerItem:playItem];
        [weakSelf.myPlayer play];
    };
    [self presentViewController:cameraVc animated:YES completion:nil];
}
#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{

    NSString *mediaType=[info objectForKey:UIImagePickerControllerMediaType];

    NSURL *mediaURL;
    if ([mediaType isEqualToString:@"public.movie"]){
        //如果是视频
        NSURL *url = info[UIImagePickerControllerMediaURL];//获得视频的URL
        NSLog(@"url %@",url);
        mediaURL = url;
    }

    self.mediaURL = mediaURL;

    AVPlayerItem *playItem = [AVPlayerItem playerItemWithURL:mediaURL];
    [self.myPlayer replaceCurrentItemWithPlayerItem:playItem];
    [self.myPlayer play];

    [self dismissViewControllerAnimated:YES completion:^{
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
