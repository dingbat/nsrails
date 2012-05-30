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
	
	STAssertEqualObjects(@"some_class", [SomeClass masterModelName], @"auto-underscoring");
	
	NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"NoAuto"];
	c.autoinflectsClassNames = NO;
	[c useIn:
	 ^{
		 NSRAssertRelevantConfigURL(@"NoAuto", @"custom block ^{} block");
		 
		 STAssertEqualObjects(@"SomeClass", [SomeClass masterModelName], @"No auto-underscoring");
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

- (void) test_completion_block_threads
{
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];

	[[NSRConfig defaultConfig] setPerformsCompletionBlocksOnMainThread:YES];
	
	[[NSRConfig defaultConfig] makeRequest:@"GET" requestBody:nil route:@"posts.json" sync:nil orAsync:
	 ^(id result, NSError *error)
	 {
		 STAssertTrue([NSThread isMainThread], @"With PCBOMT enabled, should run block in main thread");	
		 
		 //do the second test inside the block so they don't overwrite each other
		 
		 [[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
		 [[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
		 [[NSRConfig defaultConfig] setAppPassword:@"iphone"];

		 [[NSRConfig defaultConfig] setPerformsCompletionBlocksOnMainThread:NO];
		 
		 [[NSRConfig defaultConfig] makeRequest:@"GET" requestBody:nil route:@"posts.json" sync:nil orAsync:
		  ^(id result, NSError *error)
		  {
			  STAssertFalse([NSThread isMainThread], @"With PCBOMT disabled, should run block in same thread");		 
		  }];
	 }];
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

- (void) test_error_detection
{	
	// 404 Not Found
	
	for (int i = 0; i < [MockServer fullErrors].count; i++)
	{
		NSString *fullError = [[MockServer fullErrors] objectAtIndex:i];
		NSString *shortError = [[MockServer shortErrors] objectAtIndex:i];
		NSInteger code = [[[MockServer statusCodes] objectAtIndex:i] integerValue];
		
		//Test with succinct (default)
		[[NSRConfig defaultConfig] setSuccinctErrorMessages:YES];
			
		NSError *error = [[NSRConfig defaultConfig] errorForResponse:fullError statusCode:code];
		STAssertEqualObjects([error domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
		STAssertTrue([[[error userInfo] objectForKey:NSLocalizedDescriptionKey] isEqualToString:shortError], @"Succinct message extraction failed for short message: `%@` (is %@)",shortError, [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
		STAssertNil([[error userInfo] objectForKey:NSRValidationErrorsKey], @"Validation errors dict should not have been created for 404");

		//Test without succinct
		[[NSRConfig defaultConfig] setSuccinctErrorMessages:NO];

		NSError *error2 = [[NSRConfig defaultConfig] errorForResponse:fullError statusCode:code];
		STAssertEqualObjects([error2 domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
		STAssertTrue([[[error2 userInfo] objectForKey:NSLocalizedDescriptionKey] isEqualToString:fullError], @"NO succinct error messages failed (bad!)");
		STAssertNil([[error2 userInfo] objectForKey:NSRValidationErrorsKey], @"Validation errors dict should not have been created for 404");
	}
	
	// 422 Validation
	
	NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[[MockServer validation422Error] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
	
	NSError *valError = [[NSRConfig defaultConfig] errorForResponse:response statusCode:422];
	STAssertTrue([valError code] == 422, @"422 was returned, not picked up by config");
	STAssertEqualObjects([valError domain], NSRRemoteErrorDomain, @"Succinct error messages failed");

	id valDict = [[valError userInfo] objectForKey:NSRValidationErrorsKey];
	STAssertNotNil(valDict, @"Validation errors dict not compiled");
	STAssertTrue([valDict isKindOfClass:[NSDictionary class]], @"Object for validation key needs to be a dict");
	STAssertTrue([[[valDict allKeys] lastObject] isKindOfClass:[NSString class]], @"Keys in val dict need to be a string");
	STAssertTrue([[[valDict allValues] lastObject] isKindOfClass:[NSArray class]], @"Object in validation dict needs to be an array");
	STAssertTrue([[[[valDict allValues] lastObject] lastObject] isKindOfClass:[NSString class]], @"Object in array in validation dict needs to be a string");


	// 200 OK
	
	NSError *noError = [[NSRConfig defaultConfig] errorForResponse:[MockServer ok200] statusCode:200];
	STAssertNil(noError, @"There should be no error for status code 200");
	
	// 201 Created
	
	NSError *noError2 = [[NSRConfig defaultConfig] errorForResponse:[MockServer creation201] statusCode:201];
	STAssertNil(noError, @"There should be no error for status code 201");
}

- (void) test_http_requests
{
	/* No user/pass */
	
	NSString *url = @"http://localhost:3000/";
	[[NSRConfig defaultConfig] setAppURL:url];
	
	NSDictionary *body = NSRDictionary(@"body", @"test");
	
	NSURLRequest *request = [[NSRConfig defaultConfig] HTTPRequestForRequestType:@"POST"
																	 requestBody:body
																			 url:url];
	
	STAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no user/pass");
	STAssertEqualObjects([request HTTPMethod], @"POST", @"HTTP Methods mismatch");
	STAssertEqualObjects([[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding], @"{\"test\":\"body\"}", @"HTTP bodies mismatch");
	STAssertEqualObjects([[request URL] description], url, @"Keeps the URL");
		
	
	/* User/pass */

	[[NSRConfig defaultConfig] setAppPassword:@"password"];
	NSURLRequest *request2 = [[NSRConfig defaultConfig] HTTPRequestForRequestType:@"POST"
																	  requestBody:nil
																			  url:nil];
	STAssertNil([request2 valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no password");

	
	[[NSRConfig defaultConfig] setAppPassword:nil];
	[[NSRConfig defaultConfig] setAppUsername:@"username"];
	NSURLRequest *request3 = [[NSRConfig defaultConfig] HTTPRequestForRequestType:@"POST"
																	  requestBody:nil
																			  url:nil];
	STAssertNil([request3 valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no username");
	
	
	[[NSRConfig defaultConfig] setAppPassword:@"password"];
	NSURLRequest *request4 = [[NSRConfig defaultConfig] HTTPRequestForRequestType:@"POST"
																	  requestBody:nil
																			  url:nil];
	STAssertNotNil([request4 valueForHTTPHeaderField:@"Authorization"], @"Should send w/authorization if username+password");
}

- (void)setUpClass
{
	// Run at start of all tests in the class
}

- (void)tearDownClass {
	// Run at end of all tests in the class
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