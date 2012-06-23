//
//  Request.m
//  NSRails
//
//  Created by Dan Hassin on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRAsserts.h"

@interface NSRRequest (private)

+ (NSRRequest *) requestWithHTTPMethod:(NSString *)method;

- (NSURLRequest *) HTTPRequest;

- (NSError *) errorForResponse:(id)response statusCode:(NSInteger)statusCode;
- (id) receiveResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError **)error;

@end


@interface Request : SenTestCase

@end

@implementation Request

- (void) setUp
{
	[NSRConfig resetConfigs];
}

/*************
     UNIT
 *************/

- (void) test_query_params
{
	NSRRequest *req = [NSRRequest GET];
	
	[NSRConfig defaultConfig].appURL = @"http://myapp.com";
	
	NSURLRequest *request = [req HTTPRequest];
	STAssertEqualObjects([request.URL description], @"http://myapp.com", nil);

	[req.queryParameters setObject:@"etc" forKey:@"q"];
	
	request = [req HTTPRequest];
	STAssertEqualObjects([request.URL description], @"http://myapp.com?q=etc", nil);
	
	[req.queryParameters setObject:@"num2" forKey:@"qz"];
	
	request = [req HTTPRequest];
	STAssertEqualObjects([request.URL description], @"http://myapp.com?q=etc&qz=num2", nil);
	
	[req routeTo:@"test"];
	
	request = [req HTTPRequest];
	STAssertEqualObjects([request.URL description], @"http://myapp.com/test?q=etc&qz=num2", nil);
	
	[req.queryParameters removeAllObjects];
	
	request = [req HTTPRequest];
	STAssertEqualObjects([request.URL description], @"http://myapp.com/test", nil);
}

- (void) test_http_methods
{
	NSRRequest *req;
	
	req = [NSRRequest GET];
	STAssertEqualObjects(req.httpMethod, @"GET", nil);

	req = [NSRRequest PATCH];
	STAssertEqualObjects(req.httpMethod, @"PATCH", nil);

	req = [NSRRequest PUT];
	STAssertEqualObjects(req.httpMethod, @"PUT", nil);

	req = [NSRRequest DELETE];
	STAssertEqualObjects(req.httpMethod, @"DELETE", nil);

	req = [NSRRequest POST];
	STAssertEqualObjects(req.httpMethod, @"POST", nil);
}

- (void) test_nsurlrequest
{
	NSRRequest *req = [NSRRequest GET];
	STAssertThrows([req HTTPRequest], nil);
	
	[NSRConfig defaultConfig].appURL = @"http://myapp.com";
	
	NSURLRequest *request = [req HTTPRequest];
	STAssertEqualObjects([request.URL description], @"http://myapp.com", nil);
	STAssertEqualObjects([request HTTPMethod], @"GET", nil);
	STAssertNil([request HTTPBody], nil);

	req.body = [NSArray array];
	request = [req HTTPRequest];
	STAssertEqualObjects([request HTTPBody], [@"[]" dataUsingEncoding:NSUTF8StringEncoding], nil);

	[req routeTo:@"hello"];
	request = [req HTTPRequest];
	STAssertEqualObjects([request.URL description], @"http://myapp.com/hello", nil);

	req.body = @":f,aifj*(O#P:???";
	STAssertThrows([req HTTPRequest], nil);

	req.body = @"{hello:man}";
	STAssertThrows([req HTTPRequest], nil);	
}

/* With objects */

- (void) test_set_object_body
{
	NSRRequest *req = [NSRRequest POST];
	[req setBodyToObject:nil];
	
	[NSRConfig defaultConfig].appURL = @"http://myapp.com";

	NSURLRequest *request = [req HTTPRequest];
	STAssertNil([request HTTPBody], nil);
	
	SuperClass *p = [[SuperClass alloc] init];
	
	[req setBodyToObject:p];
	request = [req HTTPRequest];
	STAssertEqualObjects([request HTTPBody], [@"{\"super_class\":{\"super_string\":null}}" dataUsingEncoding:NSUTF8StringEncoding], nil);
	
	p.superString = @"dan";
	[req setBodyToObject:p];
	request = [req HTTPRequest];
	STAssertEqualObjects([request HTTPBody], [@"{\"super_class\":{\"super_string\":\"dan\"}}" dataUsingEncoding:NSUTF8StringEncoding], nil);
}

