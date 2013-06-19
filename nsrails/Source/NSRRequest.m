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

#import "NSRails.h"

#import "NSRRequest.h"
#import "NSData+NSRBase64.h"


#if NSRLog > 0

#define NSRLogTagged(tag, ...)			\
NSLog(@"[NSRails][%@] %@", tag, [NSString stringWithFormat:__VA_ARGS__])

#define NSRLogInOut(inout, json, ...)	\
NSRLogTagged(inout, @"%@ %@", [NSString stringWithFormat:__VA_ARGS__],(NSRLog > 1) ? (json ? json : @"") : @"")

#else

#define NSRLogTagged(...)
#define NSRLogInOut(...)

#endif

@interface NSRRequest (private)

- (id) initWithHTTPMethod:(NSString *)method;

- (NSURLRequest *) HTTPRequest;

- (NSError *) serverErrorForResponse:(id)response statusCode:(NSInteger)statusCode;
- (NSError *) errorForResponse:(NSHTTPURLResponse *)response existingError:(NSError *)existing jsonResponse:(id)jsonResponse;
- (id) receiveResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError **)error;

@end

@implementation NSRRequest
@synthesize route, httpMethod, body, config, queryParameters, additionalHTTPHeaders;

# pragma mark - Convenient routing

- (id) routeTo:(NSString *)r
{
	route = r;
	return self;
}

- (id) routeToClass:(Class)c withCustomMethod:(NSString *)optionalRESTMethod
{
	self.config = [c config];

	NSString *controller = [c remoteControllerName];
	if (!controller)
		return [self routeTo:optionalRESTMethod];

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
	if (o.remoteID && !ignoreID)
		method = [[o.remoteID stringValue] stringByAppendingPathComponent:method];
	
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

# pragma mark - Factory requests

- (id) initWithHTTPMethod:(NSString *)method
{
    self = [super init];
    if (self)
    {
        config = [NSRConfig defaultConfig];
        httpMethod = method;
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
	if (!obj.remoteID)
		[NSException raise:NSRNullRemoteIDException format:@"Attempt to %@ a %@ with a nil remoteID.",str,[obj class]];
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
	NSString *appendedRoute = (route ? route : @"");
	if (queryParameters.count > 0)
	{
		NSMutableArray *params = [NSMutableArray arrayWithCapacity:queryParameters.count];
		[queryParameters enumerateKeysAndObjectsUsingBlock:
		 ^(id key, id obj, BOOL *stop) 
		 {
			 //TODO
			 //Escape to be RFC 1808 compliant
			 [params addObject:[NSString stringWithFormat:@"%@=%@",key,obj]];
		 }];
		appendedRoute = [appendedRoute stringByAppendingFormat:@"?%@",[params componentsJoinedByString:@"&"]];
	}
	
	NSURL *base = [NSURL URLWithString:self.config.appURL];
	if (!base)
	{
		[NSException raise:NSRMissingURLException format:@"No server root URL specified. Set your rails app's root with [[NSRConfig defaultConfig] setAppURL:] somewhere in your app setup."];
	}

	
	NSURL *url = [NSURL URLWithString:appendedRoute relativeToURL:base];
	
	NSRLogInOut(@"OUT", body, @"===> %@ to %@", httpMethod, [url absoluteString]);	
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
													   timeoutInterval:self.config.timeoutInterval];
	
	[request setHTTPMethod:httpMethod];
	[request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
	[additionalHTTPHeaders enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) 
     {
         [request setValue:obj forHTTPHeaderField:key];
     }];
	
	[self.config.additionalHTTPHeaders enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop)
     {
         [request setValue:obj forHTTPHeaderField:key];
     }];
	
	if (self.config.appUsername && self.config.appPassword)
	{
		//add auth header encoded in base64
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.config.appUsername, self.config.appPassword];
		NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
		NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [authData nsr_base64Encoding]];
		
		[request setValue:authHeader forHTTPHeaderField:@"Authorization"]; 
	}
	else if (self.config.appOAuthToken)
	{
		NSString *authHeader = [NSString stringWithFormat:@"OAuth %@", self.config.appOAuthToken];
		[request setValue:authHeader forHTTPHeaderField:@"Authorization"];
	}
	
  if (body)
  {
        NSData *data;
        if ([body isKindOfClass:[NSString class]])
		{
            data = [body dataUsingEncoding:NSUTF8StringEncoding];
            if (!additionalHTTPHeaders[@"Content-Type"])
            {
                [NSException raise:@"NSRRequest Error"
                            format:@"POST body was set as a string, but no Content-Type header was specific. Please use -[NSRRequest setAdditionalHTTPHeaders:...]"];
            }
        }
        else
		{
            //let it raise an exception if invalid json object
            data = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
            if (data)
            {
                [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];                
            }
        }
        [request setHTTPBody:data];
        [request setValue:[NSNumber numberWithUnsignedInteger:data.length].stringValue forHTTPHeaderField:@"Content-Length"];
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
	if (statusCode >= 0 && statusCode < 400)
        return nil;
	
	NSString *errorMessage = response;
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    //422 means there was a validation error
    if (statusCode == 422)
    {
        errorMessage = @"Unprocessable Entity";
    }
    else if (self.config.succinctErrorMessages)
	{
		//if error message is in HTML, parse between <pre></pre> or <h1></h1> for error message
		if ([response rangeOfString:@"</html>"].location != NSNotFound)
		{
			NSString *succinctText = [self findSubstringInString:response surroundedByTag:@"pre"];
			if (!succinctText)
				succinctText = [self findSubstringInString:response surroundedByTag:@"h1"];
			
			if (succinctText)
			{
				errorMessage = [succinctText stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
			}
		}
	}
    
    [userInfo setObject:errorMessage forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:NSRRemoteErrorDomain code:statusCode userInfo:userInfo];
}

- (id) jsonResponseFromData:(NSData *)data
{
	id jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                      options:NSJSONReadingAllowFragments | NSJSONReadingMutableContainers
                                                        error:nil];

	//TODO - workaround for bug with NSJSONReadingMutableContainers. it simply... doesn't work???
	if ([jsonResponse isKindOfClass:[NSArray class]] && ![jsonResponse isKindOfClass:[NSMutableArray class]])
		jsonResponse = [NSMutableArray arrayWithArray:jsonResponse];
	
	if (!jsonResponse)
		jsonResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

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
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:existing.userInfo];
	NSString *domain = existing.domain;
	NSInteger code = statusCode;
	
	// Add on some extra info in user info dict
	[userInfo setObject:self forKey:NSRRequestObjectKey];
	[userInfo setObject:jsonResponse forKey:NSRErrorResponseBodyKey];

	return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

