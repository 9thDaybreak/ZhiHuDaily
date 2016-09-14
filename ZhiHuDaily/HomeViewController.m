//
//  HomeViewController.m
//  
//
//  Created by 肖杰华 on 16/8/17.
//
//

#import "HomeViewController.h"
#import "GNDataUtils.h"
#import <AFNetworking.h>
#import "GNTopStory.h"
#import "GNCarouselView.h"
#import "GNStoryCell.h"
#import <Masonry.h>
#import <ViewUtils.h>
#import "GNSideMenuViewController.h"
#import <UIImageView+WebCache.h>
#import "GNRefreshView.h"
#import "GNSideMenuViewController.h"
#import "GN-Prefix.pch"

@interface HomeViewController () <UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>

#define kMainScreenWidth [UIScreen mainScreen].bounds.size.width

//声明天数
@property (nonatomic, assign) NSInteger days;
//声明数据
@property (nonatomic, strong) NSMutableArray *data;
//声明是否正在加载
@property (nonatomic, assign) BOOL isLoading;
//是否显示侧边栏
@property (nonatomic, assign) BOOL isShowSideMenu;
//绘制导航栏视图
@property (strong, nonatomic) UIView *topView;
//轮播图的 View（旋转木马）
@property (weak, nonatomic) IBOutlet GNCarouselView *CarouselView;
//刷新视图
@property (weak, nonatomic) IBOutlet GNRefreshView *RefreshView;
//表视图
@property (weak, nonatomic) IBOutlet UITableView *TableView;
//主视图
@property (weak, nonatomic) IBOutlet UIView *HomeView;
//导航栏 Label
@property (weak, nonatomic) IBOutlet UILabel *TodayTitleLabel;
//显示侧边栏按钮
@property (weak, nonatomic) IBOutlet UIButton *ShowSideMenuButton;
//给控件添加点击事件
@property(nonatomic, strong) UITapGestureRecognizer *tapToHideSideMenu;
//homeView
@property (weak, nonatomic) IBOutlet UIView *homeView;
//侧边栏控制器
@property(nonatomic, strong) GNSideMenuViewController *sideMenuVC;
//拖动手势
@property(nonatomic, strong) UIPanGestureRecognizer *pan;

//约束
//CarouseView 的离上约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *CarouseViewTop;
//CarouseView 的高度约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *CarouselViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *homeViewLeft;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *homeViewRight;

@property(nonatomic, assign) BOOL isRefreshing;
@property(nonatomic, strong) UIView *tapView;

@end

@implementation HomeViewController

//偏移量40
static CGFloat const kRefreshOffsetY = 40.f;
//侧边栏的宽度
static CGFloat const kSideMenuWidth = 225.f;
//侧边栏动画的时间长度
static CGFloat const kSideMenuAnimationDuration = 0.2f;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.days = -1;    
    self.data = [[NSMutableArray alloc] init];

    //添加 tableViewCell
    [self.TableView registerNib:[UINib nibWithNibName:@"GNStoryCell" bundle:nil] forCellReuseIdentifier:@"StoryCell"];
    
    //隐藏 tableView 的滚动条
    self.TableView.showsVerticalScrollIndicator = NO;
    
    //绘制导航栏
    if (!self.topView) {
        self.topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, 64)];
        [self.HomeView insertSubview:self.topView belowSubview:self.ShowSideMenuButton];
        self.topView.backgroundColor = [UIColor clearColor];
    }
    
    //在 homeView 中添加手势识别
    [self.homeView addGestureRecognizer:self.pan];
    
    //设置侧边栏菜单
    //获取 xib
    self.sideMenuVC = [[GNSideMenuViewController alloc] initWithNibName:@"GNSideMenuViewController" bundle:nil];
    //添加进父View
    [self.view addSubview:self.sideMenuVC.view];
    [self addChildViewController:self.sideMenuVC];
    //当某个子试图控制器将加入到父视图控制器时，parent参数为父视图控制器。即：[将被加入的子视图控制器 didMoveToParentViewController:父视图控制器];
    [self.sideMenuVC didMoveToParentViewController:self];
    //设置 View 的 xy = (0,0)
    self.sideMenuVC.view.right = 0;
    self.sideMenuVC.view.top = 0;
    //获取主屏幕的高
    self.sideMenuVC.view.height = [UIScreen mainScreen].bounds.size.height;
    self.sideMenuVC.view.width = 225;
    //设置标识符，是否显示侧边栏
    self.isShowSideMenu = NO;
    
    //添加点击隐藏侧边菜单
    self.tapToHideSideMenu = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSideMenu)];
    
    self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.HomeView addGestureRecognizer:self.pan];
    
    //获取最新的数据
    [self fetchData];
    
