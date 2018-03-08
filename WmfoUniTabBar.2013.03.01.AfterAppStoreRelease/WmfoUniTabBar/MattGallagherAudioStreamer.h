//
//  MattGallagherAudioStreamer.h (originally AudioStreamer.h)
//  StreamingAudioPlayer
//
//  Created by Matt Gallagher on 27/09/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#ifdef TARGET_OS_IPHONE			
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif //TARGET_OS_IPHONE			

#include <pthread.h>
#include <AudioToolbox/AudioToolbox.h>

//#import "MainViewController.h" // EDWARDHACK

#define kNumAQBufs 6			// number of audio queue buffers we allocate
#define kAQBufSize 32 * 1024		// number of bytes in each audio queue buffer
#define kAQMaxPacketDescs 512		// number of packet descriptions in our array

@interface MattGallagherAudioStreamer : NSObject
{
	NSURL *url;
	BOOL isPlaying;
	BOOL isTerminated; // EDWARDHACK: Gets set to TRUE on normal or error stop
	
@public
	float _volume;	// EDWARDHACK: a little double bookkeeping so the volume can be initialized before the audioQueue is created in a thread

	AudioFileStreamID audioFileStream;	// the audio file stream parser

	AudioQueueRef audioQueue;								// the audio queue
	AudioQueueBufferRef audioQueueBuffer[kNumAQBufs];		// audio queue buffers
	
	AudioStreamPacketDescription packetDescs[kAQMaxPacketDescs];	// packet descriptions for enqueuing audio
	
	unsigned int fillBufferIndex;	// the index of the audioQueueBuffer that is being filled
	size_t bytesFilled;				// how many bytes have been filled
	size_t packetsFilled;			// how many packets have been filled

	bool inuse[kNumAQBufs];			// flags to indicate that a buffer is still in use
	bool started;					// flag to indicate that the queue has been started
	bool failed;					// flag to indicate an error occurred
	bool finished;				// flag to inidicate that termination is requested
								// the audio queue is not necessarily complete until
								// isPlaying is also false.
	bool discontinuous;			// flag to trigger bug-avoidance
		
	pthread_mutex_t mutex;			// a mutex to protect the inuse flags
	pthread_cond_t cond;			// a condition varable for handling the inuse flags

	pthread_mutex_t mutex2;			// a mutex to protect the AudioQueue buffer
	CFReadStreamRef stream;
}

@property BOOL isPlaying;
@property BOOL isTerminated;

- (id)initWithURL:(NSURL *)newURL;
- (void)start;
- (void)stop;
- (void)setVolume: (float) volume;

@end
