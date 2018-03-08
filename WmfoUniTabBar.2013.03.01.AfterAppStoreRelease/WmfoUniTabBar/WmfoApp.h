//
//  WmfoApp.h
//  WmfoUniTabBar
//
//  Created by Edward Beuchert on 1/8/13.
//  Copyright (c) 2013 Edward Beuchert. All rights reserved.
//

#ifndef WmfoUniTabBar_WmfoApp_h
#define WmfoUniTabBar_WmfoApp_h

#import <UIKit/UIKit.h>

@class MattGallagherAudioStreamer;
@class WmfoAppDelegate;
@class WmfoMainIPadViewController;
@class WmfoMainIPhoneViewController;
@class WmfoSpinitronViewController;
@class WmfoSharedWebViewController;

#define WMFOAPP_SHOW_MEMORY_USAGE FALSE

typedef enum WmfoViewType {
    WmfoViewTypeFullPlaylist,
    WmfoViewTypeWmfoWebsite,
    WmfoViewTypeVideos,
    WmfoViewTypeTwitter,
    WmfoViewTypeAbout,
    WmfoViewTypeSettings,
    WmfoViewTypeMainIPhone
} WmfoViewType;


#import "WmfoError.h"
#import "WmfoUtil.h"
#import "MattGallagherAudioStreamer.h"
#import "WmfoPlayButton.h"
#import "WmfoAppDelegate.h"
#import "WmfoMainIPadViewController.h"
#import "WmfoMainIPhoneViewController.h"
#import "WmfoSettingsViewController.h"
#import "WmfoSharedWebViewController.h"
#import "WmfoSpinitronViewController.h"
#import "WmfoTwitterViewController.h"
#import "WmfoHomeViewController.h"
#import "WmfoVideosViewController.h"
#import "WmfoAboutViewController.h"

#define kWmfoNumBytesPerMB (1048576)

#define kUserDefaultKey_Volume @"WmfoUniTabBar_UserDefaultKey_Volume"
#define kUserDefaultKey_WebcastUrlStreamIndex @"WmfoUniTabBar_UserDefaultKey_WebcastUrlStreamIndex"
#define kUserDefaultKey_WebcastUrlStreamCustom @"WmfoUniTabBar_UserDefaultKey_WebcastUrlStreamCustom"
#define kUserDefaultKey_TabBarOrder @"WmfoUniTabBar_UserDefaultKey_TabBarOrder"

#define kWmfoTelephoneURL @"tel:+16176273800"

#define kBaseWebcastUrl_As_CString "http://wmfo-duke.orgs.tufts.edu"
#define kBaseWebcastUrl @kBaseWebcastUrl_As_CString
#define kWebcastUrlStreamHigh @kBaseWebcastUrl_As_CString":8000"
#define kWebcastUrlStreamMedium @kBaseWebcastUrl_As_CString":8002"
#define kWebcastUrlStreamLow @kBaseWebcastUrl_As_CString":8004"

#define kWebcastUrlStreamDefaultCustom kWebcastUrlStreamLow
#define kDefaultVolume (.75)
#define kDefaultWebcastUrlStreamIndex (0)

#define SIMULATE_SPINITRON_LOAD_ERROR 0

#define kSpinitronFullCurrentPlaylistUrl @"http://spinitron.com/public/index.php?station=wmfo&ptype=d&styles=body,a%7Bbackground:black;color:white;font-family:Helvetica;text-decoration:none%7D"
#define kSpinitronFullCurrentPlaylistErrorUrl @"http://spinitron_WRONGSITE.com/public/index.php?station=wmfo&ptype=d&styles=body,a%7Bbackground:black;color:white;font-family:Helvetica;text-decoration:none%7D"
//#define kSpinitronFullCurrentPlaylistUrl @"http://spinitron.com/public/index.php?station=wmfo&ptype=d&styles=body,a%7Bbackground:purple;color:orange;font-family:Helvetica;text-decoration:none%7D"
//#define kSpinitronFullCurrentPlaylistUrl @"http://spinitron.com/public/index.php?station=wmfo&ptype=d"
#define kWmfoWebsiteUrl @"http://wmfo.org"
//#define kWmfoWebsiteUrl @"http://tuftsfreeformradio.org"
//#define kVideosWebsiteUrl @"http://www.youtube.com/results?search_query=wmfo"
//#define kVideosWebsiteUrl @"http://m.youtube.com/results?search_query=wmfo"
#define kVideosWebsiteUrl @"http://m.youtube.com/tuftsfreeform"
#define kTwitterWebsiteUrl @"http://twitter.com/wmfodj"

//#define kSpinitronCurrentPlaylistUrl @"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:black;color:white;font-family:Helvetica;text-decoration:none%7D"
//#define kSpinitronCurrentPlaylistUrl @"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:purple;color:orange;font-family:Helvetica;text-decoration:none%7D"
//#define kSpinitronCurrentPlaylistUrl @"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:rgba(112, 22, 142, 1.0);color:white;font-family:Helvetica;text-decoration:none%7D"
//#define kSpinitronCurrentPlaylistUrl @"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:#710098;color:white;font-family:Helvetica;text-decoration:none%7D"
//#define kSpinitronCurrentPlaylistUrl @"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:transparent;color:white;font-family:Helvetica;text-decoration:none%7D"
//#define kSpinitronCurrentPlaylistUrl @"http://spinitronXXX.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:transparent;color:gold;font-family:Helvetica;text-decoration:none%7D"
#define kSpinitronCurrentPlaylistUrl @"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:transparent;color:gold;font-family:Helvetica;text-decoration:none%7D"
#define kSpinitronCurrentPlaylistErrorUrl @"http://spinitron_WRONGSITE.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:transparent;color:gold;font-family:Helvetica;text-decoration:none%7D"
#define kSpinitronCurrentSongRefreshIntervalInSeconds (60.0)
#define kSpinitronCurrentFullPlaylistRefreshIntervalInSeconds (60.0)
#define kSpinitronCurrentSongWebViewFailLoadErrorMsg @"Could not retrieve current song data."
#if 0
//url = [NSURL URLWithString:@"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a{background:%20green}"];
//url = [NSURL URLWithString:@"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground:%20green%7D"];
//url = [NSURL URLWithString:@"http://spinitron.com/public/newestsong.php?station=wmfo&num=5"];
//url = [NSURL URLWithString:@"http://spinitron.com/public/newestsong.php?station=wmfo"];
//url = [NSURL URLWithString:@"http%3A%2F%2Fspinitron.com%2Fpublic%2Fnewestsong.php%3Fstation%3Dwxyz%26styles%3Dbody%2Ca%7Bbackground%3A+black%3Bcolor%3Awhite%7D"];
//url = [NSURL URLWithString:@"http://spinitron.com/public/newestsong.php?station=wmfo&styles=body,a%7Bbackground%3A%2520green%7D"];
#endif

#define kNetworkNotAvailableErrorMsg @"Could not access network. Please check that Airplane mode is turned off and that you are in range of a Wi-Fi or cellular network."
#define kWebViewFailLoadErrorMsg @"Could not load content from web site: "

#endif
