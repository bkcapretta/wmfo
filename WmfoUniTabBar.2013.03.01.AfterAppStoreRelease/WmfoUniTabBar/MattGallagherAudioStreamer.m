//
//  MattGallagherAudioStreamer.m (originally AudioStreamer.m)
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

#import "WmfoApp.h"
#ifdef TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#endif

#define PRINTERROR(LABEL)	printf("%s err %4.4s %d\n", LABEL, (char *)&err, (int)err)

#pragma mark CFReadStream Callback Function Prototypes

void ReadStreamCallBack(
							   CFReadStreamRef stream,
							   CFStreamEventType eventType,
							   void* dataIn);

#pragma mark Audio Callback Function Prototypes

void MyAudioQueueOutputCallback(void* inClientData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);
void MyPropertyListenerProc(	void *							inClientData,
								AudioFileStreamID				inAudioFileStream,
								AudioFileStreamPropertyID		inPropertyID,
								UInt32 *						ioFlags);
void MyPacketsProc(				void *							inClientData,
								UInt32							inNumberBytes,
								UInt32							inNumberPackets,
								const void *					inInputData,
								AudioStreamPacketDescription	*inPacketDescriptions);
OSStatus MyEnqueueBuffer(MattGallagherAudioStreamer* myData);

#ifdef TARGET_OS_IPHONE			
void MattGallagherAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState);
#endif

#pragma mark Audio Callback Function Implementations

