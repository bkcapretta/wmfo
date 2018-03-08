//
//  WmfoMainViewController.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 12/29/12.
//  Copyright (c) 2012 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoMainIPhoneViewController : UIViewController <UIWebViewDelegate> {
    WmfoAppDelegate * _appDelegate;
	NSTimer * _timerSpinitron;
}

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UISlider *sliderVolume;
@property (weak, nonatomic) IBOutlet WmfoPlayButton *wmfoPlayButton;
@property (weak, nonatomic) IBOutlet UILabel *lblErrorMsg;

- (void)startTimer;
- (void)stopTimer;

- (IBAction)actionWmfoPlayButtonTouchUpInside:(WmfoPlayButton *)sender;
- (IBAction)actionVolumeSliderValueChanged:(UISlider *)sender;

@end
