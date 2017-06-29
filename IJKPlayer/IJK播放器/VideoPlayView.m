//
//  VideoPlayView.m
//  WETool
//
//  Created by WE on 16/10/13.
//  Copyright © 2016年 WE. All rights reserved.
//

#import "VideoPlayView.h"
#import "UIDevice+XJDevice.h"
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface VideoPlayView()
@property(atomic, retain) id<IJKMediaPlayback> ijkPlayer;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *replayBtn;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIButton *bigPlayBtn;
@property (weak, nonatomic) IBOutlet UILabel *mediaTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UILabel *playErrorLabel;
@property (weak, nonatomic) IBOutlet UIView *brightView;
@property (weak, nonatomic) IBOutlet UIProgressView *lightProgressView;
@property (weak, nonatomic) IBOutlet UILabel *startRateLabel;

@property (assign ,nonatomic) BOOL isPlaySliderBeingDrag;
@property (strong ,nonatomic) UITapGestureRecognizer *onceTap;
@property (strong ,nonatomic) UITapGestureRecognizer *twiceTap;

@property (assign, nonatomic) CGPoint startPoint;//手势触摸起始位置
@property (assign, nonatomic) CGFloat startVB;//记录当前音量/亮度
@property (strong, nonatomic) UISlider *volumeViewSlider;//控制音量
@property (assign, nonatomic) CGFloat currentRate;//当期视频播放的进度
@property (strong, nonatomic) MPVolumeView *volumeView;//控制音量的view
@property (assign, nonatomic) Direction direction;

@end


@implementation VideoPlayView

+ (instancetype)videoViewWithFrame:(CGRect)frame{
    VideoPlayView *view = [[NSBundle mainBundle] loadNibNamed:@"VideoPlayView" owner:self options:nil].lastObject;
    view.frame = frame;
    view.playerFrame = frame;
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
     //0、初始化
    CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI/2 * 3);
    _brightView.transform = trans;
    _lightProgressView.progress = [UIScreen mainScreen].brightness;
    
    self.volumeView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width * 9.0 / 16.0);
   
    [IJKFFMoviePlayerController setLogReport:NO];
    
    //1、限制锁屏
    [UIApplication sharedApplication].idleTimerDisabled=YES;
    
    //2、添加手势
    UITapGestureRecognizer *onceTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    self.onceTap = onceTap;
    onceTap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:onceTap];
    
    UITapGestureRecognizer *twiceTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    self.twiceTap = twiceTap;
    twiceTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:twiceTap];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
    tap.cancelsTouchesInView = NO;
    [self.bottomView addGestureRecognizer:tap];//防止bottomMenuView也响应了self这个view的单击手势
    
    //3、监听播放器
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinish) name:IJKMPMoviePlayerPlaybackDidFinishNotification object:_ijkPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackStateDidChange) name:IJKMPMoviePlayerPlaybackStateDidChangeNotification object:_ijkPlayer];
    
    //4、监听屏幕方向改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - 外部方法

- (void)pauseVideo {
    [self playBtnClick:_playBtn];
    _bigPlayBtn.hidden = NO;
}

#pragma mark - Set方法

- (void)setPlayRate:(CGFloat)playRate {
    _playRate = playRate;
    if (_ijkPlayer.playbackState == IJKMPMoviePlaybackStatePlaying) {
        _ijkPlayer.currentPlaybackTime = playRate;
        self.isPlaySliderBeingDrag = NO;
        [self.activityView startAnimating];
        [self getMediaTime];
        //显示进度条
        if (_bottomView.hidden) {
            _bottomView.hidden = NO;
            _backBtn.hidden = NO;
        }
    }
}

#pragma mark - 初始化播放器

- (void)setVideoStr:(NSString *)videoStr {
    _videoStr = videoStr;
    
    if ([videoStr containsString:@"rtsp"]) {
        _playSlider.hidden = YES;
    }
    
    self.currentRate = 0;
    
    if (self.ijkPlayer) {
        [self closeVideoPlay];
    }
    
    self.ijkPlayer = [[IJKFFMoviePlayerController alloc] initWithContentURLString:videoStr withOptions:nil];
    self.ijkPlayer.view.frame = _playView.bounds;
    self.ijkPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_playView addSubview:self.ijkPlayer.view];
    
    [_ijkPlayer prepareToPlay];
    [_ijkPlayer play];
}

#pragma mark - 手势
- (void)tapView:(UITapGestureRecognizer *)tap {
    if (tap.numberOfTapsRequired == 1) {
        _bottomView.hidden = !_bottomView.hidden;
        _backBtn.hidden = !_backBtn.hidden;
        
        if (!_bottomView.hidden) {
            [self performSelector:@selector(hideBottomView) withObject:nil afterDelay:3];
        }
        
    } else if (tap.numberOfTapsRequired == 2) {
        [self playBtnClick:_playBtn];
        _bigPlayBtn.hidden = NO;
    }
}

