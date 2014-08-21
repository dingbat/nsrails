//
//  Request.m
//  NSRails
//
//  Created by Dan Hassin on 6/11/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface NSRRequest (private)

+ (NSString *) base64EncodingOfData:(NSData *)data;

+ (NSRRequest *) requestWithHTTPMethod:(NSString *)method;

- (NSURLRequest *) HTTPRequest;

- (NSError *) errorForResponse:(id)jsonResponse existingError:(NSError *)existing statusCode:(NSInteger)statusCode;
- (id) receiveResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError **)error;

@end


@interface Request : XCTestCase

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
    
    [NSRConfig defaultConfig].rootURL = [NSURL URLWithString:@"http://myapp.com"];
    
    NSURLRequest *request = [req HTTPRequest];
    XCTAssertEqualObjects([request.URL description], @"http://myapp.com");

    req.queryParameters = @{@"q":@"etc"};
    
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request.URL description], @"http://myapp.com?q=etc");
    
    req.queryParameters =@{@"q":@"etc", @"qz":@"num2"};
    
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request.URL description], @"http://myapp.com?q=etc&qz=num2");
    
    [req routeTo:@"test"];
    
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request.URL description], @"http://myapp.com/test?q=etc&qz=num2");
    
    req.queryParameters = nil;
    
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request.URL description], @"http://myapp.com/test");
}

- (void) test_http_methods
{
    NSRRequest *req;
    
    req = [NSRRequest GET];
    XCTAssertEqualObjects(req.httpMethod, @"GET");

    req = [NSRRequest PATCH];
    XCTAssertEqualObjects(req.httpMethod, @"PATCH");

    req = [NSRRequest PUT];
    XCTAssertEqualObjects(req.httpMethod, @"PUT");

    req = [NSRRequest DELETE];
    XCTAssertEqualObjects(req.httpMethod, @"DELETE");

    req = [NSRRequest POST];
    XCTAssertEqualObjects(req.httpMethod, @"POST");
}

- (void) test_nsurlrequest
{
    NSRRequest *req = [NSRRequest GET];
    XCTAssertThrowsSpecificNamed([req HTTPRequest], NSException, NSRMissingURLException, @"Should throw a missing root URL exception");
    
    [NSRConfig defaultConfig].rootURL = [NSURL URLWithString:@"http://myapp.com"];
    
    NSURLRequest *request = [req HTTPRequest];
    XCTAssertEqualObjects([request.URL description], @"http://myapp.com");
    XCTAssertEqualObjects([request HTTPMethod], @"GET");
    XCTAssertNil([request HTTPBody]);

    XCTAssertThrows(req.body = @(42), @"Should throw an invalid body object exception");

    req.body = @[];
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request HTTPBody], [@"[]" dataUsingEncoding:NSUTF8StringEncoding]);

    [req routeTo:@"hello"];
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request.URL description], @"http://myapp.com/hello");
    
    req = [NSRRequest POST];
    req.body = @"this=that&thisarray[]=thatvalue]";
    req.additionalHTTPHeaders = @{@"Content-Type":@"application/x-www-form-urlencoded"};
    request = [req HTTPRequest];
    NSData *data = [req.body dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(request.HTTPBody, data, @"Body of NSRRequest was not able to be set to an NSString");
    
    req.additionalHTTPHeaders = nil;
    XCTAssertThrows([req HTTPRequest], @"Should throw exception because no Content-Type header was given when POST body was set as a string.");
}

/* With objects */

- (void) test_set_object_body
{
    NSRRequest *req = [NSRRequest POST];
    [req setBodyToObject:nil];
    
    [NSRConfig defaultConfig].rootURL = [NSURL URLWithString:@"http://myapp.com"];

    NSURLRequest *request = [req HTTPRequest];
    XCTAssertNil([request HTTPBody]);
    
    SuperClass *p = [[SuperClass alloc] init];
    
    [req setBodyToObject:p];
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request HTTPBody], [@"{\"super_class\":{\"super_string\":null}}" dataUsingEncoding:NSUTF8StringEncoding]);
    
    p.superString = @"dan";
    [req setBodyToObject:p];
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request HTTPBody], [@"{\"super_class\":{\"super_string\":\"dan\"}}" dataUsingEncoding:NSUTF8StringEncoding]);
}

