//
//  WmfoUtil.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/9/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#import "WmfoApp.h"

@interface WmfoUtil : NSObject

void WmfoUtilQuietLog(NSString *format, ...);

+ (BOOL) queryMemoryUsageNumBytes:(UInt32 *)pNumBytes andNumMB:(float *)pNumMB;
+ (NSString *) getMemoryUsageAsNSString;
+ (void) reportMemoryUsage;
+ (void) reportMemoryUsageWithComment:(NSString *) strComment;

+ (NSURL *) getNSURLByAddingPercentEscapesToRawUrlString:(NSString *)rawUrl;

////////////////////////////////////////
+ (BOOL) isIPad;
+ (BOOL) canTelephoneWmfo;
+ (BOOL) checkNetworkNoUI;
+ (BOOL) checkNetworkDisplayingAlertIfNotConnected;
//+ (BOOL) canConnectToWmfo;
+ (BOOL) connectedToNetwork;
//+ (NSString *) getIPAddressForHost: (NSString *) theHost;
//+ (BOOL) hostAvailable: (NSString *) theHost;

+ (void) showNetworkNotAvailableErrorMsgOnLabel: (UILabel *) errorMsgLabel;
+ (void) showWebViewFailLoadErrorMsgOnLabel: (UILabel *) errorMsgLabel withSystemError:(NSError *)error;
+ (BOOL) maybeDisplayNetworkErrorMsgOnLabel: (UILabel *) errorMsgLabel;
+ (void)handleWebViewFailLoadError:(NSError *)error;
+ (void)handleWebViewFailLoadError:(NSError *)error withRequest:(NSURLRequest *)request;
+ (void) loadRequestString:(NSString *)urlString forWebView:(UIWebView *)webView;
+ (void) loadLocalFile:(NSString *)name ofType:(NSString *)ext forWebView:(UIWebView *)webView;

@end
