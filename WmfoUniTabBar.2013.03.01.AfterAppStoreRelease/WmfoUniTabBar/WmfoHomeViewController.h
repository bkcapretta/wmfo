//
//  WmfoHomeViewController.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/8/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoHomeViewController : UIViewController {
    WmfoSharedWebViewController * _wmfoSharedWebViewController;
}

- (void) addChildViewControllers;
- (void) onViewWillAppearForChildViewControllers;

@end