- (id) sendSynchronous:(NSError **)errorOut
{
	NSURLRequest *request = [self HTTPRequest];
	
	NSError *appleError = nil;
	NSHTTPURLResponse *response = nil;
	
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&appleError];
	
	id jsonResponse = [self jsonResponseFromData:data];
	NSError *error = [self errorForResponse:jsonResponse existingError:appleError statusCode:response.statusCode];
	
	if (errorOut)
		*errorOut = error;

	return (error ? nil : jsonResponse);
}

- (void) performCompletionBlock:(void(^)(void))block
{
	if (self.config.performsCompletionBlocksOnMainThread)
	{
		dispatch_sync(dispatch_get_main_queue(), block);
	}
	else
	{
		block();
	}
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
		 
		 if (block)
			 [self performCompletionBlock:^{ block( (error ? nil : jsonResponse), error); }];
	 }];
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [self initWithHTTPMethod:[aDecoder decodeObjectForKey:@"httpMethod"]]))
    {
        route = [aDecoder decodeObjectForKey:@"route"];
        self.body = [aDecoder decodeObjectForKey:@"body"];
        self.config = [aDecoder decodeObjectForKey:@"config"];
        self.queryParameters = [aDecoder decodeObjectForKey:@"queryParameters"];
        self.additionalHTTPHeaders = [aDecoder decodeObjectForKey:@"additionalHTTPHeaders"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:route forKey:@"route"];
    [aCoder encodeObject:httpMethod forKey:@"httpMethod"];
    [aCoder encodeObject:body forKey:@"body"];
    [aCoder encodeObject:config forKey:@"config"];
    [aCoder encodeObject:queryParameters forKey:@"queryParameters"];
    [aCoder encodeObject:additionalHTTPHeaders forKey:@"additionalHTTPHeaders"];
}

@end