//    self.RefreshView.hidden = YES;

}

- (void)fetchData {
    
    //是否正在加载
    self.isLoading = YES;
    
    //设置 URL，当 days 为-1时获取最新的数据，当days 为-1以外
    NSString *url = nil;
    if (self.days == -1) {
        url = @"http://news-at.zhihu.com/api/4/news/latest";
    } else {
        url = [@"http://news.at.zhihu.com/api/4/news/before/" stringByAppendingString:[GNDataUtils dateStringBeforeDays:self.days]];
    }
    
    //URL 会话配置：默认
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    //会话配置初始化
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    
    [[manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        //如果days 为-1，
        if (self.days == -1) {
            
            //获取轮播图的数据
            NSArray *topStoriesJSON = responseObject[@"top_stories"];
            NSMutableArray *topStories = [[NSMutableArray alloc] init];
            for (NSDictionary *JSON in topStoriesJSON) {
                //调用模型类GNTopStory
                GNTopStory *topStory = [[GNTopStory alloc] initWithJSON:JSON];
                //将对象添加进空数组topStories
                [topStories addObject:topStory];
            }
            [self.CarouselView setTopStories:topStories];
        }

        //获取 tableView 的数据
        NSArray *storiesJSON = responseObject[@"stories"];
        NSMutableArray *stories = [[NSMutableArray alloc] init];
        //将数据遍历进一个字典里再调用模型，再将模型添加进数组里
        for (NSDictionary *JSON in storiesJSON) {
            GNStory *story = [[GNStory alloc] initWithJSON:JSON];
            [stories addObject:story];
        }
        
        [self.data addObject:[NSArray arrayWithArray:stories]];
        
        [self.TableView reloadData];
    
        self.isLoading = NO;
        self.days++;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"获取不到数据");
        //是否加载
        self.isLoading = NO;
        //创建的方法是挂起的，需要使用 resume 来执行
    }] resume];
}

#pragma mark - UITableViewDataSource

//头的高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    //如果组的数目为0，则 Header 的高度为0，否则，header 高度为44
    if (section == 0) {
        return 0;
    }
    return 44;
}

//头的内容视图
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    //如果组的数目为0则为空
    if (section == 0) {
        return nil;
    }
    
    //如果组的数目不为0，则创建一个 View
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, 44)];
    header.backgroundColor = [UIColor colorWithRed:0.0667 green:0.478 blue:0.804 alpha:1];
    
    //在 View 中添加一个标签
    UILabel *dataLabel = [[UILabel alloc] initWithFrame:header.bounds
    ];
    //标签内容为日期
    dataLabel.text = [GNDataUtils dateStringBeforeDays:section];
    //字体颜色
    dataLabel.textColor = [UIColor whiteColor];
    //文本对齐，居中对齐
    dataLabel.textAlignment = NSTextAlignmentCenter;
    [header addSubview:dataLabel];
    
    return header;
}

//组的个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.data.count;
}

//每组有多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *stories = self.data[section];
    return stories.count;
}

