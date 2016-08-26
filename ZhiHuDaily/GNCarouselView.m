//
//  GNCarouselView.m
//  ZhiHuDaily
//
//  Created by 肖杰华 on 16/8/18.
//  Copyright © 2016年 ZhuSunGongZuoShi. All rights reserved.
//

#import "GNCarouselView.h"
#import "GNTopStory.h"
#import "GNBannerView.h"
#import <UIImageView+WebCache.h>
#import <Masonry.h>

@interface GNCarouselView () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (strong, nonatomic) NSTimer *timer;

#define GNScrollViewWidth self.scrollView.frame.size.width
#define GNScrollViewHeight self.scrollView.frame.size.height

@end

@implementation GNCarouselView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        //因为此方法返回的是个数组，是为了以防有多个对象返回，所以要在后面添加firstObject
        self.view = [[[NSBundle mainBundle]loadNibNamed:@"GNCarouselView" owner:self options:nil] firstObject];
        
        self.view.frame = self.bounds;
        [self addSubview:self.view];
        
        //pageControl的颜色
        self.pageControl.pageIndicatorTintColor = [UIColor grayColor];
        
        //选中pageControl的颜色
        self.pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setTopStories:(NSArray *)topStories {
    
    if (!topStories) {
        return;
    }

    //内容大小，即scrollView可以滚动的区域。scrollView的宽度为屏幕宽度 * 图片的个数，高度为 View 的高度
    self.scrollView.contentSize = CGSizeMake(GNScrollViewWidth * topStories.count, 0);

    //点数量
    self.pageControl.numberOfPages = topStories.count;
    //当前页
    self.pageControl.currentPage = 0;
    //只有一页时隐藏 pageControl
    self.pageControl.hidesForSinglePage = YES;
    //滚动条显示
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;

    UIView *lastBannerView = nil;
    
    for (int i = 0; i < topStories.count; i++) {
        
        //导入模型
         GNTopStory *topStory = topStories[i];
        
        //初始化轮播图的 View
        GNBannerView *bannerView = [[GNBannerView alloc] init];
        
        //设置bannerView的图片和标签
        [bannerView.bannerImageView sd_setImageWithURL:[NSURL URLWithString:topStory.imageURLString]];
        bannerView.bannerLabel.text = topStory.title;
        
        //设置图片的 frame
        [self.scrollView addSubview:bannerView];
        [bannerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(self.scrollView.mas_height);
            make.width.mas_equalTo(GNScrollViewWidth);
            make.top.equalTo(self.scrollView.mas_top);
            
            if (lastBannerView) {
                make.left.equalTo(lastBannerView.mas_right);
            } else {
                make.left.equalTo(self.scrollView.mas_left);
            }
        }];
        lastBannerView = bannerView;
//        bannerView.frame = CGRectMake(i * GNScrollViewWidth, 0, GNScrollViewWidth, GNScrollViewHeight);
        //将图片添加进 scrollView
        
    }
    //启动定时器
    [self startTimer];
}

#pragma mark - NSTimer

/**
 *  TimeInterval:在本例中表示每隔几秒自动滚动一次
 *  target:表示监听者
 *  selector:表示要监听的方法
 *  userInfo:表示是否需要传入信息，在本例中不需要
 *  repeats:表示是否需要重复，在本例中需要重复
 **/

//开始定时器
- (void)startTimer {
    //创建定时器
    self.timer = [NSTimer scheduledTimerWithTimeInterval:4.0 target:self selector:@selector(nextPage:) userInfo:nil repeats:YES];
    
    // 修改timer在RunLoop中的模式，以便在主线程之外可以分配时间来处理定时器
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

//停止 NSTimer
- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)nextPage:(NSTimer *)timer {
    
    //得出下一页的页码
    NSInteger nextPage = self.pageControl.currentPage + 1;
    
    //当页码超过最后一页时，返回到第一页
    if (nextPage == self.pageControl.numberOfPages) {
        nextPage = 0;
    }
    
    [self.scrollView setContentOffset:CGPointMake(nextPage * GNScrollViewWidth, 0) animated:YES];
}

#pragma mark - UIScrollViewDelegate

//轮动时
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    //计算 page，两种方法
//    int page = (scrollView.contentOffset.x + GNScrollViewWidth / 2) / GNScrollViewWidth;
    int page = scrollView.contentOffset.x / GNScrollViewWidth + 0.5;
    
    self.pageControl.currentPage = page;
}

//拖拽时停止定时器
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self stopTimer];
}

// 用户拖拽结束时，重新开启定时器
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self startTimer];
}

@end
