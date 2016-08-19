//
//  GNSideMenuViewController.m
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/19.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import "GNSideMenuViewController.h"
#import "GNSideMenuCell.h"
#import <QuickLook/QuickLook.h>

@interface GNSideMenuViewController () <UITableViewDataSource, UITabBarDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *menuItems;

@end

@implementation GNSideMenuViewController

static NSString *const kCellIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.menuTableView registerNib:[UINib nibWithNibName:@"GNSideMenuCell" bundle:nil] forCellReuseIdentifier:kCellIdentifier];
    self.menuTableView.delegate = self;
    self.menuTableView.dataSource = self;
    
    self.menuItems = @[
                       @"首页",
                       @"日常心理学",
                       @"用户推荐日报",
                       @"电影日报",
                       @"不许无聊",
                       @"设计日报",
                       @"大公司日报",
                       @"财经日报",
                       @"互联网安全",
                       @"开始游戏",
                       @"音乐日报",
                       @"动漫日报",
                       @"体育日报"
                       ];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.menuItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GNSideMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    cell.menuTitle.text = self.menuItems[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

//空

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UIColor *backgroundColor = [UIColor colorWithRed:0.106 green:0.125 blue:0.141 alpha:1];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.menuTableView.bounds;
    gradientLayer.colors = @[ (id)[UIColor clearColor].CGColor, (id)backgroundColor.CGColor];
    gradientLayer.endPoint = CGPointMake(0.5, 0.8);
    gradientLayer.startPoint = CGPointMake(0.5, 1);
    self.menuTableView.layer.mask = gradientLayer;
}

@end