//
// MyPropertyListenerProc
//
// Receives notification when the AudioFileStream has audio packets to be
// played. In response, this function creates the AudioQueue, getting it
// ready to begin playback (playback won't begin until audio packets are
// sent to the queue in MyEnqueueBuffer).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// kAudioQueueProperty_IsRunning listening added.
//
void MyPropertyListenerProc(	void *							inClientData,
								AudioFileStreamID				inAudioFileStream,
								AudioFileStreamPropertyID		inPropertyID,
								UInt32 *						ioFlags)
{	
	// this is called by audio file stream when it finds property values
	MattGallagherAudioStreamer* myData = (__bridge MattGallagherAudioStreamer*)inClientData;
	OSStatus err = noErr;

	switch (inPropertyID) {
		case kAudioFileStreamProperty_ReadyToProducePackets :
		{
			myData->discontinuous = true;
			
			// the file stream parser is now ready to produce audio packets.
			// get the stream format.
			AudioStreamBasicDescription asbd;
			UInt32 asbdSize = sizeof(asbd);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
			if (err) { PRINTERROR("get kAudioFileStreamProperty_DataFormat"); myData->failed = true; break; }
			
			// create the audio queue
			err = AudioQueueNewOutput(&asbd, MyAudioQueueOutputCallback, (__bridge void *)(myData), NULL, NULL, 0, &myData->audioQueue);
			if (err) {
                WmfoCheckOSStatusAndLogError(err, @"MyPropertyListenerProc() - AudioQueueNewOutput()");
                PRINTERROR("AudioQueueNewOutput"); myData->failed = true; break;
            }
			AudioQueueSetParameter ( myData->audioQueue, kAudioQueueParam_Volume, myData->_volume );			
			
			// listen to the "isRunning" property
			err = AudioQueueAddPropertyListener(myData->audioQueue, kAudioQueueProperty_IsRunning, MyAudioQueueIsRunningCallback, (__bridge void *)(myData));
			if (err) { PRINTERROR("AudioQueueAddPropertyListener"); myData->failed = true; break; }
			
			// allocate audio queue buffers
			for (unsigned int i = 0; i < kNumAQBufs; ++i) {
				err = AudioQueueAllocateBuffer(myData->audioQueue, kAQBufSize, &myData->audioQueueBuffer[i]);
				if (err) { PRINTERROR("AudioQueueAllocateBuffer"); myData->failed = true; break; }
			}
// 2013.02.04 - It appears that reading an MP3 stream no longer requires / supports kAudioFileStreamProperty_MagicCookieData
#if 0
			// get the cookie size
			UInt32 cookieSize;
			Boolean writable;
			err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
            WmfoCheckAndLogError(err, @"MyPropertyListenerProc AudioFileStreamGetPropertyInfo kAudioFileStreamProperty_MagicCookieData");
			if (err) { PRINTERROR("info kAudioFileStreamProperty_MagicCookieData"); break; }

			// get the cookie data
			void* cookieData = calloc(1, cookieSize);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
			if (err) { PRINTERROR("get kAudioFileStreamProperty_MagicCookieData"); free(cookieData); break; }

			// set the cookie on the queue.
			err = AudioQueueSetProperty(myData->audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
			free(cookieData);
			if (err) { PRINTERROR("set kAudioQueueProperty_MagicCookie"); break; }
			break;
#endif
		}
	}
}

//
// MyPacketsProc
//
// When the AudioStream has packets to be played, this function gets an
// idle audio buffer and copies the audio packets into it. The calls to
// MyEnqueueBuffer won't return until there are buffers available (or the
// playback has been stopped).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
void MyPacketsProc(				void *							inClientData,
								UInt32							inNumberBytes,
								UInt32							inNumberPackets,
								const void *					inInputData,
								AudioStreamPacketDescription	*inPacketDescriptions)
{
	// this is called by audio file stream when it finds packets of audio
	MattGallagherAudioStreamer* myData = (__bridge MattGallagherAudioStreamer*)inClientData;
	
	// we have successfully read the first packests from the audio stream, so
	// clear the "discontinuous" flag
	myData->discontinuous = false;

	// the following code assumes we're streaming VBR data. for CBR data, the second branch is used.
	if (inPacketDescriptions)
	{
		for (int i = 0; i < inNumberPackets; ++i) {
			SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
			SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
			
			// If the audio was terminated before this point, then
			// exit.
			if (myData->finished)
			{
				return;
			}

			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			if (bufSpaceRemaining < packetSize) {
				MyEnqueueBuffer(myData);
			}
			
			pthread_mutex_lock(&myData->mutex2);

			// If the audio was terminated while waiting for a buffer, then
			// exit.
			if (myData->finished)
			{
				pthread_mutex_unlock(&myData->mutex2);
				return;
			}
			 
			// copy data to the audio queue buffer
			AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
			memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)inInputData + packetOffset, packetSize);
			
			pthread_mutex_unlock(&myData->mutex2);
			
			// fill out packet description
			myData->packetDescs[myData->packetsFilled] = inPacketDescriptions[i];
			myData->packetDescs[myData->packetsFilled].mStartOffset = myData->bytesFilled;
			// keep track of bytes filled and packets filled
			myData->bytesFilled += packetSize;
			myData->packetsFilled += 1;

			// if that was the last free packet description, then enqueue the buffer.
			size_t packetsDescsRemaining = kAQMaxPacketDescs - myData->packetsFilled;
			if (packetsDescsRemaining == 0) {
				MyEnqueueBuffer(myData);
			}
		}	
	}
	else
	{
		size_t offset = 0;
		while (inNumberBytes)
		{
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			if (bufSpaceRemaining < inNumberBytes) {
				MyEnqueueBuffer(myData);
			}
			
			pthread_mutex_lock(&myData->mutex2);

			// If the audio was terminated while waiting for a buffer, then
			// exit.
			if (myData->finished)
			{
				pthread_mutex_unlock(&myData->mutex2);
				return;
			}
			
			// copy data to the audio queue buffer
			AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
			bufSpaceRemaining = kAQBufSize - myData->bytesFilled;
			size_t copySize;
			if (bufSpaceRemaining < inNumberBytes)
			{
				copySize = bufSpaceRemaining;
			}
			else
			{
				copySize = inNumberBytes;
			}
			memcpy((char*)fillBuf->mAudioData + myData->bytesFilled, (const char*)(inInputData + offset), copySize);

			pthread_mutex_unlock(&myData->mutex2);

			// keep track of bytes filled and packets filled
			myData->bytesFilled += copySize;
			myData->packetsFilled = 0;
			inNumberBytes -= copySize;
			offset += copySize;
		}
	}
}