- (void) test_routing
{
	NSRRequest *request = [[NSRRequest alloc] init];
	
	[request routeTo:@"hi"];
	STAssertEqualObjects(request.route, @"hi", nil);
	
	/* NORMAL */
	
	//class
	[request routeToClass:[NestParent class]];	
	STAssertEqualObjects(request.route, @"parents", nil);
	
	[request routeToClass:[NestParent class] withCustomMethod:@"action"];
	STAssertEqualObjects(request.route, @"parents/action", nil);
	
	//object (no id)
	[request routeToObject:[[NestParent alloc] init]];	
	STAssertEqualObjects(request.route, @"parents", nil);
	
	[request routeToObject:[[NestParent alloc] init] withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"parents/action", nil);
	
	//object (id)
	NSDictionary *idDict = NSRDictionary(NSRNumber(1), @"id");
	
	[request routeToObject:[NestParent objectWithRemoteDictionary:idDict]];	
	STAssertEqualObjects(request.route, @"parents/1", nil);
	
	[request routeToObject:[NestParent objectWithRemoteDictionary:idDict] withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"parents/1/action", nil);
	
	
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
	[request routeToObject:[CustomClass objectWithRemoteDictionary:idDict]];	
	STAssertEqualObjects(request.route, @"customs/1", nil);
	
	[request routeToObject:[CustomClass objectWithRemoteDictionary:idDict] withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"customs/1/action", nil);
	
	
	/* PREFIX */
	
	//class
	[request routeToClass:[NestChildPrefixed class]];	
	STAssertEqualObjects(request.route, @"prefs", nil);
	
	[request routeToClass:[NestChildPrefixed class] withCustomMethod:@"action"];
	STAssertEqualObjects(request.route, @"prefs/action", nil);
	
	//object
	NestChildPrefixed *pref = [[NestChildPrefixed alloc] init];
	
	[request routeToObject:pref];
	STAssertEqualObjects(request.route, @"prefs", nil);
	
	pref.parent = [[NestParent alloc] init];
	STAssertThrows([request routeToObject:pref], @"Should throw exception bc association's rID is nil");
	
	pref.parent.remoteID = NSRNumber(1);
	[request routeToObject:pref];
	STAssertEqualObjects(request.route, @"parents/1/prefs", nil);
	
	[request routeToObject:pref withCustomMethod:@"action"];
	STAssertEqualObjects(request.route, @"parents/1/prefs/action", nil);
	
	pref.remoteID = NSRNumber(5);
	[request routeToObject:pref];
	STAssertEqualObjects(request.route, @"parents/1/prefs/5", nil);
	
	[request routeToObject:pref withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"parents/1/prefs/5/action", nil);
	
	/* DOUBLE PREFIX */
	
	
	// Now double nested + custom names
	// Controller (class)
	
	[request routeToClass:[NestChildPrefixedChild class]];	
	STAssertEqualObjects(request.route, @"pref2s", nil);
	
	[request routeToClass:[NestChildPrefixedChild class] withCustomMethod:@"action"];	
	STAssertEqualObjects(request.route, @"pref2s/action", nil);
	
	// Instance
	NestChildPrefixedChild *smth2 = [[NestChildPrefixedChild alloc] init];
	
	[request routeToObject:smth2 withCustomMethod:nil];
	STAssertEqualObjects(request.route, @"pref2s", nil);
	
	[request routeToObject:smth2 withCustomMethod:@"action"];
	STAssertEqualObjects(request.route, @"pref2s/action", nil);
	
	smth2.remoteID = [NSNumber numberWithInt:15];
	
	for (int i = 0; i < 2; i++)
	{
		[request routeToObject:smth2 withCustomMethod:nil];
		STAssertEqualObjects(request.route, @"pref2s/15", nil);
		
		[request routeToObject:smth2 withCustomMethod:@"action"];
		STAssertEqualObjects(request.route, @"pref2s/15/action", nil);
		
		request = [NSRRequest DELETE];
	}
	
	for (int i = 0; i < 2; i++)
	{
		if (i == 0)
            request = [NSRRequest PATCH];
		else
            request = [NSRRequest GET];
		
		smth2.remoteID = nil;
		smth2.childParent = nil;
		
		// Instance
		[request routeToObject:smth2];
		STAssertEqualObjects(request.route, @"pref2s", nil);
		
		[request routeToObject:smth2 withCustomMethod:@"action"];
		STAssertEqualObjects(request.route, @"pref2s/action", nil);
		
		smth2.remoteID = [NSNumber numberWithInt:1];
		
		[request routeToObject:smth2];
		STAssertEqualObjects(request.route, @"pref2s/1", nil);
		
		[request routeToObject:smth2 withCustomMethod:@"action"];
		STAssertEqualObjects(request.route, @"pref2s/1/action", nil);
		
		smth2.childParent = [[NestChildPrefixed alloc] init];
		STAssertThrowsSpecificNamed([request routeToObject:smth2], NSException, NSRNullRemoteIDException, @"Should still crash, because 'thePrefixer' relation has a nil remoteID");
		
		smth2.childParent.remoteID = [NSNumber numberWithInt:15];
		
		[request routeToObject:smth2];
		STAssertEqualObjects(request.route, @"prefs/15/pref2s/1", nil);
		
		[request routeToObject:smth2 withCustomMethod:@"action"];
		STAssertEqualObjects(request.route, @"prefs/15/pref2s/1/action", nil);
		
		smth2.childParent.parent = [[NestParent alloc] init];
		STAssertThrowsSpecificNamed([request routeToObject:smth2], NSException, NSRNullRemoteIDException, @"Should STILL crash, because 'thePrefixer' relation's 'custom' has a nil remoteID");
		
		smth2.childParent.parent.remoteID = [NSNumber numberWithInt:23];
		
		[request routeToObject:smth2];
		STAssertEqualObjects(request.route, @"parents/23/prefs/15/pref2s/1", nil);
		
		[request routeToObject:smth2 withCustomMethod:@"action"];
		STAssertEqualObjects(request.route, @"parents/23/prefs/15/pref2s/1/action", nil);
		
		//make sure class methods still work
		[request routeToClass:[NestChildPrefixedChild class]];	
		STAssertEqualObjects(request.route, @"pref2s", nil);
		
		[request routeToClass:[NestChildPrefixedChild class] withCustomMethod:@"action"];	
		STAssertEqualObjects(request.route, @"pref2s/action", nil);
		
		//make sure no ID still works
		smth2.remoteID = nil;
		
		[request routeToObject:smth2];
		STAssertEqualObjects(request.route, @"parents/23/prefs/15/pref2s", nil);
		
		[request routeToObject:smth2 withCustomMethod:@"action"];
		STAssertEqualObjects(request.route, @"parents/23/prefs/15/pref2s/action", nil);
	}
}

