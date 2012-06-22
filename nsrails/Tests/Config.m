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

#define NSRAssertRelevantClassConfigURL(class, string) \
NSRAssertEqualConfigs([NSRConfig relevantConfigForClass:class], string, nil)

#define NSRAssertRelevantConfigURL(string) \
NSRAssertRelevantClassConfigURL(nil, string)

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

- (void) test_environments
{
	NSRConfig *defaultDev = [NSRConfig defaultConfig];
	STAssertNotNil(defaultDev, @"Calling defaultConfig should generate config if nil");
	
	[[NSRConfig defaultConfig] setAppURL:@"Default"];
	NSRAssertRelevantConfigURL(@"Default");
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentDevelopment, @"Should've set default to dev environment");
	
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentProduction];
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Should've set environment to Prod");
	STAssertNil([NSRConfig defaultConfig].appURL, @"App URL for Prod environment never set, should be nil.");
	
	[[NSRConfig defaultConfig] setAppURL:@"Prod"];
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Environment should still be Prod from before");
	NSRAssertRelevantConfigURL(@"Prod");
	
	NSRConfig *testConfig = [NSRConfig configForEnvironment:@"test"];
	testConfig.appURL = @"TestURL";
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Environment still be Prod");
	NSRAssertRelevantConfigURL(@"Prod");
	STAssertNotNil(testConfig, @"Calling configForEnvironment: should generate a new config if non-existent");
	
	[NSRConfig setCurrentEnvironment:@"test"];
	STAssertEqualObjects([NSRConfig currentEnvironment], @"test", @"Environment should be test");
	NSRAssertRelevantConfigURL(@"TestURL");
	
	NSRConfig *newProd = [[NSRConfig alloc] initWithAppURL:@"NewProdURL"];
	[newProd useAsDefaultForEnvironment:NSRConfigEnvironmentProduction];
	STAssertEqualObjects([NSRConfig currentEnvironment], @"test", @"Environment should still be test");
	NSRAssertRelevantConfigURL(@"TestURL");
	NSRAssertEqualConfigs([NSRConfig configForEnvironment:NSRConfigEnvironmentProduction], @"NewProdURL", @"Production environment config should change after overwriting its default", nil);
	
	//set it default for current env too (test)
	[newProd useAsDefault];
	NSRAssertRelevantConfigURL(@"NewProdURL");
	
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentDevelopment];
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentDevelopment, @"Environment should have been set to Dev");
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
	
	NSString *string3 = [[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]];
	STAssertEqualObjects(string3, @"1969", @"Datetime string should be formatted to 'yyyy'");
	
	//invalid date format
	[[NSRConfig defaultConfig] setDateFormat:@"!@#@$"];

	STAssertEqualObjects([[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]], @"!@#@$", @"New format should've been applied");
}

- (void) test_class_attachment
{
	NSRAssertRelevantClassConfigURL([Tester class], nil);
	NSRAssertRelevantConfigURL(nil);
	STAssertEquals([NSRConfig relevantConfigForClass:[Tester class]], [NSRConfig defaultConfig], nil);
	
	[[NSRConfig defaultConfig] setAppURL:@"def"];
	NSRAssertRelevantConfigURL(@"def");
	STAssertEquals([NSRConfig relevantConfigForClass:[Tester class]], [NSRConfig defaultConfig], nil);
	
	NSRConfig *someConfig = [[NSRConfig alloc] initWithAppURL:@"something"];
	[someConfig useForClass:[Tester class]];
	NSRAssertRelevantConfigURL(@"def");
	NSRAssertRelevantClassConfigURL([Tester class], @"something");
	STAssertEquals([NSRConfig relevantConfigForClass:[Tester class]], someConfig, nil);
}

@end

