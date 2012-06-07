//
//  NSRRequest.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface NormalClass : NSRRemoteObject
@end

@implementation NormalClass
@end

@interface CustomClass : NSRRemoteObject
@end

@implementation CustomClass
NSRUseModelName(@"custom");
@end

@interface PrefixClass : NSRRemoteObject
@property (nonatomic, strong) NormalClass *normal;
@end

@implementation PrefixClass
@synthesize normal;
NSRUseResourcePrefix(normal);
NSRUseModelName(@"pref");
@end


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
	
	req.config = [[NSRConfig alloc] initWithAppURL:@"http://CUSTOM"];
		
	request = [req HTTPRequest];
	STAssertEqualObjects([[request URL] description], @"http://CUSTOM", @"Uses custom config");

	req.config = nil;
	
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

- (void) test_routing
{
	NSRRequest *request = [[NSRRequest alloc] init];
	
	[request routeTo:@"hi"];
	STAssertEqualObjects(request.route, @"hi", nil);
	
	/* NORMAL */
	
	//class
	[request routeToClass:[NormalClass class]];	
	STAssertEqualObjects(request.route, @"normal_classes", nil);
	
	[request routeToClass:[NormalClass class] withCustomMethod:@"action"];
	STAssertEqualObjects(request.route, @"normal_classes/action", nil);
	
	//object (no id)
	[request routeToObject:[[NormalClass alloc] init]];	
	STAssertEqualObjects(request.route, @"normal_classes", nil);
	
	[request routeToObject:[[NormalClass alloc] init] withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"normal_classes/action", nil);
	
	//object (id)
	NSDictionary *idDict = NSRDictionary(NSRNumber(1), @"id");
	
	[request routeToObject:[[NormalClass alloc] initWithRemoteDictionary:idDict]];	
	STAssertEqualObjects(request.route, @"normal_classes/1", nil);
	
	[request routeToObject:[[NormalClass alloc] initWithRemoteDictionary:idDict] withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"normal_classes/1/action", nil);
	
	
	/* CUSTOM */
	
	//class
	[request routeToClass:[CustomClass class]];	
	STAssertEqualObjects(request.route, @"customs", nil);
	
	[request routeToClass:[CustomClass class] withCustomMethod:@"action"];
	STAssertEqualObjects(request.route, @"customs/action", nil);
	
	//object (no id)
	[request routeToObject:[[CustomClass alloc] init]];	
	STAssertEqualObjects(request.route, @"customs", nil);
	
	[request routeToObject:[[CustomClass alloc] init] withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"customs/action", nil);
	
	//object (id)	
	[request routeToObject:[[CustomClass alloc] initWithRemoteDictionary:idDict]];	
	STAssertEqualObjects(request.route, @"customs/1", nil);
	
	[request routeToObject:[[CustomClass alloc] initWithRemoteDictionary:idDict] withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"customs/1/action", nil);
	
	
	/* PREFIX */
	
	//class
	[request routeToClass:[PrefixClass class]];	
	STAssertEqualObjects(request.route, @"prefs", nil);
	
	[request routeToClass:[PrefixClass class] withCustomMethod:@"action"];
	STAssertEqualObjects(request.route, @"prefs/action", nil);
	
	//object
	PrefixClass *pref = [[PrefixClass alloc] init];
	STAssertThrows([request routeToObject:pref], @"Should throw exception bc association is nil");
	
	pref.normal = [[NormalClass alloc] init];
	STAssertThrows([request routeToObject:pref], @"Should throw exception bc association's rID is nil");
	
	pref.normal.remoteID = NSRNumber(1);
	[request routeToObject:pref];
	STAssertEqualObjects(request.route, @"normal_classes/1/prefs", nil);

	[request routeToObject:pref withCustomMethod:@"action"];
	STAssertEqualObjects(request.route, @"normal_classes/1/prefs/action", nil);

	pref.remoteID = NSRNumber(5);
	[request routeToObject:pref];
	STAssertEqualObjects(request.route, @"normal_classes/1/prefs/5", nil);
	
	[request routeToObject:pref withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"normal_classes/1/prefs/5/action", nil);
	
	
	/* CUSTOM CONFIG */
	
	NSRConfig *config = [[NSRConfig alloc] initWithAppURL:@"http://CUSTOM"];
	[config useForClass:[CustomClass class]];

	[request routeToClass:[CustomClass class]];
	STAssertEquals(request.config, config, @"Should have same config");

	request.config = nil;

	[request routeToObject:[[CustomClass alloc] init]];
	STAssertEquals(request.config, config, @"Should have same config");
}

