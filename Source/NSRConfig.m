//
//  NSRConfig.m
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRConfig.h"

@implementation NSRConfig

static NSString* appURL;
static NSString* appUsername;
static NSString* appPassword;

+ (void) setAppURL:(NSString *)str
{
	//get rid of trailing /
	if ([[str substringFromIndex:str.length-1] isEqualToString:@"/"])
		str = [str substringToIndex:str.length-1];
	
	//add http:// if not included already
	NSString *http = (str.length < 7 ? nil : [str substringToIndex:7]);
	if (![http isEqualToString:@"http://"] && ![http isEqualToString:@"https:/"])
	{
		str = [@"http://" stringByAppendingString:str];
	}
	
	appURL = str;
}
+ (void) setAppUsername:(NSString *)str {	appUsername = str;	}
+ (void) setAppPassword:(NSString *)str {	appPassword = str;	}

+ (NSString *) appURL { return appURL; }
+ (NSString *) appUsername { return appUsername; }
+ (NSString *) appPassword { return appPassword; }

@end
