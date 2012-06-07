//
//  NSRConfig.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface SomeClass : NSRRemoteObject
@end

@implementation SomeClass
@end

@interface NSRConfig (private)

- (NSURLRequest *) HTTPRequestForRequestType:(NSString *)httpVerb requestBody:(id)body url:(NSString *)route;

@end

@interface TNSRConfig : SenTestCase
@end


#define NSRAssertRelevantConfigURL(string,desc) NSRAssertEqualConfigs([NSRRemoteObject getRelevantConfig], string, desc, nil)


@implementation TNSRConfig

- (void) test_nested_contexts
{
	[[NSRConfig defaultConfig] setAppURL:@"Default"];
	
	NSRAssertRelevantConfigURL(@"Default", @"default, exterior before nesting");
	
	[[NSRConfig defaultConfig] useIn:^
	 {
		 NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"Nested"];
		 [c use];
		 
		 NSRAssertRelevantConfigURL(@"Nested", @"[use] nested inside of default block");
		 
		 [[NSRConfig defaultConfig] useIn:^
		  {
			  NSRAssertRelevantConfigURL(@"Default", @"default block nested inside [use] inside default block");
			  
			  [c useIn:^
			   {
				   NSRAssertRelevantConfigURL(@"Nested", @"triple nested");
			   }];
		  }];
		 
		 [c end];
		 
		 NSRAssertRelevantConfigURL(@"Default", @"default at the end of default block after nestings");
	 }];
	
	STAssertEqualObjects(@"some_class", [SomeClass remoteModelName], @"auto-underscoring");
	
	NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"NoAuto"];
	c.autoinflectsClassNames = NO;
	[c useIn:
	 ^{
		 NSRAssertRelevantConfigURL(@"NoAuto", @"custom block ^{} block");
		 
		 STAssertEqualObjects(@"SomeClass", [SomeClass remoteModelName], @"No auto-underscoring");
	 }];
	
	NSRAssertRelevantConfigURL(@"Default", @"default exterior after all nesting");
}

- (void) test_environments
{
	[NSRConfig resetConfigs];
	
	NSRConfig *defaultDev = [NSRConfig defaultConfig];
	STAssertNotNil(defaultDev, @"Calling defaultConfig should generate config if nil");
	
	[[NSRConfig defaultConfig] setAppURL:@"Default"];
	NSRAssertRelevantConfigURL(@"Default", nil);
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentDevelopment, @"Should've set default to dev environment");
	
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentProduction];
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Should've set environment to Prod");
	STAssertNil([NSRConfig defaultConfig].appURL, @"App URL for Prod environment never set, should be nil.");
	
	[[NSRConfig defaultConfig] setAppURL:@"Prod"];
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Environment should still be Prod from before");
	NSRAssertRelevantConfigURL(@"Prod", @"Default URL set while in Prod, should have stuck");
	
	NSRConfig *testConfig = [NSRConfig configForEnvironment:@"test"];
	testConfig.appURL = @"TestURL";
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Environment still be Prod");
	NSRAssertRelevantConfigURL(@"Prod", @"Default URL set while in Prod, should have stuck");
	STAssertNotNil(testConfig, @"Calling configForEnvironment: should generate a new config if non-existent");
	
	[NSRConfig setCurrentEnvironment:@"test"];
	STAssertEqualObjects([NSRConfig currentEnvironment], @"test", @"Environment should be test");
	NSRAssertRelevantConfigURL(@"TestURL", @"Default URL should be one set for test");
	
	NSRConfig *newProd = [[NSRConfig alloc] initWithAppURL:@"NewProdURL"];
	[newProd useAsDefaultForEnvironment:NSRConfigEnvironmentProduction];
	STAssertEqualObjects([NSRConfig currentEnvironment], @"test", @"Environment should still be test");
	NSRAssertRelevantConfigURL(@"TestURL", @"Default URL should be one set for test");
	NSRAssertEqualConfigs([NSRConfig configForEnvironment:NSRConfigEnvironmentProduction], @"NewProdURL", @"Production environment config should change after overwriting its default", nil);
	
	//set it default for current env too (test)
	[newProd useAsDefault];
	NSRAssertRelevantConfigURL(@"NewProdURL", @"Default URL should be the new one set for prod");
	
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentDevelopment];
	STAssertEqualObjects([NSRConfig currentEnvironment], NSRConfigEnvironmentDevelopment, @"Environment should have been set to Dev");
	NSRAssertRelevantConfigURL(@"Default", @"Default URL should be one set for Dev");
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
	STAssertThrowsSpecificNamed([[NSRConfig defaultConfig] dateFromString:mockDatetime], NSException, NSRInternalError, @"Should throw exception - receiving config format != server format");

	//date -> string
	NSString *string2 = [[NSRConfig defaultConfig] stringFromDate:date];
	STAssertFalse([string2 isEqualToString:mockDatetime], @"Datetime string sent and datetime string server accepts should not be equal. (format mismatch)");
	
	NSString *string3 = [[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]];
	STAssertEqualObjects(string3, @"1969", @"Datetime string should be formatted to 'yyyy'");
}

- (void) test_class_attachment
{
	NSRAssertEqualConfigs([[SomeClass propertyCollection] customConfig], nil, @"", nil);
	
	[[NSRConfig defaultConfig] setAppURL:@"def"];
	NSRAssertRelevantConfigURL(@"def", nil);
	
	NSRAssertEqualConfigs([[SomeClass propertyCollection] customConfig], nil, @"def", nil);

	[[[NSRConfig alloc] initWithAppURL:@"something"] useForClass:[SomeClass class]];
	NSRAssertRelevantConfigURL(@"def", nil);
	
	NSRAssertEqualConfigs([[SomeClass propertyCollection] customConfig], @"something", @"def", nil);

	NSRAssertRelevantConfigURL(@"def", nil);
}

- (void)setUp
{
	[NSRConfig resetConfigs];

	// Run before each test method
}

- (void)tearDown {
	// Run after each test method
}

@end