- (void)hideBottomView{
    [UIView animateWithDuration:0.5 animations:^{
        _bottomView.alpha = 0;
        _backBtn.alpha = 0;
    } completion:^(BOOL finished) {
        _bottomView.alpha = 1;
        _backBtn.alpha = 1;
        _bottomView.hidden = YES;
        _backBtn.hidden = YES;
    }];
}

#pragma mark - 返回
- (IBAction)backBtnClick:(id)sender {
    if (_fullScreenBtn.selected) {
        [self fullScreenBtnClick:_fullScreenBtn];
    } else {
        
        self.currentPlayRate = _ijkPlayer.currentPlaybackTime;
        
        [self closeVideoPlay];
        
        if (self.gobackBlock) {
            self.gobackBlock();
        }
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    }
}

#pragma mark - 关闭播放器
-(void)closeVideoPlay{
    [self.ijkPlayer pause];
    [self.ijkPlayer stop];
    [self.ijkPlayer shutdown];
    [self.ijkPlayer.view removeFromSuperview];
    self.ijkPlayer = nil;
    
//    [self.ijkPlayer.view removeFromSuperview];
//    [_ijkPlayer shutdown];
//    _ijkPlayer = nil;
}

#pragma mark - 播放
- (IBAction)playBtnClick:(UIButton *)sender {
    if (sender.selected) {
        [_ijkPlayer pause];
        _bigPlayBtn.hidden = NO;
    } else {
        [_ijkPlayer play];
        _bigPlayBtn.hidden = YES;
    }
    sender.selected  = !sender.selected;
}

#pragma mark - 全屏
- (IBAction)fullScreenBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    if (sender.selected == YES) {
        [UIDevice setOrientation:UIInterfaceOrientationLandscapeRight];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        self.frame = self.window.bounds;
        if (self.fullScreenBlock) {
            self.fullScreenBlock();
        }
    } else {
        [UIDevice setOrientation:UIInterfaceOrientationPortrait];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.frame = self.playerFrame;
        if (self.smallWindowBlock) {
            self.smallWindowBlock();
        }
    }
}

#pragma mark - 大播放按钮点击
- (IBAction)bigPlayBtnClick:(UIButton *)sender {
    [UIView animateWithDuration:0.3 animations:^{
        sender.alpha = 0;
    } completion:^(BOOL finished) {
        sender.alpha = 1;
        sender.hidden = YES;
        [self playBtnClick:_playBtn];
    }];
}

#pragma mark - 重播
- (IBAction)rePlayBtnClick:(UIButton *)sender {
    self.videoStr = _videoStr;
    sender.hidden = YES;
}

#pragma mark - PlaySlider方法 -> 快进

- (IBAction)playSliderTouchDown:(id)sender {
    self.isPlaySliderBeingDrag = YES;
}

- (IBAction)playSliderTouchUpInside:(id)sender {
    _ijkPlayer.currentPlaybackTime = self.playSlider.value;
    self.isPlaySliderBeingDrag = NO;
    [self.activityView startAnimating];
}

- (IBAction)playSliderValueChanged:(id)sender {
    [self getMediaTime];
}

#pragma mark IJK监听
- (void)didFinish {
    if (_ijkPlayer.loadState == 3) {
        _replayBtn.hidden = NO;
        _backBtn.hidden = NO;
    } else if (_ijkPlayer.loadState == 0) {
        [_activityView stopAnimating];
        _playErrorLabel.hidden = NO;
        
        [self removeGestureRecognizer:self.onceTap];
        [self removeGestureRecognizer:self.twiceTap];
    }
    NSLog(@"【播放结束状态**%ld】",(long)_ijkPlayer.loadState);
}

- (void)moviePlayBackStateDidChange {
    if (_ijkPlayer.playbackState == IJKMPMoviePlaybackStatePlaying) {
        
        _playBtn.selected = YES;
        
        [_activityView stopAnimating];

        _playSlider.maximumValue = _ijkPlayer.duration;
        
        [self getMediaTime];
        
        if (!_bottomView.hidden) {
            [self performSelector:@selector(hideBottomView) withObject:nil afterDelay:3];
        }
        
        if (self.playRate) {
            _startRateLabel.hidden = NO;
            
            _ijkPlayer.currentPlaybackTime = _playRate;
            
            _playRate = 0;
            
            [UIView animateWithDuration:3 animations:^{
                _startRateLabel.alpha = 0;
            } completion:^(BOOL finished) {
                _startRateLabel.alpha = 1;
                _startRateLabel.hidden = YES;
            }];
            
        }
    }
    NSLog(@"【播放成功**%ld】",(long)_ijkPlayer.playbackState);
}

