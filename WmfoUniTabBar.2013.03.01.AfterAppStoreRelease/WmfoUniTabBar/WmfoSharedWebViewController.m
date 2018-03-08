//
//  WmfoSharedWebViewController.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/8/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@implementation WmfoSharedWebViewController

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	_appDelegate = [WmfoAppDelegate sharedInstance];
	self.lblErrorMsg.hidden = TRUE;
	[self maybeRemoveTelephoneWmfoBtn];
	[self setupWebView];
//    self.webView.hidden = TRUE;
//    [self loadRequestString:kSpinitronFullCurrentPlaylistUrl];
    
}
- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self fixupGeometriesToMatchSuperview];
	[self loadWebViewDependingOnViewType];
}
- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
- (void)onApplicationDidBecomeActive {
    if (![self checkNetworkThenMaybeShowErrorMsgOnLabel]) {
        return;
    }
    [self loadWebViewDependingOnViewType];
}
- (BOOL)checkNetworkIfRequiredThenMaybeShowErrorMsgOnLabel {
    if ([self isViewTypeAbout] ) {
        // The About web page is local and doesn't need a network connection to display
        return TRUE;
    }
    return [self checkNetworkThenMaybeShowErrorMsgOnLabel];
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
- (void) loadWebViewDependingOnViewType {
    if (![self checkNetworkIfRequiredThenMaybeShowErrorMsgOnLabel] ) {
        return;
    }
	
	[self.progressInd startAnimating];
    _isFullPlaylistLastUserWebView = FALSE; // override below as appropriate
    
	if ( [self isViewTypeAbout] ) {
		[WmfoUtil loadLocalFile:@"WmfoAppAboutViewWebPageIPhone" ofType:@"html" forWebView:self.webView];
	} else if ( [self isViewTypePlaylist] ) {
        _isFullPlaylistLastUserWebView = TRUE;
#if SIMULATE_SPINITRON_LOAD_ERROR
        NSString * urlString = nil;
        static BOOL alternateErrorUrl = FALSE;
        if (alternateErrorUrl) {
            urlString = kSpinitronFullCurrentPlaylistErrorUrl;
        } else {
            urlString = kSpinitronFullCurrentPlaylistUrl;
        }
        alternateErrorUrl = !alternateErrorUrl;
		[WmfoUtil loadRequestString:urlString forWebView:self.webView];
#elif 0
        // File saved in web browser looks horrible!
		[WmfoUtil loadLocalFile:@"WmfoAppMainIPhoneViewSampleFullCurrentPlaylist" ofType:@"html" forWebView:self.webView];
#elif 0
        // One of Evan's shows with lots of album images
		[WmfoUtil loadRequestString:@"http://spinitron.com/public/index.php?station=wmfo&ptype=d&playlist=37248&styles=body,a%7Bbackground:black;color:white;font-family:Helvetica;text-decoration:none%7D" forWebView:self.webView];
#else
		[WmfoUtil loadRequestString:kSpinitronFullCurrentPlaylistUrl forWebView:self.webView];
#endif
	} else if ( [self isViewTypeWMFO] ) {
		self.webView.scalesPageToFit = YES;
		[WmfoUtil loadRequestString:kWmfoWebsiteUrl forWebView:self.webView];
	} else if ( [self isViewTypeVideos] ) {
		[WmfoUtil loadRequestString:kVideosWebsiteUrl forWebView:self.webView];
	} else if ( [self isViewTypeTwitter] ) {
		[WmfoUtil loadRequestString:kTwitterWebsiteUrl forWebView:self.webView];
	} else {
        WmfoLogError(@"[WmfoSharedWebViewController loadWebViewDependingOnViewType] unknown view type.\n");
	}
}
- (NSString *) strViewType {
    return self.parentViewController.tabBarItem.title;
}
- (BOOL) isViewTypeAbout {
	return [self.strViewType isEqualToString: @"About"];
}
- (BOOL) isViewTypeVideos {
	return [self.strViewType isEqualToString: @"Videos"];
}
- (BOOL) isViewTypePlaylist {
	return [self.strViewType isEqualToString: @"Playlist"];
}
- (BOOL) isViewTypePlaylistAndWebViewCantGoBack {
	return self.isViewTypePlaylist && !self.webView.canGoBack;
}
- (BOOL) isViewTypeWMFO {
	return  [self.strViewType isEqualToString: @"WMFO"];
}
- (BOOL) isViewTypeTwitter {
	return [self.strViewType isEqualToString: @"Twitter"];
}
- (void) setWebViewBtnsEnabledState {
	self.btnBack.enabled = self.webView.canGoBack;
	self.btnForward.enabled = self.webView.canGoForward;
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
- (void) fixupGeometriesToMatchSuperview {
    WmfoUtilQuietLog(@"[WmfoSharedWebViewController fixupGeometriesToMatchSuperview] self.view.superview.frame.size.height=%f self.view.frame.size.height=%f\n", self.view.superview.frame.size.height, self.view.frame.size.height);
    CGRect superviewFrame = self.view.superview.frame;
    self.view.frame = superviewFrame;
    self.progressInd.center = self.view.center;
}
- (void) maybeRemoveTelephoneWmfoBtn {
	if (![WmfoUtil canTelephoneWmfo]) {
		NSMutableArray *items = [self.toolbar.items mutableCopy];
		[items removeObject: self.btnTelephoneWmfo];
		self.toolbar.items = items;
	}
}
- (void) webViewDidStartLoad:(UIWebView *)theWebView {
//	self.progressInd.hidden = FALSE;
	[self.progressInd startAnimating];
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType != UIWebViewNavigationTypeOther) {
        // We receive a UIWebViewNavigationTypeOther notification on initial load, assume all others are user actions
        _isFullPlaylistLastUserWebView = FALSE;
    }
    _request = request;
    return YES;
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    WmfoUtilQuietLog(@"[WmfoSharedWebViewController webView:didFailLoadWithError:] %@\n", error);
	[self.progressInd stopAnimating];
    if (![WmfoError isIgnoreableNSError:error]) {
        if (_isFullPlaylistLastUserWebView) {
            self.lblErrorMsg.text = kSpinitronCurrentSongWebViewFailLoadErrorMsg;
            [self showLblErrorMsgHideWebView];
        } else {
            [WmfoUtil handleWebViewFailLoadError:error withRequest:_request];
        }
    }
    _request = nil;
}
- (void) webViewDidFinishLoad:(UIWebView *)theWebView {
	[self.progressInd stopAnimating];
    [self showWebViewHideLblErrorMsg];
	[self setWebViewBtnsEnabledState];
    _request = nil;
}
- (void) maybeReloadFullPlaylist {
    if (![WmfoUtil checkNetworkNoUI]) {
        return;
    }
    if (_isFullPlaylistLastUserWebView || self.isViewTypePlaylistAndWebViewCantGoBack) {
        [self loadWebViewDependingOnViewType];
    }
}

- (IBAction) actionBtnBackPressed:(UIBarButtonItem *)sender {
	[self.webView goBack];
}
- (IBAction) actionBtnForwardPressed:(UIBarButtonItem *)sender {
	[self.webView goForward];
}
- (IBAction) actionBtnTelephoneWmfoPressed:(UIBarButtonItem *)sender {
    [_appDelegate telephoneWmfo];
}
@end
