//
//  WmfoAppDelegate.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 12/29/12.
//  Copyright (c) 2012 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@implementation WmfoAppDelegate

- (void) setLblMemoryUsage:(UILabel *)lblMemoryUsage {
    _lblMemoryUsage = lblMemoryUsage;
#if WMFOAPP_SHOW_MEMORY_USAGE
    _lblMemoryUsage.hidden = FALSE;
#else
    _lblMemoryUsage.hidden = TRUE;
#endif
}
- (UILabel *) lblMemoryUsage {
    return _lblMemoryUsage;
}
- (UIViewController *) activeViewController {
    if ([WmfoUtil isIPad]) {
        return _wmfoMainIPadViewController;
    } else {
        return _tabBarController.selectedViewController;
    }
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate application:didFinishLaunchingWithOptions:] (enter)"];
    [[UINavigationBar appearance] setTintColor:[UIColor purpleColor]];
    _standardUserDefaults = [NSUserDefaults standardUserDefaults];
	[self loadUserDefaults];
    [self initIPhoneTabBarController];
	[self startStream];
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate application:didFinishLaunchingWithOptions:] (exit)"];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate applicationWillResignActive:] (enter)"];
    [self stopTimers];
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate applicationWillResignActive:] (exit)"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate applicationDidEnterBackground:] (enter)"];
	[self saveUserDefaults];
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate applicationDidEnterBackground:] (exit)"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate applicationWillEnterForeground:] (exit)"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate applicationDidBecomeActive:] (enter)"];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self startTimers];
    UIViewController * activeViewController = self.activeViewController;
    if ([activeViewController respondsToSelector:@selector(onApplicationDidBecomeActive)]) {
        [activeViewController performSelector:@selector(onApplicationDidBecomeActive)];
    }
    if (_startPlayingOnApplicationDidBecomeActive) {
        [self startStream];
    }

    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate applicationDidBecomeActive:] (exit)"];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.    
    // Since we support background processing etc. this isn't reliably called when the user "exits" under iOS
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate applicationWillTerminate:] (exit)"];
}

// +initialize is invoked before the class receives any other messages, so it
// is a good place to set up application defaults
+ (void)initialize {
    if ([self class] == [WmfoAppDelegate class]) {
		[self initFirstTimeUserDefaultPrefs];
    }
}
+ (WmfoAppDelegate *) sharedInstance {
	// I believe this is the best way to access the AppDelegate globally as a singleton
    // because it should work at any point of initialization...
	id appDelegate = [[UIApplication sharedApplication] delegate];
	return (WmfoAppDelegate *) appDelegate;
}

#pragma mark -
#pragma mark Misc Methods

- (NSString *) getWebcastStringUrlFromCurrentSelectedSegCtlIndex {
    int selectedSegCtlIndex = self.webcastUrlStreamIndex;
	NSString * s;
	if ( selectedSegCtlIndex == 0 ) {
		s = kWebcastUrlStreamLow;
	} else if ( selectedSegCtlIndex == 1 ) {
		s = kWebcastUrlStreamMedium;
	} else if ( selectedSegCtlIndex == 2 ) {
		s = kWebcastUrlStreamHigh;
	} else if ( selectedSegCtlIndex == 3 ) {
		// Custom string default; maybe later retrieve from user pref?
		s = _webcastUrlStreamCustom;
	} else {
		s = @"[WmfoAppDelegate getWebcastStringUrlFromCurrentSelectedSegCtlIndex] Bad index";
		WmfoLogError(@"%@", s);
	}
	return s;
}
- (NSURL *) getWebcastUrlFromCurrentSelectedSegCtlIndex {
	NSString * s = [self getWebcastStringUrlFromCurrentSelectedSegCtlIndex];
	NSURL *url = [WmfoUtil getNSURLByAddingPercentEscapesToRawUrlString:s];
	return url;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqual:@"isPlaying"])
	{
		if ([(MattGallagherAudioStreamer *)object isPlaying]) {
			// Wait until the stream is actually playing (i.e. the audioQueue has been successfully created)
			// before setting the volume
			[_streamer setVolume: _volume];
			[_wmfoPlayButton onPlayingStartedNotification];
		} else {
			[_wmfoPlayButton onPlayingStoppedNotification];
			[self removeObserversForAudioStreamer];
			_streamer = nil;
		}
		return;
	} else if ([keyPath isEqual:@"isTerminated"]) {
		if ([(MattGallagherAudioStreamer *)object isTerminated]) {
			// This handles error termination
			[_wmfoPlayButton onPlayingStoppedNotification];
			NSLog(@"isTerminated received");
		}
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change
						  context:context];
}

