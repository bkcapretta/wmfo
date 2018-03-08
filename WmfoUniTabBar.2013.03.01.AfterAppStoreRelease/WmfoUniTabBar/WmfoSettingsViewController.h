//
//  WmfoSettingsViewController.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 12/29/12.
//  Copyright (c) 2012 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoSettingsViewController : UIViewController <UITextFieldDelegate> {
	WmfoAppDelegate * _appDelegate;
}

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segCtl;
@property (weak, nonatomic) IBOutlet UILabel *lblMemoryUsage;

-(void)setupStreamTextFieldAndSegCtl;

-(void)onFinishedEditingCustomStreamTextField;
-(void)onStreamSourceChanged;

- (IBAction)actionStreamChangedSegmentAction:(UISegmentedControl *)sender;

@end