//每一行行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GNStoryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StoryCell" forIndexPath:indexPath];
    GNStory *story = self.data[indexPath.section][indexPath.row];
    cell.label.text = story.title;
    [cell.label sizeToFit];
    [cell.rightImageView sd_setImageWithURL:story.images[0]];
    
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetY = scrollView.contentOffset.y ;
    NSLog(@"偏移量为 = %f",contentOffsetY);
    
    //表视图往下滑的时候
    if (contentOffsetY > 0) {
        
        //如果偏移量大于一组数据的高度时，隐藏标签
        if (contentOffsetY >= 90 * [self.data[0] count] + 200) {
            self.TodayTitleLabel.hidden = YES;
            self.topView.hidden = YES;
            } else {
                self.TodayTitleLabel.hidden = NO;
                self.topView.hidden = NO;
            }
        
        CGFloat alpha = contentOffsetY / 64;
        //更改导航栏透明度
        self.topView.backgroundColor = [UIColor colorWithRed:0.0667 green:0.478 blue:0.804 alpha:alpha];
        
        //更改图片轮播器的 top 约束
        self.CarouseViewTop.constant = -contentOffsetY;
    }
    
    //表视图往上滑的时候
    if (contentOffsetY < 0) {
        //更改图片的高度
        self.CarouselViewHeight.constant = 220 - contentOffsetY;
        
        //如果下拉幅度大于某个值，则让他一直保持这个值
        if (contentOffsetY <= -kRefreshOffsetY * 1.5) {
            self.TableView.contentOffset = CGPointMake(0, -kRefreshOffsetY * 1.5);
        }
        
        //从0到下拉的阈值之间
        if (contentOffsetY <= 0 && contentOffsetY >= - kRefreshOffsetY * 1.5) {
            
           
            if (self.isRefreshing) {
                [self.RefreshView updateProgress:0];
            } else {
                    [self.RefreshView updateProgress:-contentOffsetY / kRefreshOffsetY];
                }
            }
    }
    
    //下拉松手
    if (contentOffsetY < -kRefreshOffsetY && !scrollView.isDragging) {
        //开始动画
        [self.RefreshView startAnimation];
        self.isRefreshing = YES;
                
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.RefreshView stopAnimation];
                    self.isRefreshing = NO;
            });
    }
    [self.view layoutIfNeeded];

    //滚动到底部时
    
    CGRect bounds = scrollView.bounds;
    //内容大小
    CGSize contenteSize = scrollView.contentSize;
    //内容插图
    UIEdgeInsets inset = scrollView.contentInset;
    
    float y = scrollView.contentOffset.y + bounds.size.height - inset.bottom;
    
    float h = contenteSize.height;
    
    float reload_distance = 10;
    
    if (y > h + reload_distance) {
        
        if (self.isLoading) {
        return;
            
        } else {
            
            [self fetchData];
            
        }
    }
}

//首选状态栏样式，用户界面状态栏风格的内容
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)hideSideMenu {
    [UIView animateWithDuration:kSideMenuAnimationDuration
                     animations:^{
                         self.sideMenuVC.view.left = -255;
                         self.homeView.left = 0;
                         self.HomeView.right = 320;

                     }
                     completion:^(BOOL finished) {
                         [self.tapView removeGestureRecognizer:self.tapToHideSideMenu];
                         [self.tapView removeFromSuperview];
                         self.isShowSideMenu = NO;
                     }];
}

- (IBAction)showSideMenu:(id)sender {
    [self.sideMenuVC.menuTableView reloadData];
    
    
    [UIView animateWithDuration:kSideMenuAnimationDuration
                     animations:^{
                         self.HomeView.left = 225;
                         self.homeView.right = 545;
                         [self.homeView setNeedsUpdateConstraints];
                         self.sideMenuVC.view.left = 0;
                         [self.view layoutIfNeeded];
                     }
                    //在 homeView 上覆盖一层透明的 View，点击隐藏
                     completion:^(BOOL finished) {
                         self.tapView = [[UIView alloc] initWithFrame:self.view.bounds];
                         self.tapView.backgroundColor = [UIColor clearColor];
                         [self.tapView addGestureRecognizer:self.tapToHideSideMenu];
                         [self.HomeView addSubview:self.tapView];
                         self.isShowSideMenu = YES;
                     }];
}


- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    CGFloat offsetX = [recognizer translationInView:self.homeView].x;
    if (offsetX > 0 && offsetX < kSideMenuWidth) {
        self.sideMenuVC.view.right = offsetX;
        self.homeViewLeft.constant = offsetX;
        self.homeViewRight.constant = -offsetX;
        [self.homeView layoutIfNeeded];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (offsetX >= kSideMenuWidth / 2) {
            [self showSideMenu:nil];
        } else {
            [self hideSideMenu];
        }
    }
}

@end