#pragma mark -
#pragma mark Timers

- (void)startTimers {
    if ([WmfoUtil isIPad]) {
        [_wmfoMainIPadViewController startTimer];
    } else {
        [_wmfoMainIPhoneViewController startTimer];
        [_wmfoSpinitronViewController startTimer];
    }
#if WMFOAPP_SHOW_MEMORY_USAGE
	_timerMemoryUsage = [NSTimer scheduledTimerWithTimeInterval:kSpinitronCurrentSongRefreshIntervalInSeconds target:self selector:@selector(maybeUpdateLblMemoryConsumed) userInfo:nil repeats:YES];
#endif
}
- (void)stopTimers {
    if ([WmfoUtil isIPad]) {
        [_wmfoMainIPadViewController stopTimer];
    } else {
        [_wmfoMainIPhoneViewController stopTimer];
        [_wmfoSpinitronViewController stopTimer];
    }    
#if WMFOAPP_SHOW_MEMORY_USAGE
    [_timerMemoryUsage invalidate];
    _timerMemoryUsage = nil;
#endif
}
- (void)maybeUpdateLblMemoryConsumed {
    if (_lblMemoryUsage && !_lblMemoryUsage.hidden) {
        _lblMemoryUsage.text = [WmfoUtil getMemoryUsageAsNSString];
    }
}



#pragma mark -
#pragma mark User Defaults and Preferences

+ (void)initFirstTimeUserDefaultPrefs {
	// Register default values for the settings we remember...
	NSNumber *defaultVolume = [NSNumber numberWithFloat:kDefaultVolume];
	NSNumber *defaultWebcastUrlStreamIndex = [NSNumber numberWithInt:kDefaultWebcastUrlStreamIndex];
	NSDictionary *resourceDict =
	[NSDictionary dictionaryWithObjectsAndKeys:
     defaultVolume, kUserDefaultKey_Volume,
     defaultWebcastUrlStreamIndex, kUserDefaultKey_WebcastUrlStreamIndex,
     kWebcastUrlStreamDefaultCustom, kUserDefaultKey_WebcastUrlStreamCustom,
     nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:resourceDict];
}
- (void)loadUserDefaults {
	_volume = [_standardUserDefaults floatForKey:kUserDefaultKey_Volume];
	_webcastUrlStreamIndex = [_standardUserDefaults integerForKey:kUserDefaultKey_WebcastUrlStreamIndex];
	_webcastUrlStreamCustom = [_standardUserDefaults stringForKey:kUserDefaultKey_WebcastUrlStreamCustom];
}
- (void)saveUserDefaults {
    // Store user's preferred settings, so they can be used the next time the app is launched
    [_standardUserDefaults setFloat:_volume forKey:kUserDefaultKey_Volume];
    [_standardUserDefaults setInteger:_webcastUrlStreamIndex forKey:kUserDefaultKey_WebcastUrlStreamIndex];
    [_standardUserDefaults setObject:_webcastUrlStreamCustom forKey:kUserDefaultKey_WebcastUrlStreamCustom];
	[_standardUserDefaults synchronize];
}

- (void) telephoneWmfo {
// There's an apparently timing-related bug that causes a crash when we place a call
// from the app and then try to restart the stream when the call is finished in our
// AudioSessionInterruptionListener() -- Accepting an incoming phone call is fine!
// Our workaround hack is to stop the stream here and then restart it when the app is activated...
    [self stopStream]; 
    _startPlayingOnApplicationDidBecomeActive = TRUE;
	BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kWmfoTelephoneURL]];
    if (success) {
        WmfoUtilQuietLog(@"[WmfoAppDelegate telephoneWmfo] success\n");
    } else {
        WmfoUtilQuietLog(@"[WmfoAppDelegate telephoneWmfo] failed\n");        
    }
}

