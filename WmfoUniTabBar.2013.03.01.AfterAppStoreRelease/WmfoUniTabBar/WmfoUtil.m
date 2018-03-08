//
//  WmfoUtil.m
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/9/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

// For network connection test
#import <SystemConfiguration/SystemConfiguration.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#import <mach/mach.h>

@implementation WmfoUtil

#pragma mark -
#pragma mark Error and Logging Methods

// From: http://stackoverflow.com/questions/1374926/how-to-get-rid-of-all-this-garbage-in-nslog
// Also see: http://borkware.com/rants/agentm/mlog/
// NSLog() writes out entirely too much stuff.  Most of the time I'm
// not interested in the program name, process ID, and current time
// down to the subsecond level.
// This takes an NSString with printf-style format, and outputs it.
// regular old printf can't be used instead because it doesn't
// support the '%@' format option.

void WmfoUtilQuietLog(NSString *format, ...) {
    va_list argList;
    va_start (argList, format);
    NSString *message = [[NSString alloc] initWithFormat: format arguments: argList];
    printf ("%s", [message UTF8String]);
    va_end  (argList);
}

#pragma mark -
#pragma mark Memory Logging Methods

+ (BOOL) queryMemoryUsageNumBytes:(UInt32 *)pNumBytes andNumMB:(float *)pNumMB {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof info;
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        UInt32 numBytes = info.resident_size;
        *pNumBytes = numBytes;
        *pNumMB = numBytes / (float) kWmfoNumBytesPerMB;
        return TRUE;
    }
    WmfoUtilQuietLog(@"queryMemoryUsageNumBytes - Error with task_info(): %s\n", mach_error_string(kerr));
    return FALSE;
}
+ (NSString *) getMemoryUsageAsNSString {
    static int prevNumBytes = 0;
    UInt32 numBytes;
    float numMB;
    [WmfoUtil queryMemoryUsageNumBytes:&numBytes andNumMB:&numMB];
    int numBytesDiff = numBytes - prevNumBytes;
    NSString * s = [NSString stringWithFormat:@"Memory in use %.2f MB (%u bytes, %+d)\n", numMB, (unsigned int)numBytes, numBytesDiff];
    prevNumBytes = numBytes;
    return s;
}
+ (void) reportMemoryUsage {
    [WmfoUtil reportMemoryUsageWithComment: nil];
}
+ (void) reportMemoryUsageWithComment:(NSString*) strComment {
    NSString * strMemUsage = [WmfoUtil getMemoryUsageAsNSString];
    if (strComment == nil) {
        WmfoUtilQuietLog(@"%@\n", strMemUsage);
    } else {
        WmfoUtilQuietLog(@"%@ (%@)\n", strMemUsage, strComment);
    }
}
#pragma mark -
#pragma mark String, URL etc. Methods

+ (NSURL *) getNSURLByAddingPercentEscapesToRawUrlString:(NSString *)rawUrl {
// We want the Core Foundation created "escapedValue" to be automatically released
// when it goes out of scope here, and "__bridge_transfer" is the right way to do that...
    NSString *escapedValue =
    //	(__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(
    (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                          nil,
                                                                          (CFStringRef)rawUrl,
                                                                          NULL,
                                                                          NULL,
                                                                          kCFStringEncodingUTF8);

    NSURL *url = [NSURL URLWithString:escapedValue];
    return url;
}


#pragma mark -
#pragma mark Misc Methods

+ (BOOL) isIPad {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

#pragma mark -
#pragma mark Network checking

+ (BOOL) canTelephoneWmfo {
	// This seems to be the most straightforward way...
	return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kWmfoTelephoneURL]];
}

+ (BOOL) checkNetworkNoUI {
	BOOL isConnectedToNetwork = [WmfoUtil connectedToNetwork];
	return isConnectedToNetwork;
}
+ (BOOL) checkNetworkDisplayingAlertIfNotConnected {
	if ([self checkNetworkNoUI]) {
        return TRUE;
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
     initWithTitle:NSLocalizedStringFromTable(@"Network Error", @"Errors", nil)
     message:NSLocalizedStringFromTable(@"Could not connect to network.", @"Errors", nil)
     delegate:self
     cancelButtonTitle:@"OK"
     otherButtonTitles: nil];

    WmfoLogError(@"[WmfoUtil checkNetworkDisplayingAlertIfNotConnected]");
    [alert show];
    return FALSE;
}

//+ (BOOL) canConnectToWmfo {
//	return [WmfoUtil hostAvailable: kBaseWebcastUrl];
//}
// From Erica Sadun, iPhone Cookbook with 5.0 SDK, p. 696

+ (BOOL) connectedToNetwork {
//	return FALSE; // for quick debugging
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags) {
        WmfoLogError(@"[WmfoUtil connectedToNetwork] Could not recover network reachability flags\n");
        return NO;
    }
    
    BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
    return (isReachable && !needsConnection) ? YES : NO;
}

