//
//  WmfoError.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 2/4/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@implementation WmfoError

+ (BOOL) isIgnoreableNSError:(NSError *)error {
    if ([error code] == NSURLErrorCancelled) {
        // This error is "returned when an asynchronous load is cancelled" and on javascript redirects
        // and is basically a spurious error from our perspective...
        WmfoUtilQuietLog(@"[WmfoError isIgnoreableNSError] called with error code NSURLErrorCancelled.\n");
        return TRUE;
    } else if ([error.domain isEqualToString:@"WebKitErrorDomain"] && [error code] == 101) {
        // This error is returned by the Twitter website with the errorMsg "Could not load content from web site: The URL can't be shown for request uz-js-frame:uzObjectiveCFunctionCloseBrowser" and doesn't seem relevant for our purposes...
        WmfoUtilQuietLog(@"[WmfoError isIgnoreableNSError] called with error.domain WebKitErrorDomain and error code == 101.\n");
        return TRUE;
    }
    return FALSE;
}

// generic error handler - if err is nonzero, prints error message and exits program.
static char * WmfoGetStdSysErrorStatusStr(OSStatus error) {
    char * resultStr = NULL;
    switch (error) {
        case kAudioUnitErr_IllegalInstrument:
            resultStr = "kAudioUnitErr_IllegalInstrument";
            break;
        case kAudioUnitErr_InstrumentTypeNotFound:
            resultStr = "kAudioUnitErr_InstrumentTypeNotFound";
            break;
        case kAudioUnitErr_UnknownFileType:
            resultStr = "kAudioUnitErr_UnknownFileType";
            break;
        case kAudioUnitErr_FileNotSpecified:
            resultStr = "kAudioUnitErr_FileNotSpecified";
            break;
            //
        case kAudioUnitErr_InvalidProperty:
            resultStr = "kAudioUnitErr_InvalidProperty";
            break;
        case kAudioUnitErr_InvalidParameter:
            resultStr = "kAudioUnitErr_InvalidParameter";
            break;
        case kAudioUnitErr_InvalidElement:
            resultStr = "kAudioUnitErr_InvalidElement";
            break;
        case kAudioUnitErr_NoConnection:
            resultStr = "kAudioUnitErr_NoConnection";
            break;
        case kAudioUnitErr_FailedInitialization:
            resultStr = "kAudioUnitErr_FailedInitialization";
            break;
        case kAudioUnitErr_TooManyFramesToProcess:
            resultStr = "kAudioUnitErr_TooManyFramesToProcess";
            break;
        case kAudioUnitErr_InvalidFile:
            resultStr = "kAudioUnitErr_InvalidFile";
            break;
        case kAudioUnitErr_FormatNotSupported:
            resultStr = "kAudioUnitErr_FormatNotSupported";
            break;
        case kAudioUnitErr_Uninitialized:
            resultStr = "kAudioUnitErr_Uninitialized";
            break;
        case kAudioUnitErr_InvalidScope:
            resultStr = "kAudioUnitErr_InvalidScope";
            break;
        case kAudioUnitErr_PropertyNotWritable:
            resultStr = "kAudioUnitErr_PropertyNotWritable";
            break;
        case kAudioUnitErr_CannotDoInCurrentContext:
            resultStr = "kAudioUnitErr_CannotDoInCurrentContext";
            break;
        case kAudioUnitErr_InvalidPropertyValue:
            resultStr = "kAudioUnitErr_InvalidPropertyValue";
            break;
        case kAudioUnitErr_PropertyNotInUse:
            resultStr = "kAudioUnitErr_PropertyNotInUse";
            break;
        case kAudioUnitErr_Initialized:
            resultStr = "kAudioUnitErr_Initialized";
            break;
        case kAudioUnitErr_InvalidOfflineRender:
            resultStr = "kAudioUnitErr_InvalidOfflineRender";
            break;
        case kAudioUnitErr_Unauthorized:
            resultStr = "kAudioUnitErr_Unauthorized";
            break;
            //
        case kAUGraphErr_NodeNotFound:
            resultStr = "kAUGraphErr_NodeNotFound";
            break;
        case kAUGraphErr_InvalidConnection:
            resultStr = "kAUGraphErr_InvalidConnection";
            break;
        case kAUGraphErr_OutputNodeErr:
            resultStr = "kAUGraphErr_OutputNodeErr";
            break;
            //        case kAUGraphErr_CannotDoInCurrentContext: // This value is a duplicate of some other error code!
            //            resultStr = "kAUGraphErr_CannotDoInCurrentContext";
            //            break;
        case kAUGraphErr_InvalidAudioUnit:
            resultStr = "kAUGraphErr_InvalidAudioUnit";
            break;
            //
        case kAudioFileUnspecifiedError:
            resultStr = "kAudioFileUnspecifiedError";
            break;
        case kAudioFileUnsupportedFileTypeError:
            resultStr = "kAudioFileUnsupportedFileTypeError";
            break;
        case kAudioFileUnsupportedDataFormatError:
            resultStr = "kAudioFileUnsupportedDataFormatError";
            break;
        case kAudioFileUnsupportedPropertyError:
            resultStr = "kAudioFileUnsupportedPropertyError";
            break;
        case kAudioFileBadPropertySizeError:
            resultStr = "kAudioFileBadPropertySizeError";
            break;
        case kAudioFilePermissionsError:
            resultStr = "kAudioFilePermissionsError";
            break;
        case kAudioFileNotOptimizedError:
            resultStr = "kAudioFileNotOptimizedError";
            break;
        case kAudioFileInvalidChunkError:
            resultStr = "kAudioFileInvalidChunkError";
            break;
        case kAudioFileDoesNotAllow64BitDataSizeError:
            resultStr = "kAudioFileDoesNotAllow64BitDataSizeError";
            break;
        case kAudioFileInvalidPacketOffsetError:
            resultStr = "kAudioFileInvalidPacketOffsetError";
            break;
        case kAudioFileInvalidFileError:
            resultStr = "kAudioFileInvalidFileError";
            break;
        case kAudioFileOperationNotSupportedError:
            resultStr = "kAudioFileOperationNotSupportedError";
            break;
        case kAudioFileNotOpenError:
            resultStr = "kAudioFileNotOpenError";
            break;
        case kAudioFileEndOfFileError:
            resultStr = "kAudioFileEndOfFileError";
            break;
        case kAudioFilePositionError:
            resultStr = "kAudioFilePositionError";
            break;
        case kAudioFileFileNotFoundError:
            resultStr = "kAudioFileFileNotFoundError";
            break;
        default:
            resultStr = "ResultCodeNotFound";
            break;
    }
    return resultStr;
}