- (void) test_routing
{
    NSRRequest *request = [[NSRRequest alloc] init];
    
    [request routeTo:@"hi"];
    XCTAssertEqualObjects(request.route, @"hi");
    
    /* NORMAL */
    
    //class
    [request routeToClass:[NestParent class]];    
    XCTAssertEqualObjects(request.route, @"parents");
    
    [request routeToClass:[NestParent class] withCustomMethod:@"action"];
    XCTAssertEqualObjects(request.route, @"parents/action");
    
    //object (no id)
    [request routeToObject:[[NestParent alloc] init]];    
    XCTAssertEqualObjects(request.route, @"parents");
    
    [request routeToObject:[[NestParent alloc] init] withCustomMethod:@"action"];    
    XCTAssertEqualObjects(request.route, @"parents/action");
    
    //object (id)
    NSDictionary *idDict = @{@"id":@1};
    
    [request routeToObject:[NestParent objectWithRemoteDictionary:idDict]];    
    XCTAssertEqualObjects(request.route, @"parents/1");
    
    [request routeToObject:[NestParent objectWithRemoteDictionary:idDict] withCustomMethod:@"action"];    
    XCTAssertEqualObjects(request.route, @"parents/1/action");
    
    
    /* CUSTOM */
    
    //class
    [request routeToClass:[CustomClass class]];    
    XCTAssertEqualObjects(request.route, @"customs");
    
    [request routeToClass:[CustomClass class] withCustomMethod:@"action"];
    XCTAssertEqualObjects(request.route, @"customs/action");
    
    //object (no id)
    [request routeToObject:[[CustomClass alloc] init]];    
    XCTAssertEqualObjects(request.route, @"customs");
    
    [request routeToObject:[[CustomClass alloc] init] withCustomMethod:@"action"];    
    XCTAssertEqualObjects(request.route, @"customs/action");
    
    //object (id)    
    [request routeToObject:[CustomClass objectWithRemoteDictionary:idDict]];    
    XCTAssertEqualObjects(request.route, @"customs/1");
    
    [request routeToObject:[CustomClass objectWithRemoteDictionary:idDict] withCustomMethod:@"action"];    
    XCTAssertEqualObjects(request.route, @"customs/1/action");
    
    
    /* PREFIX */
    
    //class
    [request routeToClass:[NestChildPrefixed class]];    
    XCTAssertEqualObjects(request.route, @"prefs");
    
    [request routeToClass:[NestChildPrefixed class] withCustomMethod:@"action"];
    XCTAssertEqualObjects(request.route, @"prefs/action");
    
    //object
    NestChildPrefixed *pref = [[NestChildPrefixed alloc] init];
    
    [request routeToObject:pref];
    XCTAssertEqualObjects(request.route, @"prefs");
    
    pref.parent = [[NestParent alloc] init];
    XCTAssertThrows([request routeToObject:pref], @"Should throw exception bc association's rID is nil");
    
    pref.parent.remoteID = @1;
    [request routeToObject:pref];
    XCTAssertEqualObjects(request.route, @"parents/1/prefs");
    
    [request routeToObject:pref withCustomMethod:@"action"];
    XCTAssertEqualObjects(request.route, @"parents/1/prefs/action");
    
    pref.remoteID = @5;
    [request routeToObject:pref];
    XCTAssertEqualObjects(request.route, @"parents/1/prefs/5");
    
    [request routeToObject:pref withCustomMethod:@"action"];    
    XCTAssertEqualObjects(request.route, @"parents/1/prefs/5/action");
    
    /* DOUBLE PREFIX */
    
    
    // Now double nested + custom names
    // Controller (class)
    
    [request routeToClass:[NestChildPrefixedChild class]];    
    XCTAssertEqualObjects(request.route, @"pref2s");
    
    [request routeToClass:[NestChildPrefixedChild class] withCustomMethod:@"action"];    
    XCTAssertEqualObjects(request.route, @"pref2s/action");
    
    // Instance
    NestChildPrefixedChild *smth2 = [[NestChildPrefixedChild alloc] init];
    
    [request routeToObject:smth2 withCustomMethod:nil];
    XCTAssertEqualObjects(request.route, @"pref2s");
    
    [request routeToObject:smth2 withCustomMethod:@"action"];
    XCTAssertEqualObjects(request.route, @"pref2s/action");
    
    smth2.remoteID = @15;
    
    for (int i = 0; i < 2; i++)
    {
        [request routeToObject:smth2 withCustomMethod:nil];
        XCTAssertEqualObjects(request.route, @"pref2s/15");
        
        [request routeToObject:smth2 withCustomMethod:@"action"];
        XCTAssertEqualObjects(request.route, @"pref2s/15/action");
        
        request = [NSRRequest DELETE];
    }
    
    for (int i = 0; i < 2; i++)
    {
        if (i == 0) {
            request = [NSRRequest PATCH];
        }
        else {
            request = [NSRRequest GET];
        }
        
        smth2.remoteID = nil;
        smth2.childParent = nil;
        
        // Instance
        [request routeToObject:smth2];
        XCTAssertEqualObjects(request.route, @"pref2s");
        
        [request routeToObject:smth2 withCustomMethod:@"action"];
        XCTAssertEqualObjects(request.route, @"pref2s/action");
        
        smth2.remoteID = @1;
        
        [request routeToObject:smth2];
        XCTAssertEqualObjects(request.route, @"pref2s/1");
        
        [request routeToObject:smth2 withCustomMethod:@"action"];
        XCTAssertEqualObjects(request.route, @"pref2s/1/action");
        
        smth2.childParent = [[NestChildPrefixed alloc] init];
        XCTAssertThrowsSpecificNamed([request routeToObject:smth2], NSException, NSRNullRemoteIDException, @"Should still crash, because 'thePrefixer' relation has a nil remoteID");
        
        smth2.childParent.remoteID = @15;
        
        [request routeToObject:smth2];
        XCTAssertEqualObjects(request.route, @"prefs/15/pref2s/1");
        
        [request routeToObject:smth2 withCustomMethod:@"action"];
        XCTAssertEqualObjects(request.route, @"prefs/15/pref2s/1/action");
        
        smth2.childParent.parent = [[NestParent alloc] init];
        XCTAssertThrowsSpecificNamed([request routeToObject:smth2], NSException, NSRNullRemoteIDException, @"Should STILL crash, because 'thePrefixer' relation's 'custom' has a nil remoteID");
        
        smth2.childParent.parent.remoteID = @23;
        
        [request routeToObject:smth2];
        XCTAssertEqualObjects(request.route, @"parents/23/prefs/15/pref2s/1");
        
        [request routeToObject:smth2 withCustomMethod:@"action"];
        XCTAssertEqualObjects(request.route, @"parents/23/prefs/15/pref2s/1/action");
        
        //make sure class methods still work
        [request routeToClass:[NestChildPrefixedChild class]];    
        XCTAssertEqualObjects(request.route, @"pref2s");
        
        [request routeToClass:[NestChildPrefixedChild class] withCustomMethod:@"action"];    
        XCTAssertEqualObjects(request.route, @"pref2s/action");
        
        //make sure no ID still works
        smth2.remoteID = nil;
        
        [request routeToObject:smth2];
        XCTAssertEqualObjects(request.route, @"parents/23/prefs/15/pref2s");
        
        [request routeToObject:smth2 withCustomMethod:@"action"];
        XCTAssertEqualObjects(request.route, @"parents/23/prefs/15/pref2s/action");
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
    XCTAssertEqualObjects(create.route, @"parents");
    XCTAssertEqualObjects(create.httpMethod, @"POST");
    XCTAssertEqualObjects(create.body, [norm remoteDictionaryRepresentationWrapped:YES]);
    
    norm.remoteID = @5;
    
    create = [NSRRequest requestToCreateObject:norm];
    XCTAssertEqualObjects(create.route, @"parents", @"Should ignore ID in route");
    
    /* FETCH */
    
    norm.remoteID = nil;
    XCTAssertThrows([NSRRequest requestToFetchObject:norm], @"Should throw nil rID");
    
    norm.remoteID = @5;
    NSRRequest *fetch = [NSRRequest requestToFetchObject:norm];
    XCTAssertEqualObjects(fetch.route, @"parents/5");
    XCTAssertEqualObjects(fetch.httpMethod, @"GET");
    XCTAssertNil(fetch.body);
    
    /* UPDATE */
    
    norm.remoteID = nil;
    XCTAssertThrows([NSRRequest requestToUpdateObject:norm], @"Should throw nil rID");
    
    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion3];
    norm.remoteID = @5;
    NSRRequest *update = [NSRRequest requestToUpdateObject:norm];
    XCTAssertEqualObjects(update.route, @"parents/5");
    XCTAssertEqualObjects(update.httpMethod, @"PUT");
    XCTAssertEqualObjects(update.body, [norm remoteDictionaryRepresentationWrapped:YES]);
    
    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion4];
    update = [NSRRequest requestToUpdateObject:norm];
    XCTAssertEqualObjects(update.httpMethod, @"PATCH");
    
    [[NSRConfig defaultConfig] setUpdateMethod:@"xxx"];
    update = [NSRRequest requestToUpdateObject:norm];
    XCTAssertEqualObjects(update.httpMethod, @"xxx");
        
    /* DELETE */
    
    norm.remoteID = nil;
    XCTAssertThrows([NSRRequest requestToDestroyObject:norm], @"Should throw nil rID");
    
    norm.remoteID = @5;
    NSRRequest *delete = [NSRRequest requestToDestroyObject:norm];
    XCTAssertEqualObjects(delete.route, @"parents/5");
    XCTAssertEqualObjects(delete.httpMethod, @"DELETE");
    XCTAssertNil(delete.body);
    
    /* REPLACE */
    
    norm.remoteID = nil;
    XCTAssertThrows([NSRRequest requestToReplaceObject:norm], @"Should throw nil rID");
    
    norm.remoteID = @5;
    NSRRequest *replace = [NSRRequest requestToReplaceObject:norm];
    XCTAssertEqualObjects(replace.route, @"parents/5");
    XCTAssertEqualObjects(replace.httpMethod, @"PUT");
    XCTAssertEqualObjects(replace.body, [norm remoteDictionaryRepresentationWrapped:YES]);
    
    /* FIND ONE */
    
    XCTAssertThrows([NSRRequest requestToFetchObjectWithID:nil ofClass:[NestParent class]], @"Should throw nil rID");
    
    NSRRequest *findOne = [NSRRequest requestToFetchObjectWithID:@1 ofClass:[NestParent class]];
    XCTAssertEqualObjects(findOne.route, @"parents/1");
    XCTAssertEqualObjects(findOne.httpMethod, @"GET");
    XCTAssertNil(findOne.body);
    
    /* FIND ALL */
    
    for (int i = 0; i < 2; i++)
    {
        NSRRequest *findAll;
        if (i == 0) {
            findAll = [NSRRequest requestToFetchAllObjectsOfClass:[NestParent class] viaObject:nil];
        }
        else {
            findAll = [NSRRequest requestToFetchAllObjectsOfClass:[NestParent class]];
        }
        
        XCTAssertEqualObjects(findAll.route, @"parents");
        XCTAssertEqualObjects(findAll.httpMethod, @"GET");
        XCTAssertNil(findAll.body);
    }
    
    
    /* FIND ALL VIA OBJECT */
    
    norm.remoteID = @5;
    
    NSRRequest *findAllObj = [NSRRequest requestToFetchAllObjectsOfClass:[NestChildPrefixed class] viaObject:norm];
    XCTAssertEqualObjects(findAllObj.route, @"parents/5/prefs");
    XCTAssertEqualObjects(findAllObj.httpMethod, @"GET");
    XCTAssertNil(findAllObj.body);
    
    norm.remoteID = nil;
    
    XCTAssertThrows([NSRRequest requestToFetchAllObjectsOfClass:[NestChildPrefixed class] viaObject:norm], @"Should throw nil rID");
    
    //try with nil
    findAllObj = [NSRRequest requestToFetchAllObjectsOfClass:[NestChildPrefixed class] viaObject:nil];
    XCTAssertEqualObjects(findAllObj.route, @"prefs");
}

