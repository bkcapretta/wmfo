//
//  WmfoTwitterViewController.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/9/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoTwitterViewController : UIViewController {
    WmfoSharedWebViewController * _wmfoSharedWebViewController;
}

- (void) addChildViewControllers;
- (void) onViewWillAppearForChildViewControllers;

@end