//
// MyEnqueueBuffer
//
// Called from MyPacketsProc and connectionDidFinishLoading to pass filled audio
// bufffers (filled by MyPacketsProc) to the AudioQueue for playback. This
// function does not return until a buffer is idle for further filling or
// the AudioQueue is stopped.
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
OSStatus MyEnqueueBuffer(MattGallagherAudioStreamer* myData)
{
	OSStatus err = noErr;
	myData->inuse[myData->fillBufferIndex] = true;		// set in use flag
	
	// enqueue buffer
	AudioQueueBufferRef fillBuf = myData->audioQueueBuffer[myData->fillBufferIndex];
	fillBuf->mAudioDataByteSize = myData->bytesFilled;
	
	if (myData->packetsFilled)
	{
		err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, myData->packetsFilled, myData->packetDescs);
	}
	else
	{
		err = AudioQueueEnqueueBuffer(myData->audioQueue, fillBuf, 0, NULL);
	}
	
	if (err) { PRINTERROR("AudioQueueEnqueueBuffer"); myData->failed = true; return err; }		
	
	if (!myData->started) {		// start the queue if it has not been started already
		err = AudioQueueStart(myData->audioQueue, NULL);
		if (err) {
            WmfoCheckOSStatusAndLogError(err, @"MyEnqueueBuffer");
            PRINTERROR("AudioQueueStart"); myData->failed = true; return err;
        }
		myData->started = true;
	}

	// go to next buffer
	if (++myData->fillBufferIndex >= kNumAQBufs) myData->fillBufferIndex = 0;
	myData->bytesFilled = 0;		// reset bytes filled
	myData->packetsFilled = 0;		// reset packets filled

	// wait until next buffer is not in use
	pthread_mutex_lock(&myData->mutex); 
	while (myData->inuse[myData->fillBufferIndex] && !myData->finished)
	{
		pthread_cond_wait(&myData->cond, &myData->mutex);
	}
	pthread_mutex_unlock(&myData->mutex);

	return err;
}

//
// MyFindQueueBuffer
//
// Returns the index of the specified buffer in the audioQueueBuffer array.
//
// This function is unchanged from Apple's example in AudioFileStreamExample.
//
int MyFindQueueBuffer(MattGallagherAudioStreamer* myData, AudioQueueBufferRef inBuffer)
{
	for (unsigned int i = 0; i < kNumAQBufs; ++i) {
		if (inBuffer == myData->audioQueueBuffer[i]) 
			return i;
	}
	return -1;
}

//
// MyAudioQueueOutputCallback
//
// Called from the AudioQueue when playback of specific buffers completes. This
// function signals from the AudioQueue thread to the AudioStream thread that
// the buffer is idle and available for copying data.
//
// This function is unchanged from Apple's example in AudioFileStreamExample.
//
void MyAudioQueueOutputCallback(	void*					inClientData, 
									AudioQueueRef			inAQ, 
									AudioQueueBufferRef		inBuffer)
{
	// this is called by the audio queue when it has finished decoding our data. 
	// The buffer is now free to be reused.
	MattGallagherAudioStreamer* myData = (__bridge MattGallagherAudioStreamer*)inClientData;
	unsigned int bufIndex = MyFindQueueBuffer(myData, inBuffer);
	
	// signal waiting thread that the buffer is free.
	pthread_mutex_lock(&myData->mutex);
	myData->inuse[bufIndex] = false;
	pthread_cond_signal(&myData->cond);
	pthread_mutex_unlock(&myData->mutex);
}

//
// MyAudioQueueIsRunningCallback
//
// Called from the AudioQueue when playback is started or stopped. This
// information is used to toggle the observable "isPlaying" property and
// set the "finished" flag.
//
void MyAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	MattGallagherAudioStreamer *myData = (__bridge MattGallagherAudioStreamer *)inUserData;
	
	if (myData.isPlaying)
	{
		myData->finished = true;
		myData.isPlaying = false;

#ifdef TARGET_OS_IPHONE			
		AudioSessionSetActive(false);
#endif
	}
	else
	{
		myData.isPlaying = true;
		if (myData->finished)
		{
			myData.isPlaying = false;
		}
		
		//
		// Note about this bug avoidance quirk:
		//
		// On cleanup of the AudioQueue thread, on rare occasions, there would
		// be a crash in CFSetContainsValue as a CFRunLoopObserver was getting
		// removed from the CFRunLoop.
		//
		// After lots of testing, it appeared that the audio thread was
		// attempting to remove CFRunLoop observers from the CFRunLoop after the
		// thread had already deallocated the run loop.
		//
		// By creating an NSRunLoop for the AudioQueue thread, it changes the
		// thread destruction order and seems to avoid this crash bug -- or
		// at least I haven't had it since (nasty hard to reproduce error!)
		//
		[NSRunLoop currentRunLoop];
	}
	
}

