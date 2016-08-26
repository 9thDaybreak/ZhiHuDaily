//
//  GNBannerView.m
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/18.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import "GNBannerView.h"

@interface GNBannerView ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation GNBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //初始化时，获取到 xib 中的 View
        UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"GNBannerView" owner:self options:nil] firstObject];
        view.frame = self.bounds;
        [self addSubview:view];
        
        self.bannerImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.frame = self.bannerImageView.bounds;
        self.gradientLayer.colors = @[
                                      (id)[UIColor colorWithWhite:0.2 alpha:0.6].CGColor,
                                      (id)[UIColor clearColor].CGColor,
                                      (id)[UIColor clearColor].CGColor,
                                      (id)[UIColor colorWithWhite:0.2 alpha:0.6].CGColor
                                      ];
        self.gradientLayer.locations = @[@0.0, @0.4, @0.7, @1.0];
        
        [self.bannerImageView.layer addSublayer:self.gradientLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.gradientLayer.frame = self.bannerImageView.bounds;
    [CATransaction commit];
}

@end
