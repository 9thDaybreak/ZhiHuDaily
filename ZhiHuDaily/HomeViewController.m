//
//  HomeViewController.m
//  
//
//  Created by 肖杰华 on 16/8/17.
//
//

#import "HomeViewController.h"
#import "GNCarouselView.h"
#import "GNTopStory.h"
#import "GNStoryCell.h"
#import "GNDataUtils.h"
#import <ViewUtils.h>
#import "GNSideMenuViewController.h"
#import <AFNetworking.h>

@interface HomeViewController () <UITableViewDelegate,UITableViewDataSource,UIScrollViewDelegate>

@property (nonatomic, assign) NSInteger days;
@property (nonatomic, strong) NSMutableArray *data;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *homeView;
//给控件添加点击事件
@property (nonatomic, strong) UITapGestureRecognizer *tapToHideSideMenu;
//拖动手势
@property (nonatomic, strong) UIPanGestureRecognizer *pan;
@property (nonatomic, strong) GNSideMenuViewController *sideMenuVC;
@property (nonatomic, assign) BOOL isShowSideMenu;
@property (nonatomic, assign) BOOL isLoading;


@end

@implementation HomeViewController

static CGFloat const kSideMenuWidth = 225.f;
static CGFloat const kRefreshOffsetY = 40.f;
static CGFloat const kSideMenuAnimationDuration = 0.2f;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.days = -1;
    self.data = [[NSMutableArray alloc] init];
    
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
    self.sideMenuVC.view.width = 255;
    //设置标识符，是否显示侧边栏
    self.isShowSideMenu = NO;
    
    //设置 story tableView
    [self.tableView registerNib:[UINib nibWithNibName:@"GNStoryCell" bundle:nil] forCellReuseIdentifier:@"StoryCell"];
    self.tapToHideSideMenu = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSideMenu)];
    //在 homeView 中添加手势识别
    [self.homeView addGestureRecognizer:self.pan];
    
    //获取最新的日常事件
    [self fetchData];
}

- (void)hideSideMenu {
    [UIView animateWithDuration:kSideMenuAnimationDuration animations:^{
        //x
        self.homeView.left = 0;
        
    }];
}

- (void)fetchData {
    self.isLoading = YES;
    
    NSString *url = nil;
    if (self.days == -1) {
        url = @"http://news-at.zhihu.com/api/4/news/latest";
    } else {
        url = [@"http://news.at.zhihu.com/api/4/news/before/" stringByAppendingString:[GNDataUtils dateStringBeforeDays:self.days]];
    }
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:config];
    
    
}
@end
