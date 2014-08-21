/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRRequest.m
 
 Copyright (c) 2012 Dan Hassin.
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <NSRails/NSRails.h>
#import "NSRRequest.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h> //UIKit needed for managing activity indicator
#endif

NSString * const NSRRequestObjectKey        = @"NSRRequestObjectKey";
NSString * const NSRErrorResponseBodyKey    = @"NSRErrorResponseBodyKey";

NSString * const NSRRemoteErrorDomain       = @"NSRRemoteErrorDomain";
NSString * const NSRMissingURLException     = @"NSRMissingURLException";
NSString * const NSRNullRemoteIDException   = @"NSRNullRemoteIDException";

@interface NSRRequest (private)

- (id) initWithHTTPMethod:(NSString *)method;

- (NSURLRequest *) HTTPRequest;

- (NSError *) serverErrorForResponse:(id)response statusCode:(NSInteger)statusCode;
- (NSError *) errorForResponse:(NSHTTPURLResponse *)response existingError:(NSError *)existing jsonResponse:(id)jsonResponse;
- (id) receiveResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError **)error;

@end

@implementation NSRRequest

# pragma mark - Convenient routing

- (id) routeTo:(NSString *)r
{
    _route = r;
    return self;
}

- (id) routeToClass:(Class)c withCustomMethod:(NSString *)optionalRESTMethod
{
    self.config = [c config];

    NSString *controller = [c remoteControllerName];
    if (!controller) {
        return [self routeTo:optionalRESTMethod];
    }

    return [self routeTo:[controller stringByAppendingPathComponent:optionalRESTMethod]];
}

- (id) routeToClass:(Class)c
{
    return [self routeToClass:c withCustomMethod:nil];
}

- (id) routeToObject:(NSRRemoteObject *)o withCustomMethod:(NSString *)method ignoreID:(BOOL)ignoreID
{
    self.config = [o.class config];
    
    //prepend the ID: action -> 1/action
    if (o.remoteID && !ignoreID) {
        method = [[o.remoteID stringValue] stringByAppendingPathComponent:method];
    }
    
    //prepend the classname: 1/action -> class/1/action
    [self routeToClass:[o class] withCustomMethod:method];
    
    NSRRemoteObject *prefix = [o objectUsedToPrefixRequest:self];
    if (prefix)
    {
        if (!prefix.remoteID)
        {
            [NSException raise:NSRNullRemoteIDException format:@"Attempt to %@ %@ instance with a prefix association (%@ instance) that has a nil remoteID.",self.httpMethod ? self.httpMethod : @"remotely access",[o class],[prefix class]];
        }
        
        //if prefix, prepend the route to prefix: class/1/action -> prefixes/15/class/1/action (+ recursive)
        [self routeToObject:prefix withCustomMethod:self.route];
    }
    
    return self;
}

- (id) routeToObject:(NSRRemoteObject *)o withCustomMethod:(NSString *)method
{
    return [self routeToObject:o withCustomMethod:method ignoreID:NO];
}

- (id) routeToObject:(NSRRemoteObject *)o ignoreID:(BOOL)ignore
{
    return [self routeToObject:o withCustomMethod:nil ignoreID:ignore];
}

- (id) routeToObject:(NSRRemoteObject *)o
{
    return [self routeToObject:o withCustomMethod:nil];
}

- (void) setBodyToObject:(NSRRemoteObject *)obj
{
    self.body = [obj remoteDictionaryRepresentationWrapped:YES];
}

- (void) setBody:(id)body
{
    if (body && ![body isKindOfClass:[NSString class]] && ![NSJSONSerialization isValidJSONObject:body]) {
        [NSException raise:NSInvalidArgumentException format:@"NSRRequest body is not a valid top-level JSON object (only array or dictionary allowed)."];
    }
    
    _body = body;
}

# pragma mark - Factory requests

- (id) initWithHTTPMethod:(NSString *)method
{
    self = [super init];
    if (self)
    {
        _httpMethod = method;
        self.config = [NSRConfig defaultConfig];
    }
    
    return self;
}

+ (NSRRequest *) GET
{
    return [[self alloc] initWithHTTPMethod:@"GET"];
}

+ (NSRRequest *) DELETE
{
    return [[self alloc] initWithHTTPMethod:@"DELETE"];    
}

+ (NSRRequest *) POST
{
    return [[self alloc] initWithHTTPMethod:@"POST"];
}

+ (NSRRequest *) PUT
{
    return [[self alloc] initWithHTTPMethod:@"PUT"];
}

+ (NSRRequest *) PATCH
{
    return [[self alloc] initWithHTTPMethod:@"PATCH"];
}


