//
//  WmfoSettingsViewController.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 12/29/12.
//  Copyright (c) 2012 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@implementation WmfoSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	_appDelegate = [WmfoAppDelegate sharedInstance];
    [self updateLblMemoryUsage];
    _appDelegate.lblMemoryUsage = self.lblMemoryUsage;
	self.textField.delegate = self;
	[self setupStreamTextFieldAndSegCtl];
	// Hook up the segCtl's callback *after* we set it up so it doesn't get called prematurely...
	//[self.segCtl addTarget:self action:@selector(streamChangedSegmentAction:) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTextField:nil];
    [self setSegCtl:nil];
    [self setLblMemoryUsage:nil];
    [super viewDidUnload];
}
- (void) updateLblMemoryUsage {
    self.lblMemoryUsage.text = [WmfoUtil getMemoryUsageAsNSString];
}
- (int) isStreamTextEditableForSegCtlIndex: (int) selectedSegCtlIndex {
	if ( selectedSegCtlIndex >= 0 && selectedSegCtlIndex < 3) {
		return FALSE;
	}
	return TRUE;
}
-(void)setupStreamTextFieldAndSegCtl {
	NSString * txt = [_appDelegate getWebcastStringUrlFromCurrentSelectedSegCtlIndex];
	self.textField.text = txt;
	int webcastUrlStreamIndex = _appDelegate.webcastUrlStreamIndex;
	self.segCtl.selectedSegmentIndex = webcastUrlStreamIndex;
	if ([self isStreamTextEditableForSegCtlIndex: webcastUrlStreamIndex]) {
		self.textField.enabled = TRUE;
		self.textField.textColor = [UIColor blackColor];
	} else {
		self.textField.enabled = FALSE;
		self.textField.textColor = [UIColor grayColor];
	}
}
-(void)onFinishedEditingCustomStreamTextField {
    [self.textField resignFirstResponder];
    if (![_appDelegate.webcastUrlStreamCustom isEqualToString:self.textField.text]) {
        // Only change the source if the user has actually changed it...
        _appDelegate.webcastUrlStreamCustom = self.textField.text;
        [self onStreamSourceChanged];        
    }
}
-(void)onStreamSourceChanged {
	[self setupStreamTextFieldAndSegCtl];
	[_appDelegate stopStream];
	[_appDelegate startStream];
    [self updateLblMemoryUsage];
}
#if 1
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Dismiss the keyboard when the view outside the text field is touched.
    if (self.textField.isFirstResponder) {
        [self onFinishedEditingCustomStreamTextField];        
    }
    [super touchesBegan:touches withEvent:event];
}
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	// When the user presses return, take focus away from the text field so that the keyboard is dismissed.
	if (theTextField == self.textField) {
		[self onFinishedEditingCustomStreamTextField];
	}
	return YES;
}
#endif
- (IBAction)actionStreamChangedSegmentAction:(UISegmentedControl *)sender {
	_appDelegate.webcastUrlStreamIndex = sender.selectedSegmentIndex;
	[self onStreamSourceChanged];
}
@end
