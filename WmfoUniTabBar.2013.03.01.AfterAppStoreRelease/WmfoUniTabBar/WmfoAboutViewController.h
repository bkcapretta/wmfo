//
//  WmfoAboutViewController.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/10/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoAboutViewController : UIViewController {
    WmfoSharedWebViewController * _wmfoSharedWebViewController;
}

- (void) addChildViewControllers;
- (void) onViewWillAppearForChildViewControllers;

@end
