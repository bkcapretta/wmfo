//
//  WmfoAppDelegate.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 12/29/12.
//  Copyright (c) 2012 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate> {
    NSUserDefaults * _standardUserDefaults;
    WmfoMainIPadViewController * _wmfoMainIPadViewController;
    WmfoMainIPhoneViewController * _wmfoMainIPhoneViewController;
    WmfoSpinitronViewController * _wmfoSpinitronViewController;
    UITabBarController * _tabBarController; // iPhone only
    WmfoPlayButton * _wmfoPlayButton;
    UILabel *_lblMemoryUsage;
    NSTimer *_timerMemoryUsage;
    MattGallagherAudioStreamer *_streamer;
	float _volume;
	int _webcastUrlStreamIndex;
	NSString * _webcastUrlStreamCustom;
    BOOL _startPlayingOnApplicationDidBecomeActive;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) WmfoMainIPadViewController *wmfoMainIPadViewController;
@property (strong, nonatomic) WmfoMainIPhoneViewController * wmfoMainIPhoneViewController;
@property (strong, nonatomic) WmfoSpinitronViewController * wmfoSpinitronViewController;
@property (strong, nonatomic) UITabBarController *tabBarController;
@property (strong, nonatomic) WmfoPlayButton *wmfoPlayButton;
@property (strong, nonatomic) UILabel *lblMemoryUsage;
@property (nonatomic, retain) MattGallagherAudioStreamer *streamer;
@property float volume;
@property (readonly) UIViewController * activeViewController;
@property int webcastUrlStreamIndex;
@property (nonatomic, retain) NSString * webcastUrlStreamCustom;
@property BOOL startPlayingOnApplicationDidBecomeActive;


+ (WmfoAppDelegate *) sharedInstance;

- (NSString *) getWebcastStringUrlFromCurrentSelectedSegCtlIndex;

- (void)startTimers;
- (void)stopTimers;

+ (void)initFirstTimeUserDefaultPrefs;
- (void)loadUserDefaults;
- (void)saveUserDefaults;

- (void) telephoneWmfo;

- (void)initIPhoneTabBarController;


- (void)startOrStopStream;
- (void)startStream;
- (void)startStreamWorker;
- (void)stopStream;
- (void)addObserversForAudioStreamer;
- (void)removeObserversForAudioStreamer;

@end