#ifdef TARGET_OS_IPHONE			
//
// MyAudioSessionInterruptionListener
//
// Invoked if the audio session is interrupted (like when the phone rings)
//
void MattGallagherAudioSessionInterruptionListener(void *pData, UInt32 interruptionState)
{
	WmfoAppDelegate * appDelegate = (__bridge WmfoAppDelegate *) pData;
	MattGallagherAudioStreamer *streamer = appDelegate.streamer;
	if (interruptionState == kAudioSessionBeginInterruption) {
		if (streamer.isPlaying) {
            WmfoUtilQuietLog(@"MattGallagherAudioSessionInterruptionListener() kAudioSessionBeginInterruption streamer.isPlaying = TRUE\n");
            appDelegate.startPlayingOnApplicationDidBecomeActive = TRUE;
			[appDelegate stopStream];
		} else {
            WmfoUtilQuietLog(@"MattGallagherAudioSessionInterruptionListener() kAudioSessionBeginInterruption streamer.isPlaying = FALSE\n");
            appDelegate.startPlayingOnApplicationDidBecomeActive = FALSE;
		}
	} else if (interruptionState == kAudioSessionEndInterruption) {
        WmfoUtilQuietLog(@"MattGallagherAudioSessionInterruptionListener() kAudioSessionEndInterruption\n");
	}
}
#endif

#pragma mark CFReadStream Callback Function Implementations

//
// ReadStreamCallBack
//
// This is the callback for the CFReadStream from the network connection. This
// is where all network data is passed to the AudioFileStream.
//
// Invoked when an error occurs, the stream ends or we have data to read.
//
void ReadStreamCallBack
(
   CFReadStreamRef stream,
   CFStreamEventType eventType,
   void* dataIn
)
{
	MattGallagherAudioStreamer *myData = (__bridge MattGallagherAudioStreamer *)dataIn;
	
	if (eventType == kCFStreamEventErrorOccurred)
	{
		myData->failed = YES;
	}
	else if (eventType == kCFStreamEventEndEncountered)
	{
		if (myData->failed || myData->finished)
		{
			return;
		}
		
		//
		// If there is a partially filled buffer, pass it to the AudioQueue for
		// processing
		//
		if (myData->bytesFilled)
		{
			MyEnqueueBuffer(myData);
		}

		//
		// If the AudioQueue started, then flush it (to make certain everything
		// sent thus far will be processed) and subsequently stop the queue.
		//
		if (myData->started)
		{
			OSStatus err = AudioQueueFlush(myData->audioQueue);
			if (err) { PRINTERROR("AudioQueueFlush"); return; }
			
			err = AudioQueueStop(myData->audioQueue, false);
			if (err) { PRINTERROR("AudioQueueStop"); return; }

			CFReadStreamClose(stream);
			CFRelease(stream);
			myData->stream = nil;
		}
		else
		{
			//
			// If we have reached the end of the file without starting, then we
			// have failed to find any audio in the file. Abort.
			//
			myData->failed = YES;
		}
	}
	else if (eventType == kCFStreamEventHasBytesAvailable)
	{
		if (myData->failed || myData->finished)
		{
			return;
		}
		
		//
		// Read the bytes from the stream
		//
		UInt8 bytes[kAQBufSize];
		CFIndex length = CFReadStreamRead(stream, bytes, kAQBufSize);
		
		if (length == -1)
		{
			myData->failed = YES;
			return;
		}
		
		//
		// Parse the bytes read by sending them through the AudioFileStream
		//
		if (length > 0)
		{
			if (myData->discontinuous)
			{
				OSStatus err = AudioFileStreamParseBytes(myData->audioFileStream, length, bytes, kAudioFileStreamParseFlag_Discontinuity);
				if (err) { PRINTERROR("AudioFileStreamParseBytes"); myData->failed = true;}
			}
			else
			{
				OSStatus err = AudioFileStreamParseBytes(myData->audioFileStream, length, bytes, 0);
				if (err) { PRINTERROR("AudioFileStreamParseBytes"); myData->failed = true; }
			}
		}
	}
}

@implementation MattGallagherAudioStreamer

@synthesize isPlaying;
@synthesize isTerminated;

