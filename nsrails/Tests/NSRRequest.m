//
//  NSRRequest.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface TNSRRequest : SenTestCase
@end

@implementation TNSRRequest

- (void) test_completion_block_threads
{
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];

	[[NSRConfig defaultConfig] setPerformsCompletionBlocksOnMainThread:YES];
	
	NSRRequest *request = [[NSRRequest alloc] init];
	request.httpMethod = @"GET";
	request.route = @"posts";
	
	[request sendAsynchronous:
	 ^(id jsonRep, NSError *error) 
	 {
		 STAssertTrue([NSThread isMainThread], @"With PCBOMT enabled, should run block in main thread");	
		 
		 //do the second test inside the block so they don't overwrite each other
		 
		 [[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
		 [[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
		 [[NSRConfig defaultConfig] setAppPassword:@"iphone"];
		 
		 [[NSRConfig defaultConfig] setPerformsCompletionBlocksOnMainThread:NO];
		 
		 [request sendAsynchronous:
		  ^(id jsonRep, NSError *error) 
		  {
			  STAssertFalse([NSThread isMainThread], @"With PCBOMT disabled, should run block in same thread");		 
		  }];
	 }];
}

- (void) test_error_detection
{	
	NSRRequest *r = [[NSRRequest alloc] init];

	// 404 Not Found
	
	for (int i = 0; i < [MockServer fullErrors].count; i++)
	{
		NSString *fullError = [[MockServer fullErrors] objectAtIndex:i];
		NSString *shortError = [[MockServer shortErrors] objectAtIndex:i];
		NSInteger code = [[[MockServer statusCodes] objectAtIndex:i] integerValue];
		
		//Test with succinct (default)
		[[NSRConfig defaultConfig] setSuccinctErrorMessages:YES];
		
		NSError *error = [r errorForResponse:fullError statusCode:code];
		STAssertEqualObjects([error domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
		STAssertTrue([[[error userInfo] objectForKey:NSLocalizedDescriptionKey] isEqualToString:shortError], @"Succinct message extraction failed for short message: `%@` (is %@)",shortError, [error.userInfo objectForKey:NSLocalizedDescriptionKey]);
		STAssertNil([[error userInfo] objectForKey:NSRValidationErrorsKey], @"Validation errors dict should not have been created for 404");

		//Test without succinct
		[[NSRConfig defaultConfig] setSuccinctErrorMessages:NO];

		NSError *error2 = [r errorForResponse:fullError statusCode:code];
		STAssertEqualObjects([error2 domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
		STAssertTrue([[[error2 userInfo] objectForKey:NSLocalizedDescriptionKey] isEqualToString:fullError], @"NO succinct error messages failed (bad!)");
		STAssertNil([[error2 userInfo] objectForKey:NSRValidationErrorsKey], @"Validation errors dict should not have been created for 404");
	}
	
	// 422 Validation
	
	NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[[MockServer validation422Error] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
	
	NSError *valError = [r errorForResponse:response statusCode:422];
	STAssertTrue([valError code] == 422, @"422 was returned, not picked up by config");
	STAssertEqualObjects([valError domain], NSRRemoteErrorDomain, @"Succinct error messages failed");

	id valDict = [[valError userInfo] objectForKey:NSRValidationErrorsKey];
	STAssertNotNil(valDict, @"Validation errors dict not compiled");
	STAssertTrue([valDict isKindOfClass:[NSDictionary class]], @"Object for validation key needs to be a dict");
	STAssertTrue([[[valDict allKeys] lastObject] isKindOfClass:[NSString class]], @"Keys in val dict need to be a string");
	STAssertTrue([[[valDict allValues] lastObject] isKindOfClass:[NSArray class]], @"Object in validation dict needs to be an array");
	STAssertTrue([[[[valDict allValues] lastObject] lastObject] isKindOfClass:[NSString class]], @"Object in array in validation dict needs to be a string");


	// 200 OK
	
	NSError *noError = [r errorForResponse:[MockServer ok200] statusCode:200];
	STAssertNil(noError, @"There should be no error for status code 200");
	
	// 201 Created
	
	NSError *noError2 = [r errorForResponse:[MockServer creation201] statusCode:201];
	STAssertNil(noError, @"There should be no error for status code 201");
}

- (void) test_http_requests
{
	/* No user/pass */
	
	NSString *url = @"http://localhost:3000";
	[[NSRConfig defaultConfig] setAppURL:url];
	
	
	NSRRequest *req = [[NSRRequest alloc] init];
	req.httpMethod = @"POST";
	req.body = NSRDictionary(@"body", @"test");
	
	NSURLRequest *request = [req HTTPRequest];
	
	STAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no user/pass");
	STAssertEqualObjects([request HTTPMethod], @"POST", @"HTTP Methods mismatch");
	STAssertEqualObjects([[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding], @"{\"test\":\"body\"}", @"HTTP bodies mismatch");
	STAssertEqualObjects([[request URL] description], url, @"Keeps the URL");
		
	
	/* OAuth */
	
	for (int i = 0; i < 2; i++)
	{
		[NSRConfig defaultConfig].appOAuthToken = @"token123";
		request = [req HTTPRequest];
		
		STAssertEqualObjects([request valueForHTTPHeaderField:@"Authorization"], @"OAuth token123", @"Should send OAuth token");
			
		//should be identical if only one user/pass element is present (but still oauth)
		[[NSRConfig defaultConfig] setAppPassword:@"password"];
	}
	
	[NSRConfig defaultConfig].appOAuthToken = nil;

	/* User/pass */

	[[NSRConfig defaultConfig] setAppPassword:@"password"];
	request = [req HTTPRequest];
	STAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no password");
	
	
	[[NSRConfig defaultConfig] setAppPassword:nil];
	[[NSRConfig defaultConfig] setAppUsername:@"username"];
	request = [req HTTPRequest];
	STAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no username");
		
	
	[[NSRConfig defaultConfig] setAppPassword:@"password"];
	request = [req HTTPRequest];
	STAssertNotNil([request valueForHTTPHeaderField:@"Authorization"], @"Should send w/authorization if username+password");
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