//
//  GNDataUtils.m
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/15.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import "GNDataUtils.h"

@implementation GNDataUtils

+ (NSString *)todayDateString {
    NSDate *today = [NSDate date];
    //更改日期显示格式
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyyMMdd"];
    //返回现在时间的字符串
    return [formatter stringFromDate:today];
}

+ (NSString *)dateStringBeforeDays:(NSInteger)days {
    //更改格式
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyyMMdd"];
    //获取到 days 天前的date
    NSDate *before = [NSDate dateWithTimeIntervalSinceNow:-days*60*60*24];
    ////返回 days 天前时间的字符串
    return [formatter stringFromDate:before];
}

@end
