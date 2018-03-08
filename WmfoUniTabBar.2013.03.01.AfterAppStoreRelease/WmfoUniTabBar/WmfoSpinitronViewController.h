//
//  WmfoSpinitronViewController.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/9/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoSpinitronViewController : UIViewController {
    WmfoAppDelegate * _appDelegate;
    WmfoSharedWebViewController * _wmfoSharedWebViewController;
	NSTimer * _timerSpinitron;
}

- (void) addChildViewControllers;
- (void) onViewWillAppearForChildViewControllers;

- (void)startTimer;
- (void)stopTimer;
@end