/*************
     LOGIC
 *************/

- (void) test_factories
{
	NestParent *norm = [[NestParent alloc] init];
	
	/* CREATE */
	
	NSRRequest *create = [NSRRequest requestToCreateObject:norm];
	STAssertEqualObjects(create.route, @"parents", nil);
	STAssertEqualObjects(create.httpMethod, @"POST", nil);
	STAssertEqualObjects(create.body, [norm remoteDictionaryRepresentationWrapped:YES], nil);
	
	norm.remoteID = NSRNumber(5);
	
	create = [NSRRequest requestToCreateObject:norm];
	STAssertEqualObjects(create.route, @"parents", @"Should ignore ID in route");
	
	/* FETCH */
	
	norm.remoteID = nil;
	STAssertThrows([NSRRequest requestToFetchObject:norm], @"Should throw nil rID");
	
	norm.remoteID = NSRNumber(5);
	NSRRequest *fetch = [NSRRequest requestToFetchObject:norm];
	STAssertEqualObjects(fetch.route, @"parents/5", nil);
	STAssertEqualObjects(fetch.httpMethod, @"GET", nil);
	STAssertNil(fetch.body, nil);
	
	/* UPDATE */
	
	norm.remoteID = nil;
	STAssertThrows([NSRRequest requestToUpdateObject:norm], @"Should throw nil rID");
	
	norm.remoteID = NSRNumber(5);
	NSRRequest *update = [NSRRequest requestToUpdateObject:norm];
	STAssertEqualObjects(update.route, @"parents/5", nil);
	STAssertEqualObjects(update.httpMethod, @"PUT", nil);
	STAssertEqualObjects(update.body, [norm remoteDictionaryRepresentationWrapped:YES], nil);
	
	[[NSRConfig defaultConfig] setUpdateMethod:@"PATCH"];
	update = [NSRRequest requestToUpdateObject:norm];
	STAssertEqualObjects(update.httpMethod, @"PATCH", nil);
		
	/* DELETE */
	
	norm.remoteID = nil;
	STAssertThrows([NSRRequest requestToDestroyObject:norm], @"Should throw nil rID");
	
	norm.remoteID = NSRNumber(5);
	NSRRequest *delete = [NSRRequest requestToDestroyObject:norm];
	STAssertEqualObjects(delete.route, @"parents/5", nil);
	STAssertEqualObjects(delete.httpMethod, @"DELETE", nil);
	STAssertNil(delete.body, nil);
	
	/* REPLACE */
	
	norm.remoteID = nil;
	STAssertThrows([NSRRequest requestToReplaceObject:norm], @"Should throw nil rID");
	
	norm.remoteID = NSRNumber(5);
	NSRRequest *replace = [NSRRequest requestToReplaceObject:norm];
	STAssertEqualObjects(replace.route, @"parents/5", nil);
	STAssertEqualObjects(replace.httpMethod, @"PUT", nil);
	STAssertEqualObjects(replace.body, [norm remoteDictionaryRepresentationWrapped:YES], nil);
	
	/* FIND ONE */
	
	STAssertThrows([NSRRequest requestToFetchObjectWithID:nil ofClass:[NestParent class]], @"Should throw nil rID");
	
	NSRRequest *findOne = [NSRRequest requestToFetchObjectWithID:NSRNumber(1) ofClass:[NestParent class]];
	STAssertEqualObjects(findOne.route, @"parents/1", nil);
	STAssertEqualObjects(findOne.httpMethod, @"GET", nil);
	STAssertNil(findOne.body, nil);
	
	/* FIND ALL */
	
	for (int i = 0; i < 2; i++)
	{
		NSRRequest *findAll;
		if (i == 0)
			findAll = [NSRRequest requestToFetchAllObjectsOfClass:[NestParent class] viaObject:nil];
		else
			findAll = [NSRRequest requestToFetchAllObjectsOfClass:[NestParent class]];
		
		STAssertEqualObjects(findAll.route, @"parents", nil);
		STAssertEqualObjects(findAll.httpMethod, @"GET", nil);
		STAssertNil(findAll.body, nil);
	}
	
	
	/* FIND ALL VIA OBJECT */
	
	norm.remoteID = NSRNumber(5);
	
	NSRRequest *findAllObj = [NSRRequest requestToFetchAllObjectsOfClass:[NestChildPrefixed class] viaObject:norm];
	STAssertEqualObjects(findAllObj.route, @"parents/5/prefs", nil);
	STAssertEqualObjects(findAllObj.httpMethod, @"GET", nil);
	STAssertNil(findAllObj.body, nil);
	
	norm.remoteID = nil;
	
	STAssertThrows([NSRRequest requestToFetchAllObjectsOfClass:[NestChildPrefixed class] viaObject:norm], @"Should throw nil rID");
	
	//try with nil
	findAllObj = [NSRRequest requestToFetchAllObjectsOfClass:[NestChildPrefixed class] viaObject:nil];
	STAssertEqualObjects(findAllObj.route, @"prefs", nil);
}

