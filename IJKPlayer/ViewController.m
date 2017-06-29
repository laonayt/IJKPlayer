//
//  ViewController.m
//  IJKPlayer
//
//  Created by WE on 2017/6/22.
//  Copyright © 2017年 g. All rights reserved.
//

#import "ViewController.h"
#import "VideoPlayView.h"

#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width

@interface ViewController ()
@property (nonatomic ,strong) VideoPlayView *videoView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //2、初始化View
    self.videoView = [VideoPlayView videoViewWithFrame:CGRectMake(0, 0, SCREENWIDTH, 200)];
    [self.view addSubview:_videoView];
}
@end
