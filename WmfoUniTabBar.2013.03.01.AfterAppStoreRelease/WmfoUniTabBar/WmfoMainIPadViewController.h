//
//  WmfoMainIPadViewController.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/12/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoMainIPadViewController : UIViewController <UIWebViewDelegate, UIPopoverControllerDelegate, UIActionSheetDelegate> {
    WmfoAppDelegate * _appDelegate;
	NSTimer * _timerSpinitron;
    WmfoViewType _lastWebViewType;
    // We automatically refresh the current web view with a timer if and only if it's the full playlist 
    BOOL _isFullPlaylistLastUserWebView;
}
@property (weak, nonatomic) IBOutlet WmfoPlayButton *wmfoPlayButton;
@property (weak, nonatomic) IBOutlet UISlider *sliderVolume;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *lblErrorMsg;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressInd;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UIButton *btnForward;

@property (strong) UIPopoverController *activePopoverController;

- (void)dismissActivePopoverController;

- (void)setupWebView;

- (void)startTimer;
- (void)stopTimer;

- (IBAction)actionWmfoPlayButtonTouchUpInside:(WmfoPlayButton *)sender;
- (IBAction)actionVolumeSliderValueChanged:(UISlider *)sender;

- (IBAction)actionBtnBackPressed:(UIButton *)sender;
- (IBAction)actionBtnForwardPressed:(UIButton *)sender;

- (IBAction)actionPlaylist:(id)sender;
- (IBAction)actionVideos:(id)sender;
- (IBAction)actionSettings:(UIButton *)sender;
- (IBAction)actionWmfoWebsite:(id)sender;
- (IBAction)actionTwitter:(id)sender;
- (IBAction)actionAbout:(id)sender;

@end
