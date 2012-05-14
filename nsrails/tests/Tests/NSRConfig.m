//
//  NSRConfig.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface SomeClass : NSRailsModel
@end

@implementation SomeClass
@end

@interface NSRConfig (private)

- (NSURLRequest *) HTTPRequestForRequestType:(NSString *)httpVerb requestBody:(NSString *)body url:(NSString *)route;

@end

@interface TNSRConfig : GHTestCase
@end


#define NSRAssertRelevantConfigURL(teststring,desc) NSRAssertEqualConfigs([NSRailsModel getRelevantConfig], teststring, desc, nil)


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
	
	GHAssertEqualStrings(@"some_class", [SomeClass masterModelName], @"auto-underscoring");
	
	NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"NoAuto"];
	c.autoinflectsClassNames = NO;
	[c useIn:
	 ^{
		 NSRAssertRelevantConfigURL(@"NoAuto", @"custom block ^{} block");
		 
		 GHAssertEqualStrings(@"SomeClass", [SomeClass masterModelName], @"No auto-underscoring");
	 }];
	
	NSRAssertRelevantConfigURL(@"Default", @"default exterior after all nesting");
}

- (void) test_environments
{
	[NSRConfig resetConfigs];
	
	NSRConfig *defaultDev = [NSRConfig defaultConfig];
	GHAssertNotNil(defaultDev, @"Calling defaultConfig should generate config if nil");
	
	[[NSRConfig defaultConfig] setAppURL:@"Default"];
	NSRAssertRelevantConfigURL(@"Default", nil);
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentDevelopment, @"Should've set default to dev environment");
	
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentProduction];
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Should've set environment to Prod");
	GHAssertNil([NSRConfig defaultConfig].appURL, @"App URL for Prod environment never set, should be nil.");
	
	[[NSRConfig defaultConfig] setAppURL:@"Prod"];
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Environment should still be Prod from before");
	NSRAssertRelevantConfigURL(@"Prod", @"Default URL set while in Prod, should have stuck");
	
	NSRConfig *testConfig = [NSRConfig configForEnvironment:@"test"];
	testConfig.appURL = @"TestURL";
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Environment still be Prod");
	NSRAssertRelevantConfigURL(@"Prod", @"Default URL set while in Prod, should have stuck");
	GHAssertNotNil(testConfig, @"Calling configForEnvironment: should generate a new config if non-existent");
	
	[NSRConfig setCurrentEnvironment:@"test"];
	GHAssertEqualStrings([NSRConfig currentEnvironment], @"test", @"Environment should be test");
	NSRAssertRelevantConfigURL(@"TestURL", @"Default URL should be one set for test");
	
	NSRConfig *newProd = [[NSRConfig alloc] initWithAppURL:@"NewProdURL"];
	[NSRConfig setConfig:newProd asDefaultForEnvironment:NSRConfigEnvironmentProduction];
	GHAssertEqualStrings([NSRConfig currentEnvironment], @"test", @"Environment should still be test");
	NSRAssertRelevantConfigURL(@"TestURL", @"Default URL should be one set for test");
	NSRAssertEqualConfigs([NSRConfig configForEnvironment:NSRConfigEnvironmentProduction], @"NewProdURL", @"Production environment config should change after overwriting its default", nil);
	
	//set it default for current env too (test)
	[NSRConfig setConfigAsDefault:newProd];
	NSRAssertRelevantConfigURL(@"NewProdURL", @"Default URL should be the new one set for prod");
	
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentDevelopment];
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentDevelopment, @"Environment should have been set to Dev");
	NSRAssertRelevantConfigURL(@"Default", @"Default URL should be one set for Dev");
}

- (void) test_date_conversion
{
	NSString *mockDatetime = [MockServer datetime];
	
	//Default Rails format
	
	//string -> date
	NSDate *date = [[NSRConfig defaultConfig] dateFromString:mockDatetime];
	GHAssertNotNil(date, @"String -> date conversion failed (default format)");
	
	//date -> string
	NSString *string = [[NSRConfig defaultConfig] stringFromDate:date];
	GHAssertNotNil(string, @"Date -> string conversion failed (default format)");
	GHAssertEqualStrings(string, mockDatetime, @"Date -> string conversion didn't return same result from server");
	
	
	//If format changes...
	[[NSRConfig defaultConfig] setDateFormat:@"yyyy"];
	
	//string -> date
	GHAssertThrowsSpecificNamed([[NSRConfig defaultConfig] dateFromString:mockDatetime], NSException, NSRailsDateConversionException, @"Should throw exception - receiving config format != server format");

	//date -> string
	NSString *string2 = [[NSRConfig defaultConfig] stringFromDate:date];
	GHAssertNotEqualStrings(string2, mockDatetime, @"Datetime string sent and datetime string server accepts should not be equal. (format mismatch)");
}