- (void) test_configs
{
	NSRRequest *req = [NSRRequest POST];
	STAssertEquals(req.config, [NSRConfig defaultConfig], nil);
	STAssertThrows([req.HTTPRequest URL], nil);
	
	[NSRConfig defaultConfig].appURL = @"http://myapp.com";
	
	STAssertEqualObjects([req.HTTPRequest URL], [NSURL URLWithString:@"http://myapp.com"], nil);
	
	NSRConfig *customConfig = [[NSRConfig alloc] initWithAppURL:@"http://custom"];
	req.config = customConfig;
	STAssertEquals(req.config, customConfig, nil);
	STAssertEqualObjects([req.HTTPRequest URL], [NSURL URLWithString:@"http://custom"], nil);
	
	[req routeToClass:[CustomConfigClass class]];
	STAssertEqualObjects(req.config.appURL, [CustomConfigClass config].appURL, nil);
	STAssertEqualObjects([req.HTTPRequest URL], [NSURL URLWithString:@"http://class/CustomConfigClasses"], nil);

	[req routeToObject:[[CustomConfigClass alloc] init]];
	STAssertEqualObjects(req.config.appURL, [[[CustomConfigClass alloc] init].class config].appURL, nil);
	STAssertEqualObjects([req.HTTPRequest URL], [NSURL URLWithString:@"http://class/CustomConfigClasses"], nil);
}

