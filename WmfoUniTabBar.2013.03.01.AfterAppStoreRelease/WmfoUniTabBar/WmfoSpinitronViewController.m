//
//  WmfoSpinitronViewController.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/9/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@implementation WmfoSpinitronViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (id) initWithCoder:(NSCoder *)aDecoder {
    // Called when using storyboards
	self = [super initWithCoder:aDecoder];
	if (self) {
        [self addChildViewControllers];
        _appDelegate = [WmfoAppDelegate sharedInstance];
        _appDelegate.wmfoSpinitronViewController = self;
    }
	return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self onViewWillAppearForChildViewControllers];
}
- (void)onApplicationDidBecomeActive {
    [_wmfoSharedWebViewController onApplicationDidBecomeActive];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) addChildViewControllers {
    _wmfoSharedWebViewController = [[WmfoSharedWebViewController alloc] initWithNibName:@"WmfoSharedWebViewController" bundle:nil];
    [self addChildViewController:_wmfoSharedWebViewController];
}
- (void) onViewWillAppearForChildViewControllers {
    // Accessing the view here for the first time implicitly creates it...
    [self.view addSubview:_wmfoSharedWebViewController.view];
//    WmfoUtilQuietLog(@"[WmfoSpinitronViewController onViewWillAppearForChildViewControllers] self.view.frame.size.height=%f _wmfoSharedWebViewController.view.frame.size.height=%f\n", self.view.frame.size.height, _wmfoSharedWebViewController.view.frame.size.height);
//    CGRect frame = self.view.frame;
//    CGSize size = self.view.frame.size;
//    CGRect frame2 = _wmfoSharedWebViewController.view.frame;
//    _wmfoSharedWebViewController.view.frame = frame;
//    
}

- (void)maybeUpdateSpinitronWebView {
    UIViewController * selectedViewController = _appDelegate.tabBarController.selectedViewController;
//    if ([selectedViewController isMemberOfClass:[WmfoSpinitronViewController class]]) {
    if (selectedViewController == self) {
        [_wmfoSharedWebViewController maybeReloadFullPlaylist];
    }
}
- (void)startTimer {
	_timerSpinitron = [NSTimer scheduledTimerWithTimeInterval:kSpinitronCurrentFullPlaylistRefreshIntervalInSeconds target:self selector:@selector(maybeUpdateSpinitronWebView) userInfo:nil repeats:YES];
}
- (void)stopTimer {
    [_timerSpinitron invalidate];
    _timerSpinitron = nil;
}



@end
