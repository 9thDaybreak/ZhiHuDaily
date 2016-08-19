//
//  GNTopStory.h
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/18.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import "GNStory.h"

@interface GNTopStory : GNStory

@property (nonatomic, strong) NSString *imageURLString;

- (instancetype)initWithJSON:(NSDictionary *)JSON;

@end
