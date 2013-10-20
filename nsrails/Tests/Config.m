//
//  Config.m
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRAsserts.h"

extern NSString * const NSRRails3DateFormat;
extern NSString * const NSRRails4DateFormat;

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
    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion3];

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
	
	NSString *string3 = [[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:100000]];
	STAssertEqualObjects(string3, @"1970", @"Datetime string should be formatted to 'yyyy'");
	
	//invalid date format
	[[NSRConfig defaultConfig] setDateFormat:@"!@#@$"];

	STAssertEqualObjects([[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]], @"!@#@$", @"New format should've been applied");
}

- (void) test_rails_versions
{
    //rails 4 should be the default rails configuration
    
    NSString *df3 = NSRRails3DateFormat;
    NSString *um3 = @"PUT";

    NSString *df4 = NSRRails4DateFormat;
    NSString *um4 = @"PATCH";

    STAssertEqualObjects([NSRConfig defaultConfig].dateFormat, df4, nil);
    STAssertEqualObjects([NSRConfig defaultConfig].updateMethod, um4, nil);

    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion3];
    STAssertEqualObjects([NSRConfig defaultConfig].dateFormat, df3, nil);
    STAssertEqualObjects([NSRConfig defaultConfig].updateMethod, um3, nil);
    
    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion4];
    STAssertEqualObjects([NSRConfig defaultConfig].dateFormat, df4, nil);
    STAssertEqualObjects([NSRConfig defaultConfig].updateMethod, um4, nil);
}

@end

