//
//  GNTopStory.m
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/18.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import "GNTopStory.h"

@implementation GNTopStory

- (instancetype)initWithJSON:(NSDictionary *)JSON {
    self = [[GNTopStory alloc] init];
    if (self) {
        self.title = JSON[@"title"];
        self.storyId = JSON[@"id"];
        self.gaPrefix = JSON[@"ga_prefix"];
        self.type = JSON[@"type"];
        self.imageURLString = JSON[@"image"];
    }
    return self;
}

@end
