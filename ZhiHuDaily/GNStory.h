//
//  GNStory.h
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/18.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GNStory : NSObject

@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *storyId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *gaPrefix;
@property (nonatomic, strong) NSArray *images;

- (instancetype)initWithJSON:(NSDictionary *)JSON;


@end
