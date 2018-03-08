//
//  WmfoError.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 2/4/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface WmfoError : NSObject
+ (BOOL) isIgnoreableNSError:(NSError *)error;
@end
#define WmfoAssertAndLogError(condition, msg) if (!(condition)) {WmfoLogError(msg);}
#define WmfoCheckBoolAndLogError(condition, msg) if (!(condition)) {WmfoLogError(msg);}
BOOL WmfoCheckOSStatusError(OSStatus error, const char *operation);
BOOL WmfoCheckOSStatusAndLogError(OSStatus error, NSString *format, ...);
void WmfoLogError(NSString *format, ...);
void WmfoErrorExceptionHandler(NSException *exception);