- (void) test_completion_block_threads
{
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	[[NSRConfig defaultConfig] setPerformsCompletionBlocksOnMainThread:YES];
	
	NSRRequest *request = [NSRRequest GET];
	[request routeTo:@"posts"];
	
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
	NSRRequest *r = [NSRRequest GET];
	
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
		STAssertEqualObjects([[error userInfo] objectForKey:NSLocalizedDescriptionKey], shortError, @"Succinct message extraction failed for short message");
		STAssertNil([[error userInfo] objectForKey:NSRValidationErrorsKey], @"Validation errors dict should not have been created for 404");
		STAssertEquals([[error userInfo] objectForKey:NSRRequestObjectKey],r,@"Should include itself as the request");
        
		//Test without succinct
		[[NSRConfig defaultConfig] setSuccinctErrorMessages:NO];
		
		NSError *error2 = [r errorForResponse:fullError statusCode:code];
		STAssertEqualObjects([error2 domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
		STAssertTrue([[[error2 userInfo] objectForKey:NSLocalizedDescriptionKey] isEqualToString:fullError], @"NO succinct error messages failed (bad!)");
		STAssertNil([[error2 userInfo] objectForKey:NSRValidationErrorsKey], @"Validation errors dict should not have been created for 404");
        STAssertEquals([[error userInfo] objectForKey:NSRRequestObjectKey],r,@"Should include itself as the request");
    }
	
	// 422 Validation
	
	NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[[MockServer validation422Error] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
	
	NSError *valError = [r errorForResponse:response statusCode:422];
	STAssertTrue([valError code] == 422, @"422 was returned, not picked up by config");
	STAssertEqualObjects([valError domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
    STAssertEquals([[valError userInfo] objectForKey:NSRRequestObjectKey],r,@"Should include itself as the request");

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

- (void) test_authentication
{
	/** No user/pass (*/
	
	NSString *url = @"http://localhost:3000";
	[[NSRConfig defaultConfig] setAppURL:url];
	
	NSRRequest *req = [NSRRequest GET];
	
	NSURLRequest *request = [req HTTPRequest];
	STAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no user/pass");

	/** OAuth **/
	
	for (int i = 0; i < 2; i++)
	{
		[NSRConfig defaultConfig].appOAuthToken = @"token123";
		request = [req HTTPRequest];
		
		STAssertEqualObjects([request valueForHTTPHeaderField:@"Authorization"], @"OAuth token123", @"Should send OAuth token");
		
		//should be identical if only one user/pass element is present (but still oauth)
		[[NSRConfig defaultConfig] setAppPassword:@"password"];
	}
	
	[NSRConfig defaultConfig].appOAuthToken = nil;
	
	/** User/pass **/
	
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

- (void) test_serialization
{
    NSString *file = [NSHomeDirectory() stringByAppendingPathComponent:@"test.dat"];

    NSRConfig *config = [[NSRConfig alloc] initWithAppURL:@"hi"];
    
    NSRRequest *req = [[NSRRequest GET] routeTo:@"hi"];
    req.config = config;
    req.body = @"test";
    
    [req.queryParameters setObject:@"hi" forKey:@"t"];
    [req.additionalHTTPHeaders setObject:@"hi" forKey:@"t"];
		
	STAssertTrue([NSKeyedArchiver archiveRootObject:req toFile:file], @"Archiving should've worked (serialize)");
	
	NSRRequest *req2 = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
	STAssertEqualObjects(req.httpMethod, req2.httpMethod, @"Should've carried over");	
	STAssertEqualObjects(req.route, req2.route, @"Should've carried over");	
	STAssertEqualObjects(req.queryParameters, req2.queryParameters, @"Should've carried over");	
	STAssertEqualObjects(req.additionalHTTPHeaders, req2.additionalHTTPHeaders, @"Should've carried over");	
	STAssertEqualObjects(req.config.appURL, req2.config.appURL, @"Should've carried over");	
	STAssertEqualObjects(req.body, req2.body, @"Should've carried over");	
}

- (void) test_additional_headers
{
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
	
	NSRRequest *req = [NSRRequest GET];
    [req.additionalHTTPHeaders setObject:@"hi" forKey:@"test"];
    NSURLRequest *request = [req HTTPRequest];
    STAssertEqualObjects([request valueForHTTPHeaderField:@"test"], @"hi", @"Should send custom key");

    [req.additionalHTTPHeaders setObject:@"hi" forKey:@"test2"];
    request = [req HTTPRequest];
    STAssertEqualObjects([request valueForHTTPHeaderField:@"test2"], @"hi", @"Should send custom key");
    STAssertEqualObjects([request valueForHTTPHeaderField:@"test"], @"hi", @"Should still send custom key");

    [req.additionalHTTPHeaders removeAllObjects];
    request = [req HTTPRequest];
    STAssertNil([request valueForHTTPHeaderField:@"test2"], @"Should've cleared custom key");
    STAssertNil([request valueForHTTPHeaderField:@"test"], @"Should've cleared custom key");
}

@end
