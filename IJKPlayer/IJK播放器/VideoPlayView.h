//
//  VideoPlayView.h
//  WETool
//
//  Created by WE on 16/10/13.
//  Copyright © 2016年 WE. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, Direction) {
    DirectionLeftOrRight,
    DirectionUpOrDown,
    DirectionNone
};

typedef void (^GoBackBlock)(void);
typedef void (^FullScreenBlock)(void);
typedef void (^SmallWindowBlock)(void);

@interface VideoPlayView : UIView
@property (nonatomic ,assign) CGRect playerFrame;
@property (nonatomic ,copy) GoBackBlock gobackBlock;
@property (nonatomic ,copy) FullScreenBlock fullScreenBlock;
@property (nonatomic ,copy) SmallWindowBlock smallWindowBlock;
@property (weak, nonatomic) IBOutlet UISlider *playSlider;
@property (nonatomic ,copy) NSString *videoStr;//视频Url
@property (assign, nonatomic) CGFloat playRate;//设置初始视频的进度
@property (assign, nonatomic) CGFloat currentPlayRate;//视频的当前进度

+ (instancetype)videoViewWithFrame:(CGRect)frame;

- (void)pauseVideo;

@end