- (void) test_configs
{
    NSRRequest *req = [NSRRequest POST];
    XCTAssertEqual(req.config, [NSRConfig defaultConfig]);
    XCTAssertThrows([req.HTTPRequest URL]);
    
    [NSRConfig defaultConfig].rootURL = [NSURL URLWithString:@"http://myapp.com"];
    
    XCTAssertEqualObjects([req.HTTPRequest URL], [NSURL URLWithString:@"http://myapp.com"]);
    
    NSRConfig *customConfig = [[NSRConfig alloc] init];
    customConfig.rootURL = [NSURL URLWithString:@"http://custom"];
    req.config = customConfig;
    XCTAssertEqual(req.config, customConfig);
    XCTAssertEqualObjects([req.HTTPRequest URL], [NSURL URLWithString:@"http://custom"]);
    
    [req routeToClass:[CustomConfigClass class]];
    XCTAssertEqualObjects(req.config.rootURL, [CustomConfigClass config].rootURL);
    XCTAssertEqualObjects([req.HTTPRequest URL], [NSURL URLWithString:@"http://class/CustomConfigClasses"]);

    [req routeToObject:[[CustomConfigClass alloc] init]];
    XCTAssertEqualObjects(req.config.rootURL, [[[CustomConfigClass alloc] init].class config].rootURL);
    XCTAssertEqualObjects([req.HTTPRequest URL], [NSURL URLWithString:@"http://class/CustomConfigClasses"]);
}