//
// initWithURL
//
// Init method for the object.
//
- (id)initWithURL:(NSURL *)newUrl
{
	self = [super init];
	if (self != nil) {
		url = newUrl;
	}
	return self;
}

//
// startInternal
//
// This is the start method for the AudioStream thread. This thread is created
// because it will be blocked when there are no audio buffers idle (and ready
// to receive audio data).
//
// Activity in this thread:
//	- Creation and cleanup of all AudioFileStream and AudioQueue objects
//	- Receives data from the CFReadStream
//	- AudioFileStream processing
//	- Copying of data from AudioFileStream into audio buffers
//  - Stopping of the thread because of end-of-file
//	- Stopping due to error or failure
//
// Activity *not* in this thread:
//	- AudioQueue playback and notifications (happens in AudioQueue thread)
//  - Actual download of NSURLConnection data (NSURLConnection's thread)
//	- Creation of the AudioStreamer (other, likely "main" thread)
//	- Invocation of -start method (other, likely "main" thread)
//	- User/manual invocation of -stop (other, likely "main" thread)
//
// This method contains bits of the "main" function from Apple's example in
// AudioFileStreamExample.
//
- (void)startInternal
{
//	//
//	// Retains "self". This means that we can't be deleted while playback is
//	// using our buffers. It also means that releasing an AudioStreamer while
//	// it is playing won't stop playback. This is a bit weird but, oh well.
//	//
//	[self retain];
//	
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
#ifdef TARGET_OS_IPHONE			
	//
	// Set the audio session category so that we continue to play if the
	// iPhone/iPod auto-locks.
	//
	AudioSessionInitialize (
		NULL,                          // 'NULL' to use the default (main) run loop
		NULL,                          // 'NULL' to use the default run loop mode
		MattGallagherAudioSessionInterruptionListener,  // a reference to your interruption callback
		(__bridge void *)([WmfoAppDelegate sharedInstance]) // data to pass to your interruption listener callback
	);
	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty (
		kAudioSessionProperty_AudioCategory,
		sizeof (sessionCategory),
		&sessionCategory
	);
	AudioSessionSetActive(true);
#endif

	//
	// Attempt to guess the file type from the URL. Reading the MIME type
	// from the CFReadStream would be a better approach since lots of
	// URL's don't have the right extension.
	//
	// If you have a fixed file-type, you may want to hardcode this.
	//
	AudioFileTypeID fileTypeHint = kAudioFileMP3Type;
#if 0 // Edward says, yes, let's hardcode this because it's always MP3...
	NSString *fileExtension = [[url path] pathExtension];
	if ([fileExtension isEqual:@"mp3"])
	{
		fileTypeHint = kAudioFileMP3Type;
	}
	else if ([fileExtension isEqual:@"wav"])
	{
		fileTypeHint = kAudioFileWAVEType;
	}
	else if ([fileExtension isEqual:@"aifc"])
	{
		fileTypeHint = kAudioFileAIFCType;
	}
	else if ([fileExtension isEqual:@"aiff"])
	{
		fileTypeHint = kAudioFileAIFFType;
	}
	else if ([fileExtension isEqual:@"m4a"])
	{
		fileTypeHint = kAudioFileM4AType;
	}
	else if ([fileExtension isEqual:@"mp4"])
	{
		fileTypeHint = kAudioFileMPEG4Type;
	}
	else if ([fileExtension isEqual:@"caf"])
	{
		fileTypeHint = kAudioFileCAFType;
	}
	else if ([fileExtension isEqual:@"aac"])
	{
		fileTypeHint = kAudioFileAAC_ADTSType;
	}
#endif
	// initialize a mutex and condition so that we can block on buffers in use.
	pthread_mutex_init(&mutex, NULL);
	pthread_cond_init(&cond, NULL);
	pthread_mutex_init(&mutex2, NULL);
	
	// create an audio file stream parser
	OSStatus err = AudioFileStreamOpen((__bridge void *)(self), MyPropertyListenerProc, MyPacketsProc, 
							fileTypeHint, &audioFileStream);
	if (err) { PRINTERROR("AudioFileStreamOpen"); goto cleanup; }
	
	//
	// Create the GET request
	//
    CFHTTPMessageRef message= CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (__bridge CFURLRef)url, kCFHTTPVersion1_1);
    stream = CFReadStreamCreateForHTTPRequest(NULL, message);
    CFRelease(message);
    if (!CFReadStreamOpen(stream))
	{
        CFRelease(stream);
		goto cleanup;
    }
	
	//
	// Set our callback function to receive the data
	//
	CFStreamClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
	CFReadStreamSetClient(
		stream,
		kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered,
		ReadStreamCallBack,
		&context);
	CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);

	//
	// Process the run loop until playback is finished or failed.
	//
	do
	{
		CFRunLoopRunInMode(
			kCFRunLoopDefaultMode,
			0.25,
			false);  // HUH: Can generate "info kAudioFileStreamProperty_MagicCookieData err ?knu 1970170687"
		
		if (failed)
		{
			[self stop];

			NSString * baseMsg = NSLocalizedStringFromTable(@"Couldn't play audio", @"Errors", nil);
			NSString * fullMsg = [NSString stringWithFormat: @"%@ \n[from %@]", baseMsg, [url absoluteString]];
            WmfoLogError(fullMsg);
            UIApplicationState applicationState = [UIApplication sharedApplication].applicationState;
            if (applicationState == UIApplicationStateActive) {
                // Displaying UI like this when we're not active results in a crash after we reactivate!
                UIAlertView *alert =
				[[UIAlertView alloc]
                 initWithTitle:NSLocalizedStringFromTable(@"Network Error", @"Errors", nil)
                 //message:NSLocalizedStringFromTable(@"Attempt to play streaming audio failed.", @"Errors", nil)
                 message: fullMsg
                 delegate:self
                 cancelButtonTitle:@"OK"
                 otherButtonTitles: nil];
                [alert
                 performSelector:@selector(show)
                 onThread:[NSThread mainThread]
                 withObject:nil
                 waitUntilDone:YES];                
            }
			break;
		}
	} while (isPlaying || !finished);
	