+ (NSRRequest *) requestToFetchObjectWithID:(NSNumber *)rID ofClass:(Class)c
{
    if (!rID)
    {
        [NSException raise:NSInvalidArgumentException format:@"Attempt to fetch remote %@ objectWithID but ID passed in was nil.", c];
    }

    return [[NSRRequest GET] routeToClass:c withCustomMethod:rID.stringValue];
}

+ (NSRRequest *) requestToFetchAllObjectsOfClass:(Class)c
{
    return [[NSRRequest GET] routeToClass:c];
}

+ (NSRRequest *) requestToFetchAllObjectsOfClass:(Class)c viaObject:(NSRRemoteObject *)obj
{
    if (!obj)
    {
        return [NSRRequest requestToFetchAllObjectsOfClass:c];
    }
    else if (!obj.remoteID)
    {
        [NSException raise:NSRNullRemoteIDException format:@"Attempt to fetch all %@s via object %@, but the object's remoteID was nil.",[self class],[obj class]];
    }
    
    return [[NSRRequest GET] routeToObject:obj withCustomMethod:[c remoteControllerName]];
}

+ (void) assertPresentRemoteID:(NSRRemoteObject *)obj forMethod:(NSString *)str
{
    if (!obj.remoteID) {
        [NSException raise:NSRNullRemoteIDException format:@"Attempt to %@ a %@ with a nil remoteID.",str,[obj class]];
    }
}

+ (NSRRequest *) requestToCreateObject:(NSRRemoteObject *)obj
{
    NSRRequest *req = [[NSRRequest POST] routeToObject:obj ignoreID:YES];    
    [req setBodyToObject:obj];
    return req;
}

+ (NSRRequest *) requestToFetchObject:(NSRRemoteObject *)obj
{
    [self assertPresentRemoteID:obj forMethod:@"fetch"];
    
    return [[NSRRequest GET] routeToObject:obj];
}

+ (NSRRequest *) requestToDestroyObject:(NSRRemoteObject *)obj
{
    [self assertPresentRemoteID:obj forMethod:@"destroy"];

    return [[NSRRequest DELETE] routeToObject:obj];
}

+ (NSRRequest *) requestToUpdateObject:(NSRRemoteObject *)obj
{
    [self assertPresentRemoteID:obj forMethod:@"update"];

    NSRRequest *req = [[NSRRequest alloc] initWithHTTPMethod:[obj.class config].updateMethod];
    [req routeToObject:obj];
    [req setBodyToObject:obj];
    
    return req;
}

+ (NSRRequest *) requestToReplaceObject:(NSRRemoteObject *)obj
{
    [self assertPresentRemoteID:obj forMethod:@"replace"];

    NSRRequest *req = [[NSRRequest PUT] routeToObject:obj];
    [req setBodyToObject:obj];
    return req;
}

# pragma mark - Making the request

- (NSURLRequest *) HTTPRequest
{    
    NSString *appendedRoute = (self.route ?: @"");
    if (self.queryParameters.count > 0)
    {
        NSMutableArray *params = [NSMutableArray arrayWithCapacity:self.queryParameters.count];
        [self.queryParameters enumerateKeysAndObjectsUsingBlock:
         ^(id key, id obj, BOOL *stop) 
         {
             //TODO: Escape to be RFC 1808 compliant
             [params addObject:[NSString stringWithFormat:@"%@=%@",key,obj]];
         }];
        appendedRoute = [appendedRoute stringByAppendingFormat:@"?%@",[params componentsJoinedByString:@"&"]];
    }
    
    if (!self.config.rootURL)
    {
        [NSException raise:NSRMissingURLException format:@"No server root URL specified. Set your rails app's root with [[NSRConfig defaultConfig] setRootURL:] somewhere in your app setup."];
    }

    
    NSURL *url = [NSURL URLWithString:appendedRoute relativeToURL:self.config.rootURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                                       timeoutInterval:self.config.timeoutInterval];
    
    [request setHTTPMethod:self.httpMethod];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [self.additionalHTTPHeaders enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) {
         [request setValue:obj forHTTPHeaderField:key];
     }];
    
    [self.config.additionalHTTPHeaders enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) {
         [request setValue:obj forHTTPHeaderField:key];
     }];
    
    if (self.config.basicAuthUsername && self.config.basicAuthPassword)
    {
        //add auth header encoded in base64
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.config.basicAuthUsername, self.config.basicAuthPassword];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [NSRRequest base64EncodingOfData:authData]];
        
        [request setValue:authHeader forHTTPHeaderField:@"Authorization"]; 
    }
    else if (self.config.oAuthToken)
    {
        NSString *authHeader = [NSString stringWithFormat:@"OAuth %@", self.config.oAuthToken];
        [request setValue:authHeader forHTTPHeaderField:@"Authorization"];
    }
    
    if (self.body)
    {
        NSData *data;
      
        if ([self.body isKindOfClass:[NSString class]])
        {
            if (!self.additionalHTTPHeaders[@"Content-Type"]) {
                [NSException raise:@"NSRRequest Error"
                            format:@"POST body is a string, but no Content-Type header was specified. Please use -[NSRRequest setAdditionalHTTPHeaders:...]"];
            }

            data = [self.body dataUsingEncoding:NSUTF8StringEncoding];
        }
        else
        {
            data = [NSJSONSerialization dataWithJSONObject:self.body options:0 error:nil];
        }
      
        if (data)
        {
            [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:data];
            [request setValue:@(data.length).stringValue forHTTPHeaderField:@"Content-Length"];
        }
    }
    
    return request;
}