- (void) test_completion_block_threads
{
    [[NSRConfig defaultConfig] setRootURL:[NSURL URLWithString:@"http://localhost:3000"]];
    [[NSRConfig defaultConfig] setBasicAuthUsername:@"NSRails"];
    [[NSRConfig defaultConfig] setBasicAuthPassword:@"iphone"];
    
    [[NSRConfig defaultConfig] setPerformsCompletionBlocksOnMainThread:YES];
    
    NSRRequest *request = [NSRRequest GET];
    [request routeTo:@"posts"];
    
    [request sendAsynchronous:
     ^(id jsonRep, NSError *error) 
     {
         XCTAssertTrue([NSThread isMainThread], @"With PCBOMT enabled, should run block in main thread");    
         
         //do the second test inside the block so they don't overwrite each other
         
         [[NSRConfig defaultConfig] setRootURL:[NSURL URLWithString:@"http://localhost:3000"]];
         [[NSRConfig defaultConfig] setBasicAuthUsername:@"NSRails"];
         [[NSRConfig defaultConfig] setBasicAuthPassword:@"iphone"];
         
         [[NSRConfig defaultConfig] setPerformsCompletionBlocksOnMainThread:NO];
         
         [request sendAsynchronous:
          ^(id jsonRep, NSError *error) 
          {
              XCTAssertFalse([NSThread isMainThread], @"With PCBOMT disabled, should run block in same thread");         
          }];
     }];
}

