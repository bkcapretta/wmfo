//
//  WmfoVideosViewController.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/10/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@implementation WmfoVideosViewController

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
    
}

@end
