//
//  WmfoPlayButton.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/16/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoPlayButton : UIButton {
    WmfoAppDelegate * _appDelegate;
}

@property (readonly) BOOL isBigButton;

- (void)spinButton;

- (void)setButtonImage:(UIImage *)image;
//- (void)setButtonVisualBasedOnStreamer;
- (void)setButtonVisualLoading;
- (void)setButtonVisualStoppedAndReadyToPlay;
- (void)setButtonVisualPlayingAndReadyToStop;

- (void)onPlayingStartedNotification;
- (void)onPlayingStoppedNotification;

@end