- (void) setInitialTabBarItemTags {
    NSInteger tag = 0;
    for (UIViewController *viewController in _tabBarController.viewControllers) {
        viewController.tabBarItem.tag = tag++;
    }
}
- (void)restoreTabBarOrder {    
    NSArray *initialViewControllers = [NSArray arrayWithArray:_tabBarController.viewControllers];
    NSArray *tabBarOrder = [_standardUserDefaults arrayForKey:kUserDefaultKey_TabBarOrder];
    if (tabBarOrder) {
        NSMutableArray *newViewControllers = [NSMutableArray arrayWithCapacity:initialViewControllers.count];
        for (NSNumber *tabBarNumber in tabBarOrder) {
            NSUInteger tabBarIndex = [tabBarNumber unsignedIntegerValue];
            [newViewControllers addObject:[initialViewControllers objectAtIndex:tabBarIndex]];
        }
        _tabBarController.viewControllers = newViewControllers;
    }
}
- (void)initIPhoneTabBarController {    
    if ([WmfoUtil isIPad]) {
        _tabBarController = nil;
    } else {
        UIViewController * rootViewController = self.window.rootViewController;
        _tabBarController = (UITabBarController *) rootViewController;
        _tabBarController.delegate = self;
        [self setInitialTabBarItemTags];
        [self restoreTabBarOrder];
        // And don't permit the user to remove the main play view from the first tab position
        NSMutableArray * controllers = [NSMutableArray arrayWithArray:_tabBarController.customizableViewControllers];
        [controllers removeObjectAtIndex:0];
        _tabBarController.customizableViewControllers = controllers;
    }    
}
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [WmfoUtil reportMemoryUsageWithComment:@"WmfoAppDelegate:tabBarController:didSelectViewController"];
}
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
    
    NSUInteger count = tabBarController.viewControllers.count;
    NSMutableArray *tabOrderArray = [[NSMutableArray alloc] initWithCapacity:count];
    for (UIViewController *viewController in viewControllers) {
        
        NSInteger tag = viewController.tabBarItem.tag;
        [tabOrderArray addObject:[NSNumber numberWithInteger:tag]];
    }
    [_standardUserDefaults setObject:[NSArray arrayWithArray:tabOrderArray] forKey:kUserDefaultKey_TabBarOrder];
	[_standardUserDefaults synchronize];
}
-(float) volume {
	return _volume;
}
-(void) setVolume: (float) volume {
	_volume = volume;
	[_streamer setVolume: _volume];
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate setVolume]"];
}
#pragma mark -
#pragma mark Audio Streamer

- (void)startOrStopStream {
	if (!_streamer) {
		[self startStream];
	} else {
		[self stopStream];
	}
}
- (void)startStream {
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate startStream] (enter)"];
    _startPlayingOnApplicationDidBecomeActive = FALSE;
	if (![WmfoUtil checkNetworkDisplayingAlertIfNotConnected]) {
		return;
	}
	[self startStreamWorker];
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate startStream] (exit)"];
}

- (void)startStreamWorker {
    NSURL * url = [self getWebcastUrlFromCurrentSelectedSegCtlIndex];
	[_wmfoPlayButton setButtonVisualLoading];
	_streamer = [[MattGallagherAudioStreamer alloc]initWithURL:url];
	[self addObserversForAudioStreamer];
	[_streamer start];
}
- (void)stopStream {
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate stopStream] (enter)"];
	[_streamer stop];
    [WmfoUtil reportMemoryUsageWithComment:@"[WmfoAppDelegate stopStream] (exit)"];
}

-(void)addObserversForAudioStreamer {
	[_streamer addObserver:self forKeyPath:@"isPlaying" options:0 context:nil];
	[_streamer addObserver:self forKeyPath:@"isTerminated" options:0 context:nil];
}

-(void)removeObserversForAudioStreamer {
	[_streamer removeObserver:self forKeyPath:@"isPlaying"];
	[_streamer removeObserver:self forKeyPath:@"isTerminated"];
}
@end