static char * WmfoGetCoreAudioAndStdSysErrorStatusStr(OSStatus error) {
#if 1
    char * cstrErrorCode = WmfoGetStdSysErrorStatusStr(error);
#else
    char * cstrErrorCode;
    // From "Learning Core Audio" book
    static char charCodeErrorStr[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(charCodeErrorStr + 1) = CFSwapInt32HostToBig(error);
    if (isprint(charCodeErrorStr[1]) && isprint(charCodeErrorStr[2]) && isprint(charCodeErrorStr[3]) && isprint(charCodeErrorStr[4]))
    {
        charCodeErrorStr[0] = charCodeErrorStr[5] = '\'';
        charCodeErrorStr[6] = '\0';
        cstrErrorCode = charCodeErrorStr;
    } else {
        cstrErrorCode = WmfoGetStdSysErrorStatusStr(error);
    }
#endif
    return cstrErrorCode;
}

BOOL WmfoCheckOSStatusError(OSStatus error, const char *operation) {
	if (error == noErr) return TRUE;
    char * strErrorCode = WmfoGetCoreAudioAndStdSysErrorStatusStr(error);
	fprintf(stderr, "Error: %s (%s)\n", operation, strErrorCode);
    return FALSE;
    //	exit(1);
}
BOOL WmfoCheckOSStatusAndLogError(OSStatus error, NSString *format, ...) {
	if (error == noErr) return TRUE;
    char * cstrErrorCode = WmfoGetCoreAudioAndStdSysErrorStatusStr(error);
    NSString * strErrorCode = [NSString stringWithUTF8String:cstrErrorCode];
    // See also WmfoUtilQuietLog() for similar va_list processing
    va_list argList;
    va_start (argList, format);
    NSString * msg = [[NSString alloc] initWithFormat: format arguments: argList];
    WmfoUtilQuietLog(@"WmfoCheckAndLogError: %@ - %@\n", strErrorCode, msg);
    va_end  (argList);
    return FALSE;
}
void WmfoLogError(NSString *format, ...) {
    // See also WmfoUtilQuietLog() for similar va_list processing
    va_list argList;
    va_start (argList, format);
    NSString * msg = [[NSString alloc] initWithFormat: format arguments: argList];
    WmfoUtilQuietLog(@"WmfoLogError- %@\n", msg);
    va_end  (argList);
}
void WmfoErrorExceptionHandler(NSException *exception)
{
    //    NSArray *stack = [exception callStackReturnAddresses];
    //    NSLog(@"Stack trace: %@", stack);
    NSLog(@"WmfoErrorExceptionHandler-Stack Trace: %@", [exception callStackSymbols]);
}
@end
#if 0
No application records were found.
Applications must be ready for upload on iTunes Connect before they can be validated or submitted from within Xcode.
Screenshots for 3.5-inch iPhone and iPod touch Retina display must be 960x640, 960x600, 640x960 or 640x920 pixels, at least 72 DPI, in the RGB color space, and in the JPG or PNG format.
iPad Screenshots must be .jpeg, .jpg, .tif, .tiff, or .png file that is 1024x768, 1024x748, 768x1024, 768x1004, 2048x1536, 2048x1496, 1536x2048 or 1536x2008 pixels, at least 72 DPI, and in the RGB color space.
Screenshots for 4-inch iPhone 5 and iPod touch (5th generation) Retina display must be 1136x640, 1136x600, 640x1136 or 640x1096 pixels, at least 72 DPI, in the RGB color space, and in the JPG or PNG format.
Big Brother and The Holding Company featuring Janis Joplin “BALL AND CHAIN” from Live at the Carousel Ballroom 1968 CD/LOSSLESS ALBUM (Sony 2012)Buy it!
#endif
