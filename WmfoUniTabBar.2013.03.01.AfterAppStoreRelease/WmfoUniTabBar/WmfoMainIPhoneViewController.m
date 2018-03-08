//
//  WmfoMainViewController.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 12/29/12.
//  Copyright (c) 2012 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@implementation WmfoMainIPhoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	_appDelegate = [WmfoAppDelegate sharedInstance];
    _appDelegate.wmfoMainIPhoneViewController = self;
	_appDelegate.wmfoPlayButton = self.wmfoPlayButton;
//    self.lblErrorMsg.text = nil;
	[self.sliderVolume setValue: _appDelegate.volume];
	[self setupSpinitronWebView];
    [self.wmfoPlayButton setButtonVisualStoppedAndReadyToPlay];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setWmfoPlayButton:nil];
    [self setWebView:nil];
    [self setSliderVolume:nil];
    [self setLblErrorMsg:nil];
    [super viewDidUnload];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkNetworkThenLoadSpinitronWebViewOrShowErrorMsgOnLabel];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
- (void)onApplicationDidBecomeActive {
    [self checkNetworkThenLoadSpinitronWebViewOrShowErrorMsgOnLabel];
}
- (void)checkNetworkThenLoadSpinitronWebViewOrShowErrorMsgOnLabel {
    if ([WmfoUtil checkNetworkNoUI]) {
        [self showWebViewHideLblErrorMsg];
        [self loadSpinitronWebView];
    } else {
        [self showLblErrorMsgHideWebView];
        [WmfoUtil showNetworkNotAvailableErrorMsgOnLabel:self.lblErrorMsg];
    }    
}
- (void)showWebViewHideLblErrorMsg {
    self.webView.hidden = FALSE;
    self.lblErrorMsg.hidden = TRUE;
}
- (void)showLblErrorMsgHideWebView {
    self.lblErrorMsg.hidden = FALSE;
    self.webView.hidden = TRUE;
}
- (void)setupSpinitronWebView {
    self.webView.delegate = self;
//    self.webView.hidden = TRUE;
}
- (void)loadSpinitronWebView {
#if SIMULATE_SPINITRON_LOAD_ERROR
    NSString * urlString = nil;
    static BOOL alternateErrorUrl = FALSE;
    if (alternateErrorUrl) {
        urlString = kSpinitronCurrentPlaylistErrorUrl;
    } else {
        urlString = kSpinitronCurrentPlaylistUrl;
    }
    alternateErrorUrl = !alternateErrorUrl;
    [WmfoUtil loadRequestString:urlString forWebView:self.webView];
#elif 0
	// Dummied up playlist for making example screenshots
    [WmfoUtil loadLocalFile:@"WmfoAppMainIPhoneViewSamplePlaylist" ofType:@"html" forWebView:self.webView];
#else
    [WmfoUtil loadRequestString:kSpinitronCurrentPlaylistUrl forWebView:self.webView];
#endif
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    WmfoUtilQuietLog(@"[WmfoMainIPhoneViewController webView:didFailLoadWithError:] %@\n", error);
    if ([WmfoError isIgnoreableNSError:error]) {
        return;
    }
    self.lblErrorMsg.text = kSpinitronCurrentSongWebViewFailLoadErrorMsg;
    [self showLblErrorMsgHideWebView];
    WmfoUtilQuietLog(@"[WmfoMainIPhoneViewController webView:didFailLoadWithError:] %@\n", error);
}
- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    [self showWebViewHideLblErrorMsg];
    WmfoUtilQuietLog(@"[WmfoMainIPhoneViewController webViewDidFinishLoad:]\n");
}

- (void)maybeUpdateSpinitronWebView {
    UIViewController * selectedViewController = _appDelegate.tabBarController.selectedViewController;
    if (selectedViewController == self && [WmfoUtil checkNetworkNoUI]) {
        [self loadSpinitronWebView];
    }
}
- (void)startTimer {
	_timerSpinitron = [NSTimer scheduledTimerWithTimeInterval:kSpinitronCurrentSongRefreshIntervalInSeconds target:self selector:@selector(maybeUpdateSpinitronWebView) userInfo:nil repeats:YES];
}
- (void)stopTimer {
    [_timerSpinitron invalidate];
    _timerSpinitron = nil;
}

- (IBAction)actionWmfoPlayButtonTouchUpInside:(WmfoPlayButton *)sender {
    [_appDelegate startOrStopStream];
    [self checkNetworkThenLoadSpinitronWebViewOrShowErrorMsgOnLabel];
}
- (IBAction)actionVolumeSliderValueChanged:(UISlider *)sender {
	_appDelegate.volume = [sender value];
}

@end
