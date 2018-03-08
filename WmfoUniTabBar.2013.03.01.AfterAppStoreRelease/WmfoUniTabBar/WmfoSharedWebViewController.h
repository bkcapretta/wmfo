//
//  WmfoSharedWebViewController.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/8/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoSharedWebViewController : UIViewController <UIWebViewDelegate> {
    WmfoAppDelegate * _appDelegate;
    BOOL _isFullPlaylistLastUserWebView;
    NSURLRequest * _request;
}

@property (readonly, nonatomic, retain) NSString * strViewType;

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnBack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnForward;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnTelephoneWmfo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressInd;
@property (weak, nonatomic) IBOutlet UILabel *lblErrorMsg;

- (void)onApplicationDidBecomeActive;

- (void) setupWebView;
- (void) loadWebViewDependingOnViewType;
- (void) maybeRemoveTelephoneWmfoBtn;
- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
- (void) webViewDidStartLoad:(UIWebView *)webView;
- (void) webViewDidFinishLoad:(UIWebView *)webView;

- (BOOL) isViewTypeAbout;
- (BOOL) isViewTypeVideos;
- (BOOL) isViewTypePlaylist;
- (BOOL) isViewTypePlaylistAndWebViewCantGoBack;
- (BOOL) isViewTypeWMFO;
- (BOOL) isViewTypeTwitter;

- (void) maybeReloadFullPlaylist;

- (IBAction)actionBtnBackPressed:(UIBarButtonItem *)sender;
- (IBAction)actionBtnForwardPressed:(UIBarButtonItem *)sender;
- (IBAction)actionBtnTelephoneWmfoPressed:(UIBarButtonItem *)sender;
@end