- (void) test_error_detection
{	
	// 404 Not Found
	
	for (int i = 0; i < [MockServer fullErrors].count; i++)
	{
		NSString *fullError = [[MockServer fullErrors] objectAtIndex:i];
		NSString *shortError = [[MockServer shortErrors] objectAtIndex:i];
		
		//Test with succinct (default)
		[[NSRConfig defaultConfig] setSuccinctErrorMessages:YES];
			
		NSError *error = [[NSRConfig defaultConfig] errorForResponse:fullError statusCode:400];
		GHAssertEqualStrings([error domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
		GHAssertTrue([[[error userInfo] objectForKey:NSLocalizedDescriptionKey] isEqualToString:shortError], @"Succinct message extraction failed for short message: `%@`",shortError);
		GHAssertNil([[error userInfo] objectForKey:NSRValidationErrorsKey], @"Validation errors dict should not have been created for 404");

		//Test without succinct
		[[NSRConfig defaultConfig] setSuccinctErrorMessages:NO];

		NSError *error2 = [[NSRConfig defaultConfig] errorForResponse:fullError statusCode:400];
		GHAssertEqualStrings([error2 domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
		GHAssertTrue([[[error2 userInfo] objectForKey:NSLocalizedDescriptionKey] isEqualToString:fullError], @"NO succinct error messages failed (bad!)");
		GHAssertNil([[error2 userInfo] objectForKey:NSRValidationErrorsKey], @"Validation errors dict should not have been created for 404");
	}
	
	// 422 Validation
		
	NSError *valError = [[NSRConfig defaultConfig] errorForResponse:[MockServer validation422Error] statusCode:422];
	GHAssertTrue([valError code] == 422, @"422 was returned, not picked up by config");
	GHAssertEqualStrings([valError domain], NSRRemoteErrorDomain, @"Succinct error messages failed");

	id valDict = [[valError userInfo] objectForKey:NSRValidationErrorsKey];
	GHAssertNotNil(valDict, @"Validation errors dict not compiled");
	GHAssertTrue([valDict isKindOfClass:[NSDictionary class]], @"Object for validation key needs to be a dict");
	GHAssertTrue([[[valDict allKeys] lastObject] isKindOfClass:[NSString class]], @"Keys in val dict need to be a string");
	GHAssertTrue([[[valDict allValues] lastObject] isKindOfClass:[NSArray class]], @"Object in validation dict needs to be an array");
	GHAssertTrue([[[[valDict allValues] lastObject] lastObject] isKindOfClass:[NSString class]], @"Object in array in validation dict needs to be a string");


	// 200 OK
	
	NSError *noError = [[NSRConfig defaultConfig] errorForResponse:[MockServer ok200] statusCode:200];
	GHAssertNil(noError, @"There should be no error for status code 200");
	
	// 201 Created
	
	NSError *noError2 = [[NSRConfig defaultConfig] errorForResponse:[MockServer creation201] statusCode:201];
	GHAssertNil(noError, @"There should be no error for status code 201");
}

- (void) test_http_requests
{
	/* No user/pass */
	
	NSString *url = @"http://localhost:3000/";
	[[NSRConfig defaultConfig] setAppURL:url];
	
	NSURLRequest *request = [[NSRConfig defaultConfig] HTTPRequestForRequestType:@"POST"
																	 requestBody:@"body"
																			 url:url];
	
	GHAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no user/pass");
	GHAssertEqualStrings([request HTTPMethod], @"POST", @"HTTP Methods mismatch");
	GHAssertEqualStrings([[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding], @"body", @"HTTP bodies mismatch");
	GHAssertEqualStrings([[request URL] description], url, @"Keeps the URL");
		
	
	/* User/pass */

	[[NSRConfig defaultConfig] setAppPassword:@"password"];
	NSURLRequest *request2 = [[NSRConfig defaultConfig] HTTPRequestForRequestType:@"POST"
																	  requestBody:@"body"
																			  url:nil];
	GHAssertNil([request2 valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no password");

	
	[[NSRConfig defaultConfig] setAppPassword:nil];
	[[NSRConfig defaultConfig] setAppUsername:@"username"];
	NSURLRequest *request3 = [[NSRConfig defaultConfig] HTTPRequestForRequestType:@"POST"
																	  requestBody:@"body"
																			  url:nil];
	GHAssertNil([request3 valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no username");
	
	
	[[NSRConfig defaultConfig] setAppPassword:@"password"];
	NSURLRequest *request4 = [[NSRConfig defaultConfig] HTTPRequestForRequestType:@"POST"
																	  requestBody:@"body"
																			  url:nil];
	GHAssertNotNil([request4 valueForHTTPHeaderField:@"Authorization"], @"Should send w/authorization if username+password");

}

- (void) test_authentication_and_url
{
	NSError *e = nil;
	
	GHAssertThrowsSpecificNamed([[NSRConfig defaultConfig] makeRequest:@"GET" requestBody:nil route:@"posts.json" sync:&e orAsync:nil], NSException, NSRailsMissingURLException, @"Should fail on no app URL set in config, where's the error?");

	e = nil;
	
	//point app to localhost as it should be, but no authentication
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
	[[NSRConfig defaultConfig] setAppUsername:nil];
	[[NSRConfig defaultConfig] setAppPassword:nil];
	
	NSString *index = [[NSRConfig defaultConfig] makeRequest:@"GET" requestBody:nil route:@"posts.json" sync:&e orAsync:nil];
	
	GHAssertNotNil(e, @"Should fail on not authenticated, where's the error?");
	GHAssertNil(index, @"Response should be nil because there was an authentication error");
	
	e = nil;
	
	//add authentication
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	index = [[NSRConfig defaultConfig] makeRequest:@"GET" requestBody:nil route:@"posts.json" sync:&e orAsync:nil];
	GHAssertNil(e, @"Authenticated, should be no error");
	GHAssertNotNil(index, @"Authenticated, reponse should be present");
	
	e = nil;
	
	//test error domain
	[[NSRConfig defaultConfig] makeRequest:@"GET" requestBody:nil route:@"///missing" sync:&e orAsync:nil];
	GHAssertTrue(e.domain == NSRRemoteErrorDomain, @"Server error should have NSRRemoteErrorDomain");
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