//
//  GNCarouselView.h
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/18.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GNCarouselView : UIView

@property (strong, nonatomic) IBOutlet UIView *view;

- (void)setTopStories:(NSArray *)topStories;

@end