- (NSString *) findSubstringInString:(NSString *)string surroundedByTag:(NSString *)tag
{
    NSUInteger start = [string rangeOfString:[NSString stringWithFormat:@"<%@>",tag]].location;
    if (start != NSNotFound)
    {
        start += tag.length+2; //offset the "<pre>"
        NSUInteger end = [[string substringFromIndex:start] rangeOfString:[NSString stringWithFormat:@"</%@>",tag]].location;
        return [string substringWithRange:NSMakeRange(start, end)];
    }

    return nil;
}

- (NSError *) serverErrorForResponse:(id)response statusCode:(NSInteger)statusCode
{
    //everything ok
    if (statusCode >= 0 && statusCode < 400) {
        return nil;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    if ([response isKindOfClass:[NSString class]])
    {
        if (self.config.succinctErrorMessages)
        {
            //if error message is in HTML, parse between <pre></pre> or <h1></h1> for error message
            if ([response rangeOfString:@"</html>"].location != NSNotFound)
            {
                NSString *succinctText = [self findSubstringInString:response surroundedByTag:@"pre"];
                if (!succinctText) {
                    succinctText = [self findSubstringInString:response surroundedByTag:@"h1"];
                }
                
                if (succinctText)
                {
                    response = [succinctText stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
                }
            }
        }

        userInfo[NSLocalizedDescriptionKey] = response;
    }
    
    return [NSError errorWithDomain:NSRRemoteErrorDomain code:statusCode userInfo:userInfo];
}

- (id) jsonResponseFromData:(NSData *)data
{
    if (!data) {
        return nil;
    }
    
    id jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                      options:NSJSONReadingAllowFragments | NSJSONReadingMutableContainers
                                                        error:nil];
    
    //TODO - workaround for bug with NSJSONReadingMutableContainers. it simply... doesn't work???
    if ([jsonResponse isKindOfClass:[NSArray class]] && ![jsonResponse isKindOfClass:[NSMutableArray class]]) {
        jsonResponse = [NSMutableArray arrayWithArray:jsonResponse];
    }
    
    if (!jsonResponse) {
        jsonResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }

    return jsonResponse;
}

- (NSError *) errorForResponse:(id)jsonResponse existingError:(NSError *)existing statusCode:(NSInteger)statusCode
{
    if (!existing)
    {
        existing = [self serverErrorForResponse:jsonResponse statusCode:statusCode];
    }
    
    if (!existing)
    {
        // No errors
        return nil;
    }
    
    // Add on some extra info in user info dict
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:existing.userInfo];
    userInfo[NSRRequestObjectKey] = self;
    if (jsonResponse) {
        userInfo[NSRErrorResponseBodyKey] = jsonResponse;
    }

    return [NSError errorWithDomain:existing.domain code:existing.code userInfo:userInfo];
}

- (id) sendSynchronous:(NSError **)errorOut
{
    NSURLRequest *request = [self HTTPRequest];
    
    NSError *appleError = nil;
    NSHTTPURLResponse *response = nil;
    
    [self logOut:request];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&appleError];
    
    id jsonResponse = [self jsonResponseFromData:data];
    NSError *error = [self errorForResponse:jsonResponse existingError:appleError statusCode:response.statusCode];
    
    [self logIn:jsonResponse response:response error:error];
    
    if (errorOut) {
        *errorOut = error;
    }

    return (error ? nil : jsonResponse);
}