//+ (BOOL) addressFromString:(NSString *)IPAddress address:(struct sockaddr_in *)address {
//// We specifically don't have a prototype for this in the header because there are
//// conflicting definitions of "struct sockaddr_in" in various headers and we don't
//// reference outside this class...
//    if (!IPAddress || ![IPAddress length]) return NO;
//
//    memset((char *) address, sizeof(struct sockaddr_in), 0);
//    address->sin_family = AF_INET;
//    address->sin_len = sizeof(struct sockaddr_in);
//
//    int conversionResult = inet_aton([IPAddress UTF8String], &address->sin_addr);
//    if (conversionResult == 0) {
//		NSAssert1(conversionResult != 1, @"Failed to convert the IP address string into a sockaddr_in: %@", IPAddress);
//        return NO;
//    }
//
//    return YES;
//}
//
//+ (NSString *) getIPAddressForHost: (NSString *) theHost {
//	struct hostent *host = gethostbyname([theHost UTF8String]);
//    if (!host) {herror("resolv"); return NULL; }
//	struct in_addr **list = (struct in_addr **)host->h_addr_list;
//	NSString *addressString = [NSString stringWithCString:inet_ntoa(*list[0]) encoding:NSUTF8StringEncoding];
//	return addressString;
//}
//
//+ (BOOL) hostAvailable: (NSString *) theHost {
//
//    NSString *addressString = [self getIPAddressForHost:theHost];
//    if (!addressString)
//    {
//        printf("Error recovering IP address from host name\n");
//        return NO;
//    }
//
//    struct sockaddr_in address;
//    BOOL gotAddress = [WmfoUtil addressFromString:addressString address:&address];
//
//    if (!gotAddress)
//    {
//		printf("Error recovering sockaddr address from %s\n", [addressString UTF8String]);
//        return NO;
//    }
//
//	SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&address);
//    SCNetworkReachabilityFlags flags;
//
//	BOOL didRetrieveFlags =SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
//    CFRelease(defaultRouteReachability);
//
//    if (!didRetrieveFlags)
//    {
//        printf("Error. Could not recover network reachability flags\n");
//        return NO;
//    }
//
//    BOOL isReachable = flags & kSCNetworkFlagsReachable;
//    return isReachable ? YES : NO;;
//}

+ (void)showErrorMsgOnLabel: (UILabel *) errorMsgLabel withText: (NSString *) text {
	errorMsgLabel.text = text;
//    [errorMsgLabel.superview bringSubviewToFront: errorMsgLabel];
    errorMsgLabel.hidden = FALSE;
}
+ (void)showNetworkNotAvailableErrorMsgOnLabel: (UILabel *) errorMsgLabel {
	[WmfoUtil showErrorMsgOnLabel: errorMsgLabel withText: kNetworkNotAvailableErrorMsg];
}
+ (NSString *)constructWebViewFailLoadErrorMsgStringWithSystemError:(NSError *)error forRequest:(NSURLRequest *)request {
    NSString * s = nil;
    if (request) {
        s = [NSString stringWithFormat:@"%@%@ for request %@", kWebViewFailLoadErrorMsg, [error localizedDescription], request.URL.absoluteString];
        
    } else {
        s = [NSString stringWithFormat:@"%@%@", kWebViewFailLoadErrorMsg, [error localizedDescription]];        
    }
	return s;
}
+ (void)showWebViewFailLoadErrorMsgOnLabel: (UILabel *) errorMsgLabel withSystemError:(NSError *)error {
	NSString * s = [self constructWebViewFailLoadErrorMsgStringWithSystemError: error forRequest:nil];
	[WmfoUtil showErrorMsgOnLabel: errorMsgLabel withText: s];
}
+ (BOOL)maybeDisplayNetworkErrorMsgOnLabel: (UILabel *) errorMsgLabel  {
	if (![WmfoUtil checkNetworkNoUI]) {
		[WmfoUtil showNetworkNotAvailableErrorMsgOnLabel: errorMsgLabel];
		return TRUE;
	}
	return FALSE;
}
+ (void)handleWebViewFailLoadError:(NSError *)error {
    [WmfoUtil handleWebViewFailLoadError:error withRequest:nil];
}
+ (void)handleWebViewFailLoadError:(NSError *)error withRequest:(NSURLRequest *)request {
    WmfoUtilQuietLog(@"[WmfoUtil handleWebViewFailLoadError:withRequest] called with error %@.\n", error);
    if ([WmfoError isIgnoreableNSError:error]) {
        return;
    }
    [WmfoUtil showWebViewFailLoadErrorMsgInAlertViewForError:error forRequest:request];
}
+ (void)showWebViewFailLoadErrorMsgInAlertViewForError:(NSError *)error forRequest:(NSURLRequest *)request {
	NSString * errorMsg = [WmfoUtil constructWebViewFailLoadErrorMsgStringWithSystemError: error forRequest:request];
	UIAlertView *alert = [[UIAlertView alloc]
	 initWithTitle:NSLocalizedStringFromTable(@"Network Error", @"Errors", nil)
	 message:errorMsg
	 delegate:nil
	 cancelButtonTitle:@"OK"
	 otherButtonTitles: nil];
	[alert show];
    WmfoLogError(@"[WmfoUtil showWebViewFailLoadErrorMsgInAlertViewForError] %@", errorMsg);
}



#pragma mark -
#pragma mark UIWebView Methods

+ (void) loadRequestString:(NSString *)urlString forWebView:(UIWebView *)webView {
	NSURL * url = [NSURL URLWithString:urlString];
	NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
	[webView loadRequest:urlRequest];
}
+ (void) loadLocalFile:(NSString *)name ofType:(NSString *)ext forWebView:(UIWebView *)webView {
	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
	NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	
	NSString *htmlString = [[NSString alloc] initWithData:
							[readHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
	
	// to make html content transparent to its parent view -
	// 1) set the webview's backgroundColor property to [UIColor clearColor]
	// 2) use the content in the html: <body style="background-color: transparent">
	// 3) opaque property set to NO
	//
	//webView.opaque = NO;
	//webView.backgroundColor = [UIColor clearColor];
	//[webView loadHTMLString:htmlString baseURL:nil];
	[webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
}


@end
