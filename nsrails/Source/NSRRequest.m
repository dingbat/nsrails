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
#import "NSData+Additions.h"


#if NSRLog > 0

#define NSRLogTagged(tag, ...)			\
NSLog(@"[NSRails][%@] %@", tag, [NSString stringWithFormat:__VA_ARGS__])

#define NSRLogInOut(inout, json, ...)	\
NSRLogTagged(inout, @"%@ %@", [NSString stringWithFormat:__VA_ARGS__],(NSRLog > 1) ? (json ? json : @"") : @"")

#else
#define NSRLogTagged(...)
#define NSRLogInOut(...)
#endif

@interface NSRRemoteObject (internal)

+ (NSRConfig *) getRelevantConfig;
- (NSRConfig *) getRelevantConfig;

+ (NSRPropertyCollection *) propertyCollection;
+ (NSString *) masterModelName;
+ (NSString *) masterPluralName;

+ (NSString *) routeForMethod:(NSString *)method withObject:(NSRRemoteObject *)obj httpMethod:(NSString *)verb;
- (NSString *) routeForInstanceMethod:(NSString *)customRESTMethod httpMethod:(NSString *)verb;
+ (NSString *) routeForControllerMethod:(NSString *)customRESTMethod;

@end

@interface NSRRequest (private)

- (NSURLRequest *) HTTPRequest;
- (NSError *) errorForResponse:(id)response statusCode:(NSInteger)statusCode;
- (id) receiveResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError **)error;

@end

@implementation NSRRequest
@synthesize route, httpMethod, body, config;

# pragma mark - Config

- (NSRConfig *) config
{
	//have a nil config be the default
	if (!config)
		return [NSRConfig defaultConfig];
	
	return config;
}

- (id) init
{
	if ((self = [super init]))
	{
		self.httpMethod = @"GET";
	}
	return self;
}

# pragma mark - Convenient routing

- (id) routeToClass:(Class)c withCustomMethod:(NSString *)optionalRESTMethod
{
	self.config = [c getRelevantConfig];
	self.route = [c routeForControllerMethod:optionalRESTMethod];
	
	return self;
}

- (id) routeToClass:(Class)c
{
	return [self routeToClass:c withCustomMethod:nil];
}

- (id) routeToObject:(NSRRemoteObject *)o withCustomMethod:(NSString *)optionalRESTMethod
{
	self.config = [o getRelevantConfig];
	self.route = [o routeForInstanceMethod:optionalRESTMethod httpMethod:httpMethod];
	
	return self;
}

- (id) routeToObject:(NSRRemoteObject *)o;
{
	return [self routeToObject:o withCustomMethod:nil];
}

- (void) setBodyToObject:(NSRRemoteObject *)obj
{
	self.body = [obj remoteDictionaryRepresentationWrapped:YES];
}

# pragma mark - Factory requests

+ (NSRRequest *) requestWithRoute:(NSString *)str
{
	NSRRequest *req = [[NSRRequest alloc] init];
	req.route = str;
	
	return req;
}

+ (NSRRequest *) requestWithHTTPMethod:(NSString *)method
{
	NSRRequest *req = [[NSRRequest alloc] init];
	req.httpMethod = method;
	
	return req;
}

+ (NSRRequest *) requestToFetchObjectWithID:(NSNumber *)rID ofClass:(Class)c
{
	if (!rID)
	{
		[NSException raise:NSInvalidArgumentException format:@"Attempt to fetch remote %@ objectWithID but ID passed in was nil.", c];
	}

	return [[NSRRequest requestWithHTTPMethod:@"GET"] routeToClass:c withCustomMethod:rID.stringValue];
}

+ (NSRRequest *) requestToFetchAllObjectsOfClass:(Class)c
{
	return [[NSRRequest requestWithHTTPMethod:@"GET"] routeToClass:c];
}


+ (void) assertPresentRemoteID:(NSRRemoteObject *)obj forMethod:(NSString *)str
{
	if (!obj.remoteID)
	{
		[NSException raise:NSRNullRemoteIDException format:@"Attempt to %@ a %@ with a nil remoteID.",str,[obj class]];
	}	
}

+ (NSRRequest *) requestToCreateObject:(NSRRemoteObject *)obj
{
	NSRRequest *req = [NSRRequest requestWithHTTPMethod:@"POST"];

	NSNumber *oldID = obj.remoteID;
	
	obj.remoteID = nil;
	[req routeToObject:obj];
	obj.remoteID = oldID;
	
	[req setBodyToObject:obj];
	return req;
}

+ (NSRRequest *) requestToFetchObject:(NSRRemoteObject *)obj
{
	[self assertPresentRemoteID:obj forMethod:@"fetch"];
	
	return [[NSRRequest requestWithHTTPMethod:@"GET"] routeToObject:obj];
}

+ (NSRRequest *) requestToDestroyObject:(NSRRemoteObject *)obj
{
	[self assertPresentRemoteID:obj forMethod:@"destroy"];

	return [[NSRRequest requestWithHTTPMethod:@"DELETE"] routeToObject:obj];
}

+ (NSRRequest *) requestToUpdateObject:(NSRRemoteObject *)obj
{
	[self assertPresentRemoteID:obj forMethod:@"update"];

	NSRRequest *req = [[[NSRRequest alloc] init] routeToObject:obj];
	
	//wait till config is set to set the update method - HTTP method depends on the config
	req.httpMethod = req.config.updateMethod;
	
	[req setBodyToObject:obj];
	
	return req;
}