- (void) sendAsynchronous:(NSRHTTPCompletionBlock)block
{
#if TARGET_OS_IPHONE
    static int networkActivityRequests = 0;
    
    if (self.config.managesNetworkActivityIndicator)
    {
        networkActivityRequests++;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
#endif

    static NSOperationQueue *asyncOperationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        asyncOperationQueue = [[NSOperationQueue alloc] init];
    });
    
    NSURLRequest *request = [self HTTPRequest];
    [self logOut:request];

    [NSURLConnection sendAsynchronousRequest:request queue:asyncOperationQueue completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *appleError) 
     {
#if TARGET_OS_IPHONE
         if (self.config.managesNetworkActivityIndicator)
         {
             networkActivityRequests--;
             if (networkActivityRequests == 0)
             {
                 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
             }
         }
#endif
         id jsonResponse = [self jsonResponseFromData:data];
         NSError *error = [self errorForResponse:jsonResponse existingError:appleError statusCode:[(NSHTTPURLResponse *)response statusCode]];
         
         [self logIn:jsonResponse response:(NSHTTPURLResponse *)response error:error];
         
         if (error) {
             jsonResponse = nil;
         }
         
         if (block) {
             if (self.config.performsCompletionBlocksOnMainThread) {
                 dispatch_async(dispatch_get_main_queue(), ^{ block(jsonResponse, error); });
             }
             else {
                 block(jsonResponse, error);
             }
         }
     }];
}

#pragma mark - Logging

- (NSString *) prettyPrintedJSONFromObject:(id)object
{
    if (object) {
        if ([object isKindOfClass:[NSString class]]) {
            return object;
        }
        else {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return nil;
}

- (void) logOut:(NSURLRequest *)request
{
    if (self.config.networkLogging) {
        NSString *json = [self prettyPrintedJSONFromObject:self.body];
        NSLog(@"[NSRails][OUT] ===> %@ to %@ %@", self.httpMethod, [request.URL absoluteString], json ?: @"");
    }
}

- (void) logIn:(id)jsonObj response:(NSHTTPURLResponse *)response error:(NSError *)error
{
    if (self.config.networkLogging) {
        NSString *json = [self prettyPrintedJSONFromObject:jsonObj];
        NSLog(@"[NSRails][IN] <=== Code %d %@", (int)response.statusCode, error ?: json ?: @"");
    }
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [self initWithHTTPMethod:[aDecoder decodeObjectForKey:@"httpMethod"]]))
    {
        _route = [aDecoder decodeObjectForKey:@"route"];
        self.body = [aDecoder decodeObjectForKey:@"body"];
        self.config = [aDecoder decodeObjectForKey:@"config"];
        self.queryParameters = [aDecoder decodeObjectForKey:@"queryParameters"];
        self.additionalHTTPHeaders = [aDecoder decodeObjectForKey:@"additionalHTTPHeaders"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.route forKey:@"route"];
    [aCoder encodeObject:self.httpMethod forKey:@"httpMethod"];
    [aCoder encodeObject:self.body forKey:@"body"];
    [aCoder encodeObject:self.config forKey:@"config"];
    [aCoder encodeObject:self.queryParameters forKey:@"queryParameters"];
    [aCoder encodeObject:self.additionalHTTPHeaders forKey:@"additionalHTTPHeaders"];
}

#pragma mark - Base64 Helper

+ (NSString *) base64EncodingOfData:(NSData *)data
{
    static char encodingTable[64] = {
        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
        'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
        'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
        'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/' };

    const unsigned char *bytes = [data bytes];
    NSMutableString *result = [NSMutableString stringWithCapacity:[data length]];
    unsigned long ixtext = 0;
    unsigned long lentext = [data length];
    long ctremaining = 0;
    unsigned char inbuf[3], outbuf[4];
    unsigned short i = 0;
    unsigned short charsonline = 0, ctcopy = 0;
    unsigned long ix = 0;
    
    while( YES ) {
        ctremaining = lentext - ixtext;
        if( ctremaining <= 0 ) break;
        
        for( i = 0; i < 3; i++ ) {
            ix = ixtext + i;
            if( ix < lentext ) inbuf[i] = bytes[ix];
            else inbuf [i] = 0;
        }
        
        outbuf [0] = (inbuf [0] & 0xFC) >> 2;
        outbuf [1] = ((inbuf [0] & 0x03) << 4) | ((inbuf [1] & 0xF0) >> 4);
        outbuf [2] = ((inbuf [1] & 0x0F) << 2) | ((inbuf [2] & 0xC0) >> 6);
        outbuf [3] = inbuf [2] & 0x3F;
        ctcopy = 4;
        
        switch( ctremaining ) {
            case 1:
                ctcopy = 2;
                break;
            case 2:
                ctcopy = 3;
                break;
        }
        
        for( i = 0; i < ctcopy; i++ )
            [result appendFormat:@"%c", encodingTable[outbuf[i]]];
        
        for( i = ctcopy; i < 4; i++ )
            [result appendString:@"="];
        
        ixtext += 3;
        charsonline += 4;
    }
    
    return [NSString stringWithString:result];
}

@end
