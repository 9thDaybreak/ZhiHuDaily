//
//  GNRefreshView.h
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/23.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GNRefreshView : UIView

- (void)updateProgress:(CGFloat)progress;

- (void)startAnimation;

- (void)stopAnimation;

@end