- (void) test_error_detection
{
    NSURL *url = [NSURL URLWithString:@"http://localhost:3000"];
    [[NSRConfig defaultConfig] setRootURL:url];

    NSRRequest *r = [NSRRequest GET];
    
    // 404 Not Found
    
    for (int i = 0; i < [MockServer fullErrors].count; i++)
    {
        NSString *fullError = [MockServer fullErrors][i];
        NSString *shortError = [MockServer shortErrors][i];
        NSInteger code = [[MockServer statusCodes][i] integerValue];
        
        //Test with succinct (default)
        [[NSRConfig defaultConfig] setSuccinctErrorMessages:YES];
        
        NSError *error = [r errorForResponse:fullError existingError:nil statusCode:code];
        XCTAssertEqualObjects([error domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
        XCTAssertEqualObjects([error userInfo][NSLocalizedDescriptionKey], shortError, @"Succinct message extraction failed for short message");
        XCTAssertEqual([error userInfo][NSRRequestObjectKey],r,@"Should include itself as the request");

        //Test without succinct
        [[NSRConfig defaultConfig] setSuccinctErrorMessages:NO];
        
        NSError *error2 = [r errorForResponse:fullError existingError:nil statusCode:code];
        XCTAssertEqualObjects([error2 domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
        XCTAssertTrue([[error2 userInfo][NSLocalizedDescriptionKey] isEqualToString:fullError], @"NO succinct error messages failed (bad!)");
        XCTAssertEqual([error2 userInfo][NSRRequestObjectKey],r,@"Should include itself as the request");
    }
    
    // 422 Validation
    
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[[MockServer validation422Error] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    
    NSError *valError = [r errorForResponse:response existingError:nil statusCode:422];
    XCTAssertTrue([valError code] == 422, @"422 was returned, not picked up by config");
    XCTAssertEqualObjects([valError domain], NSRRemoteErrorDomain, @"Succinct error messages failed");
    XCTAssertEqual([valError userInfo][NSRRequestObjectKey],r,@"Should include itself as the request");

    id valDict = [valError userInfo][NSRErrorResponseBodyKey];
    XCTAssertNotNil(valDict, @"Validation errors dict not compiled");
    XCTAssertTrue([valDict isKindOfClass:[NSDictionary class]], @"Object for validation key needs to be a dict");
    XCTAssertTrue([[[valDict allKeys] lastObject] isKindOfClass:[NSString class]], @"Keys in val dict need to be a string");
    XCTAssertTrue([[[valDict allValues] lastObject] isKindOfClass:[NSArray class]], @"Object in validation dict needs to be an array");
    XCTAssertTrue([[[[valDict allValues] lastObject] lastObject] isKindOfClass:[NSString class]], @"Object in array in validation dict needs to be a string");
    
    
    // 200 OK
    
    NSError *noError = [r errorForResponse:[MockServer ok200] existingError:nil statusCode:200];
    XCTAssertNil(noError, @"There should be no error for status code 200");
    
    // 201 Created
    
    NSError *noError2 = [r errorForResponse:[MockServer creation201] existingError:nil statusCode:201];
    XCTAssertNil(noError, @"There should be no error for status code 201");
    
    /* Try retrieving data from an Apple error message */
    [r routeTo:@"auth_error"];
    NSError *e;
    id val = [r sendSynchronous:&e];
    XCTAssertNil(val, @"There should be nil value for auth error");
    XCTAssertEqualObjects((e.userInfo)[NSRErrorResponseBodyKey], @{@"message": @"Test string"}, @"Should include 401 error message in userInfo");
    XCTAssertEqual([e userInfo][NSRRequestObjectKey],r,@"Should include itself as the request");
    
    /* Error for a response sent with JSON */
    NSDictionary *dict = @{@"key":@"val"};
    NSError *dictError = [r errorForResponse:dict existingError:nil statusCode:422];
    XCTAssertTrue(dict == dictError.userInfo[NSRErrorResponseBodyKey], @"Error response value did not match the response JSON");
    
    /* Try a bogus hostname */
    e = nil;
    [[NSRConfig defaultConfig] setRootURL:[NSURL URLWithString:@"http://ojeaoifjif"]];
    [[NSRRequest GET] sendSynchronous:&e];
    XCTAssertNotNil(e, @"Should error with bogus hostname");
}

- (void) test_authentication
{
    /** No user/pass (*/
    
    NSURL *url = [NSURL URLWithString:@"http://localhost:3000"];
    [[NSRConfig defaultConfig] setRootURL:url];
    
    NSRRequest *req = [NSRRequest GET];
    
    NSURLRequest *request = [req HTTPRequest];
    XCTAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no user/pass");

    /** OAuth **/
    
    for (int i = 0; i < 2; i++)
    {
        [NSRConfig defaultConfig].oAuthToken = @"token123";
        request = [req HTTPRequest];
        
        XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Authorization"], @"OAuth token123", @"Should send OAuth token");
        
        //should be identical if only one user/pass element is present (but still oauth)
        [[NSRConfig defaultConfig] setBasicAuthPassword:@"password"];
    }
    
    [NSRConfig defaultConfig].oAuthToken = nil;
    
    /** User/pass **/
    NSString *username = @"username";
    NSString *password = @"password";
    
    [[NSRConfig defaultConfig] setBasicAuthPassword:username];
    request = [req HTTPRequest];
    XCTAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no password");
    
    
    [[NSRConfig defaultConfig] setBasicAuthPassword:nil];
    [[NSRConfig defaultConfig] setBasicAuthUsername:username];
    request = [req HTTPRequest];
    XCTAssertNil([request valueForHTTPHeaderField:@"Authorization"], @"Shouldn't send w/authorization if no username");
    
    
    [[NSRConfig defaultConfig] setBasicAuthPassword:password];
    request = [req HTTPRequest];
    XCTAssertNotNil([request valueForHTTPHeaderField:@"Authorization"], @"Should send w/authorization if username+password");
    
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", username, password];
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [NSRRequest base64EncodingOfData:authData]];
    
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Authorization"], authHeader, @"Should send HTTP basic auth if given user/pass");
}

- (void) test_serialization
{
    NSString *file = [NSHomeDirectory() stringByAppendingPathComponent:@"test.dat"];

    NSRConfig *config = [[NSRConfig alloc] init];
    config.rootURL = [NSURL URLWithString:@"http://hi"];
    
    NSRRequest *req = [[NSRRequest GET] routeTo:@"hi"];
    req.config = config;
    req.body = @"test";
    
    req.queryParameters = @{@"t":@"hi"};
    req.additionalHTTPHeaders = @{@"t":@"hi"};
        
    XCTAssertTrue([NSKeyedArchiver archiveRootObject:req toFile:file], @"Archiving should've worked (serialize)");
    
    NSRRequest *req2 = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
    XCTAssertEqualObjects(req.httpMethod, req2.httpMethod, @"Should've carried over");    
    XCTAssertEqualObjects(req.route, req2.route, @"Should've carried over");    
    XCTAssertEqualObjects(req.queryParameters, req2.queryParameters, @"Should've carried over");    
    XCTAssertEqualObjects(req.additionalHTTPHeaders, req2.additionalHTTPHeaders, @"Should've carried over");    
    XCTAssertEqualObjects(req.config.rootURL, req2.config.rootURL, @"Should've carried over");
    XCTAssertEqualObjects(req.body, req2.body, @"Should've carried over");    
}

- (void) test_additional_headers
{
    [[NSRConfig defaultConfig] setRootURL:[NSURL URLWithString:@"http://localhost:3000"]];
    
    NSRRequest *req = [NSRRequest GET];
    req.additionalHTTPHeaders = @{@"test":@"hi"};
    NSURLRequest *request = [req HTTPRequest];
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"test"], @"hi", @"Should send custom key");

    req.additionalHTTPHeaders = @{@"test":@"hi",@"test2":@"hi"};
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"test2"], @"hi", @"Should send custom key");
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"test"], @"hi", @"Should still send custom key");

    req.additionalHTTPHeaders = nil;
    request = [req HTTPRequest];
    XCTAssertNil([request valueForHTTPHeaderField:@"test2"], @"Should've cleared custom key");
    XCTAssertNil([request valueForHTTPHeaderField:@"test"], @"Should've cleared custom key");
}

- (void) test_additional_config_headers
{
    [[NSRConfig defaultConfig] setRootURL:[NSURL URLWithString:@"http://localhost:3000"]];
    [[NSRConfig defaultConfig] setAdditionalHTTPHeaders:@{@"test":@"hi"}];
    
    NSRRequest *req = [NSRRequest GET];
    NSURLRequest *request = [req HTTPRequest];
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"test"], @"hi", @"Should send custom key");
    
    req.additionalHTTPHeaders = @{@"test2":@"hi"};
    request = [req HTTPRequest];
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"test2"], @"hi", @"Should send custom key");
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"test"], @"hi", @"Should still send custom key");
}

@end