- (void) test_factories
{
	NormalClass *norm = [[NormalClass alloc] init];
	
	/* CREATE */
	
	NSRRequest *create = [NSRRequest requestToCreateObject:norm];
	STAssertEqualObjects(create.route, @"normal_classes", nil);
	STAssertEqualObjects(create.httpMethod, @"POST", nil);
	STAssertEqualObjects(create.body, [norm remoteDictionaryRepresentationWrapped:YES], nil);
	
	norm.remoteID = NSRNumber(5);
	
	create = [NSRRequest requestToCreateObject:norm];
	STAssertEqualObjects(create.route, @"normal_classes", @"Should ignore ID in route");
	
	/* FETCH */
	
	norm.remoteID = nil;
	STAssertThrows([NSRRequest requestToFetchObject:norm], @"Should throw nil rID");

	norm.remoteID = NSRNumber(5);
	NSRRequest *fetch = [NSRRequest requestToFetchObject:norm];
	STAssertEqualObjects(fetch.route, @"normal_classes/5", nil);
	STAssertEqualObjects(fetch.httpMethod, @"GET", nil);
	STAssertNil(fetch.body, nil);
	
	/* UPDATE */
	
	norm.remoteID = nil;
	STAssertThrows([NSRRequest requestToUpdateObject:norm], @"Should throw nil rID");
	
	norm.remoteID = NSRNumber(5);
	NSRRequest *update = [NSRRequest requestToUpdateObject:norm];
	STAssertEqualObjects(update.route, @"normal_classes/5", nil);
	STAssertEqualObjects(update.httpMethod, @"PUT", nil);
	STAssertEqualObjects(update.body, [norm remoteDictionaryRepresentationWrapped:YES], nil);

	[[NSRConfig defaultConfig] setUpdateMethod:@"PATCH"];
	update = [NSRRequest requestToUpdateObject:norm];
	STAssertEqualObjects(update.httpMethod, @"PATCH", nil);
	
	NSRConfig *config = [[NSRConfig alloc] initWithAppURL:@"http://CUSTOM"];
	config.updateMethod = @"PUT";
	[config useForClass:[NormalClass class]];
	
	update = [NSRRequest requestToUpdateObject:norm];

	STAssertEqualObjects(update.httpMethod, @"PUT", nil);

	/* DELETE */
	
	norm.remoteID = nil;
	STAssertThrows([NSRRequest requestToDestroyObject:norm], @"Should throw nil rID");
	
	norm.remoteID = NSRNumber(5);
	NSRRequest *delete = [NSRRequest requestToDestroyObject:norm];
	STAssertEqualObjects(delete.route, @"normal_classes/5", nil);
	STAssertEqualObjects(delete.httpMethod, @"DELETE", nil);
	STAssertNil(delete.body, nil);
	
	/* REPLACE */
	
	norm.remoteID = nil;
	STAssertThrows([NSRRequest requestToReplaceObject:norm], @"Should throw nil rID");
	
	norm.remoteID = NSRNumber(5);
	NSRRequest *replace = [NSRRequest requestToReplaceObject:norm];
	STAssertEqualObjects(replace.route, @"normal_classes/5", nil);
	STAssertEqualObjects(replace.httpMethod, @"PUT", nil);
	STAssertEqualObjects(replace.body, [norm remoteDictionaryRepresentationWrapped:YES], nil);

	/* FIND ONE */
	
	STAssertThrows([NSRRequest requestToFetchObjectWithID:nil ofClass:[NormalClass class]], @"Should throw nil rID");
	
	NSRRequest *findOne = [NSRRequest requestToFetchObjectWithID:NSRNumber(1) ofClass:[NormalClass class]];
	STAssertEqualObjects(findOne.route, @"normal_classes/1", nil);
	STAssertEqualObjects(findOne.httpMethod, @"GET", nil);
	STAssertNil(findOne.body, nil);

	/* FIND ALL */
	
	for (int i = 0; i < 2; i++)
	{
		NSRRequest *findAll;
		if (i == 0)
			findAll = [NSRRequest requestToFetchAllObjectsOfClass:[NormalClass class] viaObject:nil];
		else
			findAll = [NSRRequest requestToFetchAllObjectsOfClass:[NormalClass class]];
		
		STAssertEqualObjects(findAll.route, @"normal_classes", nil);
		STAssertEqualObjects(findAll.httpMethod, @"GET", nil);
		STAssertNil(findAll.body, nil);
	}

	
	/* FIND ALL VIA OBJECT */
	
	norm.remoteID = NSRNumber(5);
	
	NSRRequest *findAllObj = [NSRRequest requestToFetchAllObjectsOfClass:[PrefixClass class] viaObject:norm];
	STAssertEqualObjects(findAllObj.route, @"normal_classes/5/prefs", nil);
	STAssertEqualObjects(findAllObj.httpMethod, @"GET", nil);
	STAssertNil(findAllObj.body, nil);
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