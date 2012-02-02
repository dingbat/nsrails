//
//  NSRConfig.m
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRConfig.h"

@implementation NSRConfig
@synthesize appURL, appUsername, appPassword;

static NSRConfig *defaultConfig = nil;

+ (NSRConfig *) defaultConfig
{
	if (!defaultConfig) defaultConfig = [[NSRConfig alloc] init];
	return defaultConfig;
}

- (id) initWithAppURL:(NSString *)url
{
	if ((self = [super init]))
	{
		[self setAppURL:url];
	}
	return self;
}

- (void) setAppURL:(NSString *)str
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

@end