#pragma mark - 屏幕方向改变的监听
- (void)orientChange:(NSNotification *)notification {
    UIDeviceOrientation orient = [[UIDevice currentDevice] orientation];
    
    if (orient == UIDeviceOrientationPortrait) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.frame = _playerFrame;
        _fullScreenBtn.selected = NO;
        if (self.smallWindowBlock) {
            self.smallWindowBlock();
        }
    } else if (orient == UIDeviceOrientationLandscapeLeft || orient == UIDeviceOrientationLandscapeRight) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        self.frame = self.window.bounds;
        _fullScreenBtn.selected = YES;
        if (self.fullScreenBlock) {
            self.fullScreenBlock();
        }
    }
}

//触摸开始
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    //获取触摸开始的坐标
    UITouch *touch = [touches anyObject];
    CGPoint currentP = [touch locationInView:self];
    
    //记录首次触摸坐标
    self.startPoint = currentP;
    //检测用户是触摸屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是音量，右边是亮度
    if (self.startPoint.x <= self.frame.size.width / 2.0) {
        //音/量
        self.startVB = self.volumeViewSlider.value;
    } else {
        //亮度
        self.startVB = [UIScreen mainScreen].brightness;
    }
    //方向置为无
    self.direction = DirectionNone;
}

//移动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    
    if (!self.fullScreenBtn.selected) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint currentP = [touch locationInView:self];
    //得出手指在Button上移动的距离
    CGPoint panPoint = CGPointMake(currentP.x - self.startPoint.x, currentP.y - self.startPoint.y);
    //分析出用户滑动的方向
    if (self.direction == DirectionNone) {
        if (panPoint.x >= 30 || panPoint.x <= -30) {
            //进度
            self.direction = DirectionLeftOrRight;
        } else if (panPoint.y >= 30 || panPoint.y <= -30) {
            //音量和亮度
            self.direction = DirectionUpOrDown;
        }
    }
    
    if (self.direction == DirectionNone) {
        return;
    } else if (self.direction == DirectionUpOrDown) {
        //音量和亮度
        if (self.startPoint.x <= self.frame.size.width / 2.0) {
            //音量
            if (panPoint.y < 0) {
                //增大音量
                [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                if (self.startVB + (-panPoint.y / 30 / 10) - self.volumeViewSlider.value >= 0.1) {
                    [self.volumeViewSlider setValue:0.1 animated:NO];
                    [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                }
                
            } else {
                //减少音量
                [self.volumeViewSlider setValue:self.startVB - (panPoint.y / 30.0 / 10) animated:YES];
            }
            
        } else {
            _brightView.hidden = NO;
        
            //调节亮度
            if (panPoint.y < 0) {
                //增加亮度
                [[UIScreen mainScreen] setBrightness:self.startVB + (-panPoint.y / 30.0 / 10)];
                
            } else {
                //减少亮度
                [[UIScreen mainScreen] setBrightness:self.startVB - (panPoint.y / 30.0 / 10)];
                
            }
            _lightProgressView.progress = [UIScreen mainScreen].brightness;
        }
    } else if (self.direction == DirectionLeftOrRight ) {
        //显示进度条
        if (_bottomView.hidden) {
            _bottomView.hidden = NO;
            _backBtn.hidden = NO;
        }
        //进度
        CGFloat rate = panPoint.x / 100 / 50;
        
        self.currentRate = self.currentRate + rate;
        
        if (self.currentRate > 1) {
            self.currentRate = 1;
        } else if (self.currentRate < 0) {
            self.currentRate = 0;
        }
    }
}

//触摸结束
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.direction == DirectionLeftOrRight) {
        _ijkPlayer.currentPlaybackTime = self.currentRate*self.playSlider.maximumValue;
        self.isPlaySliderBeingDrag = NO;
        [self.activityView startAnimating];
        [self getMediaTime];
        
    }
    if (!_brightView.hidden) {
        [UIView animateWithDuration:1.2f animations:^{
            _brightView.alpha = 0;
        } completion:^(BOOL finished) {
            _brightView.hidden = YES;
            _brightView.alpha = 1;
        }];
    }
}

#pragma mark - 计算时间
- (void)getMediaTime {
    NSString *timeString;
    
    if (self.isPlaySliderBeingDrag) {
        timeString = [self MJJPlayerTimeStyle:_playSlider.value];
    } else {
        timeString = [self MJJPlayerTimeStyle:_ijkPlayer.currentPlaybackTime];
        _playSlider.value = _ijkPlayer.currentPlaybackTime;
    }
    
    _mediaTimeLabel.text = [NSString stringWithFormat:@"00:%@/00:%@",timeString,[self MJJPlayerTimeStyle:_ijkPlayer.duration]];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getMediaTime) object:nil];
    [self performSelector:@selector(getMediaTime) withObject:nil afterDelay:0.5];
}

#pragma mark - 定义视屏时长样式
- (NSString *)MJJPlayerTimeStyle:(NSInteger)time{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (time/3600>1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }else{
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showTimeStyle = [formatter stringFromDate:date];
    return showTimeStyle;
}

#pragma mark - 懒加载
- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        [_volumeView sizeToFit];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                self.volumeViewSlider = (UISlider*)view;
                break;
            }
        }
    }
    return _volumeView;
}

@end
