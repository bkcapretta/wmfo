//
//  WmfoPlayButton.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/16/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"
#import <QuartzCore/CoreAnimation.h>

@implementation WmfoPlayButton

- (BOOL) isBigButton {
    if (self.frame.size.width >= 63) {
        return TRUE;
    }
    return FALSE;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _appDelegate = [WmfoAppDelegate sharedInstance];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)spinButton {
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	CGRect frame = [self frame];
	self.layer.anchorPoint = CGPointMake(0.5, 0.5);
	self.layer.position = CGPointMake(frame.origin.x + 0.5 * frame.size.width, frame.origin.y + 0.5 * frame.size.height);
	[CATransaction commit];
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanFalse forKey:kCATransactionDisableActions];
	[CATransaction setValue:[NSNumber numberWithFloat:2.0] forKey:kCATransactionAnimationDuration];
	
	CABasicAnimation *animation;
	animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.fromValue = [NSNumber numberWithFloat:0.0];
	animation.toValue = [NSNumber numberWithFloat:2 * M_PI];
	animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionLinear];
	animation.delegate = self;
	[self.layer addAnimation:animation forKey:@"rotationAnimation"];
	
	[CATransaction commit];
}
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)finished {
	if  (finished) {
		[self spinButton];
	}
}
- (void)setButtonImage:(UIImage *)image {
	[self.layer removeAllAnimations];
	[self setImage:image forState:0];
}
- (void)setButtonVisualLoading {
    NSString * imageName;
    if (self.isBigButton) {
        imageName = @"imgBtnLoading64x64.png";
    } else {
        imageName = @"imgBtnLoading32x32.png";        
    }
	[self setButtonImage:[UIImage imageNamed:imageName]];
	[self spinButton];
}
- (void)setButtonVisualStoppedAndReadyToPlay {
    NSString * imageName;
    if (self.isBigButton) {
        imageName = @"imgBtnPlay64x64.png";
    } else {
        imageName = @"imgBtnPlay32x32.png";
    }
	[self setButtonImage:[UIImage imageNamed:imageName]];
}
- (void)setButtonVisualPlayingAndReadyToStop {
    NSString * imageName;
    if (self.isBigButton) {
        imageName = @"imgBtnStop64x64.png";
    } else {
        imageName = @"imgBtnStop32x32.png";
    }
	[self setButtonImage:[UIImage imageNamed:imageName]];
}
- (void)setButtonVisualBasedOnStreamer {
	MattGallagherAudioStreamer * streamer = _appDelegate.streamer;
#if 1
	if (streamer) {
		if (streamer.isPlaying) {
			[self setButtonVisualPlayingAndReadyToStop];
		} else if (streamer.isTerminated) {
			[self setButtonVisualStoppedAndReadyToPlay];
		} else {
			[self setButtonVisualLoading];
		}
	} else {
		[self setButtonVisualStoppedAndReadyToPlay];
	}
#else
	if (streamer && streamer->started) {
		if (streamer.isPlaying) {
			[self setButtonVisualPlayingAndReadyToStop];
		} else {
			[self setButtonVisualLoading];
		}
	} else {
		[self setButtonVisualStoppedAndReadyToPlay];
	}
#endif
}

- (void)onPlayingStartedNotification {
	[self
	 performSelector:@selector(setButtonVisualPlayingAndReadyToStop)
	 onThread:[NSThread mainThread]
	 withObject:nil
	 waitUntilDone:NO];
}
- (void)onPlayingStoppedNotification {
	[self
	 performSelector:@selector(setButtonVisualStoppedAndReadyToPlay)
	 onThread:[NSThread mainThread]
	 withObject:nil
	 waitUntilDone:NO];
}


@end