cleanup:

	//
	// Cleanup the read stream if it is still open
	//
	if (stream)
	{
		CFReadStreamClose(stream);
        CFRelease(stream);
		stream = nil;
	}
	
	//
	// Close the audio file strea,
	//
	err = AudioFileStreamClose(audioFileStream);
	if (err) { PRINTERROR("AudioFileStreamClose"); goto cleanup; }
	
	//
	// Dispose of the Audio Queue
	//
	if (started)
	{
		err = AudioQueueDispose(audioQueue, true);
		if (err) { PRINTERROR("AudioQueueDispose"); goto cleanup; }
	}

//	[pool release];
//	[self release];
}

//
// start
//
// Calls startInternal in a new thread.
//
- (void)start
{
	[NSThread detachNewThreadSelector:@selector(startInternal) toTarget:self withObject:nil];
}

//
// stop
//
// This method can be called to stop downloading/playback before it completes.
// It is automatically called when an error occurs.
//
// If playback has not started before this method is called, it will toggle the
// "isPlaying" property so that it is guaranteed to transition to true and
// back to false 
//
- (void)stop
{
	isTerminated = TRUE;
	
	if (stream)
	{
		CFReadStreamClose(stream);
        CFRelease(stream);
		stream = nil;
		
		if (finished)
		{
			return;
		}
		
		if (started)
		{
			//
			// Set finished to true *before* we call stop. This is to handle our
			// third thread...
			//	- This method is called from main (UI) thread
			//	- The AudioQueue thread (which owns the AudioQueue buffers and
			//		will delete them as soon as we call AudioQueueStop)
			//	- URL connection thread is copying data from AudioStream to
			//		AudioQueue buffer
			// We set this flag to tell the URL connection thread to stop
			// copying.
			//
			pthread_mutex_lock(&mutex2);
			finished = true;

			OSStatus err = AudioQueueStop(audioQueue, true);
			if (err) { PRINTERROR("AudioQueueStop"); }
			pthread_mutex_unlock(&mutex2);
			
			pthread_mutex_lock(&mutex);
			pthread_cond_signal(&cond);
			pthread_mutex_unlock(&mutex);
		}
		else
		{
			finished = true;
			self.isPlaying = YES; // See original comment above about toggling this...
			self.isPlaying = NO;
		}
	}
}

- (void)setVolume: (float) volume
{
	_volume = volume;
	AudioQueueSetParameter ( audioQueue,
							kAudioQueueParam_Volume,
							volume
	);
}

@end
