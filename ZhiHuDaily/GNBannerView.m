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
    }
    
    return self;
}

@end
