//
//  GNStory.m
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/18.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import "GNStory.h"

@interface GNStory ()

@property (nonatomic, assign) BOOL multiPic;

@end


@implementation GNStory

- (instancetype)initWithJSON:(NSDictionary *)JSON {
    self = [[GNStory alloc] init];
    
    if (self) {
        self.title = JSON[@"title"];
        self.storyId = JSON[@"id"];
        self.gaPrefix = JSON[@"ga_prefix"];
        self.type = JSON[@"type"];
        self.multiPic = JSON[@"multiPic"];
        self.images = JSON[@"images"];
    }
    return self;
}

@end