+ (NSRRequest *) requestToReplaceObject:(NSRRemoteObject *)obj
{
	[self assertPresentRemoteID:obj forMethod:@"replace"];

	NSRRequest *req = [[NSRRequest requestWithHTTPMethod:@"PUT"] routeToObject:obj];
	[req setBodyToObject:obj];
	return req;
}

# pragma mark - Making the request

- (NSURLRequest *) HTTPRequest
{	
	if (!self.config.appURL)
	{
		[NSException raise:NSRMissingURLException format:@"No server root URL specified. Set your rails app's root with +[[NSRConfig defaultConfig] setAppURL:] somewhere in your app setup. (env=%@)", [NSRConfig currentEnvironment]];
		
		return nil;
	}

	NSURL *url = [NSURL URLWithString:self.config.appURL];
	if (route)
		url = [url URLByAppendingPathComponent:route];
	
	NSRLogInOut(@"OUT", body, @"===> %@ to %@", httpMethod, url);	
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
													   timeoutInterval:self.config.timeoutInterval];
	
	[request setHTTPMethod:httpMethod];
	[request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	if (self.config.appUsername && self.config.appPassword)
	{
		//add auth header encoded in base64
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.config.appUsername, self.config.appPassword];
		NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
		NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
		
		[request setValue:authHeader forHTTPHeaderField:@"Authorization"]; 
	}
	else if (self.config.appOAuthToken)
	{
		NSString *authHeader = [NSString stringWithFormat:@"OAuth %@", self.config.appOAuthToken];
		[request setValue:authHeader forHTTPHeaderField:@"Authorization"];
	}
	
	if (body)
	{
		//let it raise an exception if invalid json object
		NSError *e = nil;
		NSData *data = [NSJSONSerialization dataWithJSONObject:body options:0 error:&e];
		
		if (data)
		{
			[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
			[request setHTTPBody:data];
			
			[request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
		}
 	}
	
	return request;
}

- (NSError *) errorForResponse:(id)response statusCode:(NSInteger)statusCode
{
	BOOL err = (statusCode < 0 || statusCode >= 400);
	
	if (err)
	{
		NSMutableDictionary *inf = [NSMutableDictionary dictionary];
		
		//422 means there was a validation error
		if (statusCode == 422)
		{
			if ([response isKindOfClass:[NSDictionary class]])
				[inf setObject:response forKey:NSRValidationErrorsKey];
			[inf setObject:@"Unprocessable Entity" forKey:NSLocalizedDescriptionKey];
		}
		else 
		{
			if (self.config.succinctErrorMessages)
			{
				//if error message is in HTML,
				if ([response rangeOfString:@"</html>"].location != NSNotFound)
				{
					NSArray *pres = [response componentsSeparatedByString:@"<pre>"];
					if (pres.count > 1)
					{
						//get the value between <pre> and </pre>
						response = [[[pres objectAtIndex:1] componentsSeparatedByString:@"</pre"] objectAtIndex:0];
					}
					else
					{
						NSArray *h1s = [response componentsSeparatedByString:@"<h1>"];
						if (h1s.count > 1)
						{
							//get the value between <h1> and </h1>
							response = [[[h1s objectAtIndex:1] componentsSeparatedByString:@"</h1"] objectAtIndex:0];
						}
					}
					response = [response stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
				}
			}
			[inf setObject:response forKey:NSLocalizedDescriptionKey];
		}
		
		NSError *error = [NSError errorWithDomain:NSRRemoteErrorDomain
											 code:statusCode
										 userInfo:inf];
		
		return error;
	}
	
	return nil;
}

- (id) receiveResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError **)error
{
	NSInteger code = [(NSHTTPURLResponse *)response statusCode];
	
	id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments | NSJSONReadingMutableContainers error:nil];
	
	//right now there's a bug with NSJSONReadingMutableContainers. it simply... doesn't work???
	if ([jsonResponse isKindOfClass:[NSArray class]] && ![jsonResponse isKindOfClass:[NSMutableArray class]])
		jsonResponse = [NSMutableArray arrayWithArray:jsonResponse];
	
	if (!jsonResponse)
		jsonResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	//see if there's an error from this response using this helper method
	NSError *railsError = [self errorForResponse:jsonResponse statusCode:code];
	
	NSRLogInOut(@"IN", railsError ? @"" : jsonResponse, @"<=== Code %d; %@", (int)code, railsError ? railsError : @"");
	
	if (railsError)
	{
		
		if (error)
			*error = railsError;
		
		return nil;
	}
	
	return jsonResponse;
}

- (id) sendSynchronous:(NSError **)error
{
	NSURLRequest *request = [self HTTPRequest];
	
	NSError *appleError = nil;
	NSHTTPURLResponse *response = nil;
	
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&appleError];
	
	//if there's an error here there must have been an issue connecting to the server.
	if (appleError)
	{
		NSRLogTagged(@"connection", @"%@", appleError);
		
		if (error)
			*error = appleError;
		
		return nil;
	}
	
	return [self receiveResponse:response data:data error:error];
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
		 
		 dispatch_queue_t queue = (self.config.performsCompletionBlocksOnMainThread ? 
								   dispatch_get_main_queue() : dispatch_get_current_queue());
		 
		 //if there's an error from the request there must have been an issue connecting to the server.
		 if (appleError)
		 {
			 NSRLogTagged(@"connection", @"%@", appleError);
			 
			 dispatch_sync(queue, ^{ block(nil, appleError); } );
		 }
		 else
		 {
			 NSError *e = nil;
			 id jsonResp = [self receiveResponse:(NSHTTPURLResponse *)response data:data error:&e];
			 
			 dispatch_sync(queue, ^{ block((e ? nil : jsonResp), e); } );
		 }
	 }];
}

@end
