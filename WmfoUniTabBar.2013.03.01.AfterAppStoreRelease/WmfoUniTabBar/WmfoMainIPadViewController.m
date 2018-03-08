//
//  WmfoMainIPadViewController.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/12/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@implementation WmfoMainIPadViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	_appDelegate = [WmfoAppDelegate sharedInstance];
    _appDelegate.wmfoMainIPadViewController = self;
	_appDelegate.wmfoPlayButton = self.wmfoPlayButton;
	[self.sliderVolume setValue: _appDelegate.volume];
    [self setupWebView];
    [self.wmfoPlayButton setButtonVisualStoppedAndReadyToPlay];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
}
- (void)viewDidUnload {
    [self setProgressInd:nil];
    [self setWmfoPlayButton:nil];
    [self setSliderVolume:nil];
    [self setBtnForward:nil];
    [self setBtnBack:nil];
    [self setLblErrorMsg:nil];
    [super viewDidUnload];
}
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadWebViewWithFullCurrentPlaylistUrl];
}
- (void)onApplicationDidBecomeActive {
    if (![self checkNetworkThenMaybeShowErrorMsgOnLabel]) {
        return;
    };
    [self reloadWebView];
}
- (BOOL)checkNetworkThenMaybeShowErrorMsgOnLabel {
    if ([WmfoUtil checkNetworkNoUI]) {
        [self showWebViewHideLblErrorMsg];
        return TRUE;
    } else {
        [self showLblErrorMsgHideWebView];
        [WmfoUtil showNetworkNotAvailableErrorMsgOnLabel:self.lblErrorMsg];
    }
    return FALSE;
}
//- (void)checkNetworkThenLoadSpinitronWebViewOrShowErrorMsgOnLabel {
//    if ([WmfoUtil checkNetworkNoUI]) {
//        self.lblErrorMsg.hidden = TRUE;
//        [self loadWebViewWithFullCurrentPlaylistUrl];
//    } else {
//        self.webView.hidden = TRUE;
//        [WmfoUtil showNetworkNotAvailableErrorMsgOnLabel:self.lblErrorMsg];
//    }
//}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // iOS 5.x and lower...
    [self dismissActivePopoverController];
    return YES;
}
- (BOOL)shouldAutorotate {
    // iOS 6 and higher...
    [self dismissActivePopoverController];
    return YES;
}
- (void) dismissActivePopoverController {
    if (self.activePopoverController) {
        [self.activePopoverController dismissPopoverAnimated:NO];
        self.activePopoverController = nil;
    }    
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self dismissActivePopoverController];
    
    // retain the popover
    if ([segue.identifier isEqualToString:@"WmfoSettingsPopover"])
    {
        UIStoryboardPopoverSegue *popoverSegue = (UIStoryboardPopoverSegue *)segue;
        UIPopoverController *thePopoverController = [popoverSegue popoverController];
//        thePopoverController.contentViewController.contentSizeForViewInPopover = CGSizeMake(320.0f, 150.0f);
        [thePopoverController setDelegate:self];
        self.activePopoverController = thePopoverController;
    }
}
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)thePopoverController {
    self.activePopoverController = nil;
}
- (void) showWebViewHideLblErrorMsg {
    self.webView.hidden = FALSE;
    self.lblErrorMsg.hidden = TRUE;
}
- (void) showLblErrorMsgHideWebView {
    self.lblErrorMsg.hidden = FALSE;
    self.webView.hidden = TRUE;
}
- (void) setupWebView {
	self.webView.delegate = self;
	self.progressInd.hidesWhenStopped = TRUE;
	[self setWebViewBtnsEnabledState];
}
- (void) setWebViewBtnsEnabledState {
	self.btnBack.enabled = self.webView.canGoBack;
	self.btnForward.enabled = self.webView.canGoForward;
}
- (void)loadWebViewForType:(WmfoViewType)type {
    
    _lastWebViewType = type;
    _isFullPlaylistLastUserWebView = FALSE; // override below

    if (type == WmfoViewTypeAbout) {
        [WmfoUtil loadLocalFile:@"WmfoAppAboutViewWebPageIPad" ofType:@"html" forWebView:self.webView];
        return;
    }
    if (![self checkNetworkThenMaybeShowErrorMsgOnLabel]) {
        return;
    }
    NSString * urlString = nil;
    switch (type) {
        case WmfoViewTypeFullPlaylist:
            _isFullPlaylistLastUserWebView = TRUE;
#if SIMULATE_SPINITRON_LOAD_ERROR
            static BOOL alternateErrorUrl = FALSE;
            if (alternateErrorUrl) {
                urlString = kSpinitronFullCurrentPlaylistErrorUrl;
            } else {
                urlString = kSpinitronFullCurrentPlaylistUrl;
            }
            alternateErrorUrl = !alternateErrorUrl;
#elif 0
            // One of Evan's shows with lots of album images
            urlString = @"http://spinitron.com/public/index.php?station=wmfo&ptype=d&playlist=37248&styles=body,a%7Bbackground:black;color:white;font-family:Helvetica;text-decoration:none%7D";
#else
            urlString = kSpinitronFullCurrentPlaylistUrl;
#endif
            break;
        case WmfoViewTypeVideos:
            urlString = kVideosWebsiteUrl;
            break;
        case WmfoViewTypeWmfoWebsite:
            urlString = kWmfoWebsiteUrl;
            break;
        case WmfoViewTypeTwitter:
            urlString = kTwitterWebsiteUrl;
            break;
        default:
            WmfoLogError(@"[WmfoMainIPadViewController loadWebViewForType] invalid WmfoViewType");
            return;
            break;
    }
    [WmfoUtil loadRequestString:urlString forWebView:self.webView];
}
- (void)reloadWebView {
    [self loadWebViewForType:_lastWebViewType];
}
- (void)loadWebViewWithFullCurrentPlaylistUrl {
    [self loadWebViewForType:WmfoViewTypeFullPlaylist];
}
- (void)webViewDidStartLoad:(UIWebView *)theWebView {
	[self.progressInd startAnimating];
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType != UIWebViewNavigationTypeOther) {
        // We receive a UIWebViewNavigationTypeOther notification on initial load, assume all others are user actions
        _isFullPlaylistLastUserWebView = FALSE;        
    }
    return YES;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    WmfoUtilQuietLog(@"[WmfoMainIPadViewController webView:didFailLoadWithError:] %@\n", error);
	[self.progressInd stopAnimating];
    if ([WmfoError isIgnoreableNSError:error]) {
        return;
    }
    if (_isFullPlaylistLastUserWebView) {
        self.lblErrorMsg.text = kSpinitronCurrentSongWebViewFailLoadErrorMsg;
        [self showLblErrorMsgHideWebView];
        return;
    }
    [WmfoUtil handleWebViewFailLoadError:error];
}
- (void) webViewDidFinishLoad:(UIWebView *)theWebView {
	[self.progressInd stopAnimating];
    [self showWebViewHideLblErrorMsg];
	[self setWebViewBtnsEnabledState];
}
- (void)maybeUpdateSpinitronWebView {
    if (_isFullPlaylistLastUserWebView) {
        [self loadWebViewWithFullCurrentPlaylistUrl];
    }
}
- (void)startTimer {
	_timerSpinitron = [NSTimer scheduledTimerWithTimeInterval:kSpinitronCurrentFullPlaylistRefreshIntervalInSeconds target:self selector:@selector(maybeUpdateSpinitronWebView) userInfo:nil repeats:YES];
}
- (void)stopTimer {
    [_timerSpinitron invalidate];
    _timerSpinitron = nil;
}

- (IBAction)actionWmfoPlayButtonTouchUpInside:(WmfoPlayButton *)sender {
    [_appDelegate startOrStopStream];
}
- (IBAction)actionVolumeSliderValueChanged:(UISlider *)sender {
	_appDelegate.volume = [sender value];
}
- (IBAction)actionBtnBackPressed:(UIButton *)sender {
	[self.webView goBack];
}
- (IBAction)actionBtnForwardPressed:(UIButton *)sender {
	[self.webView goForward];
}
- (IBAction)actionPlaylist:(id)sender {
    [self loadWebViewWithFullCurrentPlaylistUrl];
}
- (IBAction)actionVideos:(id)sender {
    [self loadWebViewForType:WmfoViewTypeVideos];
}
- (IBAction)actionSettings:(UIButton *)sender {
    // NO-OP here because we're now using a segue to invoke popover
}
- (IBAction)actionWmfoWebsite:(id)sender {
    [self loadWebViewForType:WmfoViewTypeWmfoWebsite];
}
- (IBAction)actionTwitter:(id)sender {
    [self loadWebViewForType:WmfoViewTypeTwitter];
}
- (IBAction)actionAbout:(id)sender {
    [self loadWebViewForType:WmfoViewTypeAbout];
}
@end
