//
//  Config.m
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRAsserts.h"

@interface Config : SenTestCase

@end

#define NSRAssertRelevantConfigURL(string) \
STAssertEqualObjects(string, [NSRConfig contextuallyRelevantConfig].appURL, nil)

@implementation Config

- (void) setUp
{
	[NSRConfig resetConfigs];
}

- (void) test_nested_contexts
{
	[[NSRConfig defaultConfig] setAppURL:@"Default"];
	
	NSRAssertRelevantConfigURL(@"Default");
	
	[[NSRConfig defaultConfig] useIn:^
	 {
		 NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"Nested"];
		 [c use];
		 
		 NSRAssertRelevantConfigURL(@"Nested");
		 
		 [[NSRConfig defaultConfig] useIn:^
		  {
			  NSRAssertRelevantConfigURL(@"Default");
			  
			  [c useIn:^
			   {
				   NSRAssertRelevantConfigURL(@"Nested");
			   }];
		  }];
		 
		 [c end];
		 
		 NSRAssertRelevantConfigURL(@"Default");
	 }];
	
	STAssertEqualObjects(@"custom_coder", [CustomCoder remoteModelName], @"auto-underscoring");
	
	NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"NoAuto"];
	c.autoinflectsClassNames = NO;
	[c useIn:
	 ^{
		 NSRAssertRelevantConfigURL(@"NoAuto");
		 
		 STAssertEqualObjects(@"CustomCoder", [CustomCoder remoteModelName], @"No auto-underscoring");
	 }];
	
	NSRAssertRelevantConfigURL(@"Default");
}

- (void) test_date_conversion
{
	NSString *mockDatetime = [MockServer datetime];
	
	//Default Rails format
	
	//string -> date
	NSDate *date = [[NSRConfig defaultConfig] dateFromString:mockDatetime];
	STAssertNotNil(date, @"String -> date conversion failed (default format)");
	
	//date -> string
	NSString *string = [[NSRConfig defaultConfig] stringFromDate:date];
	STAssertNotNil(string, @"Date -> string conversion failed (default format)");
	STAssertEqualObjects(string, mockDatetime, @"Date -> string conversion didn't return same result from server");
	
	
	//If format changes...
	[[NSRConfig defaultConfig] setDateFormat:@"yyyy"];
	
	//string -> date
	STAssertNil([[NSRConfig defaultConfig] dateFromString:mockDatetime], @"Should be nil - receiving config format != server format");
	
	//date -> string
	NSString *string2 = [[NSRConfig defaultConfig] stringFromDate:date];
	STAssertFalse([string2 isEqualToString:mockDatetime], @"Datetime string sent and datetime string server accepts should not be equal. (format mismatch)");
	
	NSString *string3 = [[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:100]];
	STAssertEqualObjects(string3, @"1970", @"Datetime string should be formatted to 'yyyy'");
	
	//invalid date format
	[[NSRConfig defaultConfig] setDateFormat:@"!@#@$"];

	STAssertEqualObjects([[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]], @"!@#@$", @"New format should've been applied");
}

@end

