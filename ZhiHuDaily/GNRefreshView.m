//
//  GNRefreshView.m
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/23.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import "GNRefreshView.h"
#import <ViewUtils.h>

@interface GNRefreshView ()

//用户界面活动指示器视图
@property(nonatomic, strong) UIActivityIndicatorView *indicatorView;
//形状图层：白色圆形状层
@property(nonatomic, strong) CAShapeLayer *whiteCircleShapeLayer;
//形状图层：灰度圆形状层
@property(nonatomic, strong) CAShapeLayer *grayCircleShapeLayer;

@end

@implementation GNRefreshView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit {
    
    //初始化
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.bounds];
    self.grayCircleShapeLayer = [CAShapeLayer layer];
    self.whiteCircleShapeLayer = [CAShapeLayer layer];
    
    //线宽
    self.grayCircleShapeLayer.lineWidth = 2.f;
    self.whiteCircleShapeLayer.lineWidth = 2.f;
    
    //边框颜色
    self.grayCircleShapeLayer.strokeColor = [UIColor grayColor].CGColor;
    self.whiteCircleShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    
    //清空填充颜色
    self.grayCircleShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.whiteCircleShapeLayer.fillColor = [UIColor clearColor].CGColor;
    
    //不透明度
    self.grayCircleShapeLayer.opacity = 0;
    self.whiteCircleShapeLayer.opacity = 0;
    
    //路径，贝塞尔曲线：贝塞尔路径椭圆矩形，有两种画圆的方法
    self.grayCircleShapeLayer.path = [UIBezierPath bezierPathWithOvalInRect:self.bounds].CGPath;
    //指定起始角
    self.whiteCircleShapeLayer.path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.width / 2, self.width / 2) radius:self.width / 2 startAngle:M_PI_2 endAngle:M_PI * 5 / 2 clockwise:YES].CGPath;
    self.whiteCircleShapeLayer.strokeEnd = 0;

    [self addSubview:self.indicatorView];
    [self.layer addSublayer:self.grayCircleShapeLayer];
    [self.layer addSublayer:self.whiteCircleShapeLayer];
    
}

- (void)updateProgress:(CGFloat)progress {
    
    if (progress <= 0) {
        self.whiteCircleShapeLayer.opacity = 0;
        self.grayCircleShapeLayer.opacity = 0;
    } else {
        self.whiteCircleShapeLayer.opacity = 1;
        self.grayCircleShapeLayer.opacity = 1;
    }
    
    if (progress > 1) {
        progress = 1;
    }
    
    self.whiteCircleShapeLayer.strokeEnd = progress;
}

- (void)startAnimation {
    [self.indicatorView startAnimating];
}

- (void)stopAnimation {
    [self.indicatorView stopAnimating];
}

@end
