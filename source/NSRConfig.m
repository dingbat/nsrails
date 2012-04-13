/*
 
 _|_|_|    _|_|_|  _|_|    _|_|  _|  _|    _|_|           
 _|  _|  _|_|_|    _|  _|  _|_|  _|  _|  _|_|_| 
 
 NSRConfig.m
 
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

#import "NSRConfig.h"

#import "NSRails+SBJson.h"
#import "NSData+Additions.h"

//NSRConfigStackElement implementation

//this small helper class is used to keep track of which config is contextually relevant
//a stack is used so that -[NSRConfig use] commands can be nested
//the problem with simply adding the NSRConfig to an NSMutableArray stack is that it will act funny if it's added multiple times (since an instance can only exist once in an array) and removing is even more of a nightmare

//the stack will be comprised of this element, whose sole purpose is to point to a config, meaning it can be pushed to the stack multiple times if needed be

@interface NSRConfigStackElement : NSObject
@property (nonatomic, assign) NSRConfig *config;
@end
@implementation NSRConfigStackElement
@synthesize config;
+ (NSRConfigStackElement *) elementForConfig:(NSRConfig *)c
{
	NSRConfigStackElement *element = [[NSRConfigStackElement alloc] init];
	element.config = c;
	return element;
}
@end




//NSRConfig implementation

@interface NSRConfig (private) 

- (NSString *) makeHTTPRequestWithRequest:(NSURLRequest *)request sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock;

@end

@implementation NSRConfig
@synthesize appURL, appUsername, appPassword;
@synthesize automaticallyInflects, managesNetworkActivityIndicator, timeoutInterval, ignoresClassPrefixes, succinctErrorMessages;

#pragma mark -
#pragma mark Config inits

static NSMutableDictionary *configEnvironments = nil;
static NSMutableArray *overrideConfigStack = nil;
static NSString *currentEnvironment = nil;

static int networkActivityRequests = 0;

//purely for test purposes
+ (void) resetConfigs
{
	//taken from static definitions above ^
	[configEnvironments removeAllObjects];
	[overrideConfigStack removeAllObjects];
	currentEnvironment = NSRConfigEnvironmentDevelopment;
}

+ (NSRConfig *) configForEnvironment: (NSString *)environment
{
	NSRConfig *config = [configEnvironments objectForKey:environment];
	if (!config)
	{
		config = [[NSRConfig alloc] init];
		[self setConfig:config asDefaultForEnvironment:environment];
	}
	return config;
}

+ (NSRConfig *) defaultConfig
{
	return [self configForEnvironment:[self currentEnvironment]];
}

+ (void) setConfig:(NSRConfig *)config asDefaultForEnvironment:(NSString *)environment
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		configEnvironments = [[NSMutableDictionary alloc] init];
	});
	
	if (config)
		[configEnvironments setObject:config forKey:environment];
}

+ (void) setConfigAsDefault:(NSRConfig *)config
{
	[self setConfig:config asDefaultForEnvironment:[self currentEnvironment]];
}

+ (void) setCurrentEnvironment:(NSString *)environment
{
	if (!environment)
		return;
	currentEnvironment = environment;
}

+ (NSString *) currentEnvironment
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		currentEnvironment = NSRConfigEnvironmentDevelopment;
	});
	return currentEnvironment;
}

- (id) init
{
	if ((self = [super init]))
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		
		//by default, set to accept datestring like "2012-02-01T00:56:24Z"
		//this format (ISO 8601) is default in rails
		self.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
		self.automaticallyInflects = YES;
		self.succinctErrorMessages = YES;
		self.timeoutInterval = 60;
		
		asyncOperationQueue = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (id) initWithAppURL:(NSString *)url
{
	if ((self = [self init]))
	{		
		[self setAppURL:url];
	}
	return self;
}

- (void) setAppURL:(NSString *)str
{
	if (!str)
	{
		appURL = nil;
		return;
	}
	
	//get rid of trailing / if it's there
	if (str.length > 0 && [[str substringFromIndex:str.length-1] isEqualToString:@"/"])
		str = [str substringToIndex:str.length-1];
	
	//add http:// if not included already
	NSString *http = (str.length < 7 ? nil : [str substringToIndex:7]);
	if (![http isEqualToString:@"http://"] && ![http isEqualToString:@"https:/"])
	{
		str = [@"http://" stringByAppendingString:str];
	}
	
	appURL = str;
}

#pragma mark - Date Formatting

- (void) setDateFormat:(NSString *)dateFormat
{
	[dateFormatter setDateFormat:dateFormat];
}

- (NSString *) dateFormat
{
	return dateFormatter.dateFormat;
}

- (NSString *) convertDateToString:(NSDate *)date
{
	return [dateFormatter stringFromDate:date];
}

- (NSDate *) convertStringToDate:(NSString *)string
{
	NSDate *date = [dateFormatter dateFromString:string];
	
	if (!date)
	{
		[NSException raise:NSRailsDateConversionException format:@"Attempted to convert remote date string (\"%@\") into an NSDate object, but conversion failed. Please check your config's dateFormat (used format \"%@\" for this operation).",string,dateFormatter.dateFormat];
		return nil;
	}
	
	return date;
}

#pragma mark -
#pragma mark HTTP stuff


//Do not override this method - it includes a check to see if there's no AppURL specified
- (NSString *) resultForRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock
{
#if TARGET_OS_IPHONE
	//manage network activity, currently only supported on async
	if (self.managesNetworkActivityIndicator && completionBlock)
	{
		networkActivityRequests++;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
#endif
	
	//make sure the app URL is set
	if (!self.appURL)
	{
		[NSException raise:@"NSRailsMissingURLException" format:@"No server root URL specified. Set your rails app's root with +[[NSRConfig defaultConfig] setAppURL:] somewhere in your app setup. (env=%@)", [NSRConfig currentEnvironment]];
		
		return nil;
	}
	
	NSRHTTPCompletionBlock blockPlusNetworkActivity = completionBlock;

#if TARGET_OS_IPHONE
	if (self.managesNetworkActivityIndicator && completionBlock)
	{
		blockPlusNetworkActivity = ^(NSString *data, NSError *error)
		{
			completionBlock(data, error);
			
			networkActivityRequests--;
			if (networkActivityRequests == 0)
			{
				[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			}
		};
	}
#endif
	
	//If you want to override handling the connection, override this method
	NSString *result = [self makeRequestType:type requestBody:requestStr route:route sync:error orAsync:blockPlusNetworkActivity];	
	return result;
}

- (void) logRequestWithBody:(NSString *)requestStr httpVerb:(NSString *)httpVerb url:(NSString *)url
{
#if NSRLog > 0
	NSLog(@" ");
	NSLog(@"%@ to %@",httpVerb,url);
#if NSRLog > 1
	NSLog(@"OUT===> %@",requestStr);
#endif
#endif
}

- (void) logResponse:(NSString *)response statusCode:(int)code
{
#if NSRLog == 1
	NSLog(@"<== Code %d",code);
#elif NSRLog > 1
	NSLog(@"IN<=== Code %d; %@\n\n",code,((code < 0 || code >= 400) ? @"[see ERROR]" : response));
	NSLog(@" ");
#endif
}

//Overide THIS method if necessary (for SSL etc)
- (NSString *) makeRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock
{	
	NSURLRequest *request = [self HTTPRequestForRequestType:type requestBody:requestStr route:route];
	
	[self logRequestWithBody:requestStr httpVerb:type url:[[request URL] absoluteString]];
	
	//send request using HTTP!
	NSString *result = [self makeHTTPRequestWithRequest:request sync:error orAsync:completionBlock];
	return result;
}

- (NSString *) makeHTTPRequestWithRequest:(NSURLRequest *)request sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock
{
	//ASYNC
	if (completionBlock)
	{
		[NSURLConnection sendAsynchronousRequest:request queue:asyncOperationQueue completionHandler:
		 ^(NSURLResponse *response, NSData *data, NSError *appleError) 
		 {
			 //if there's an error from the request there must have been an issue connecting to the server.
			 if (appleError)
			 {
				 NSRLogError(appleError);

				 completionBlock(nil,appleError);
			 }
			 else
			 {
				 NSInteger code = [(NSHTTPURLResponse *)response statusCode];
				 
				 NSString *rawResult = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
				 
#ifndef ARC_ENABLED
				 [rawResult autorelease];
#endif
				 
				 //int casting done to suppress Mac OS precision loss warnings
				 [self logResponse:rawResult statusCode:(int)code];
				 
				 //see if there's an error from this response using this helper method
				 NSError *railsError = [self errorForResponse:rawResult statusCode:code];
				 
				 if (railsError)
					 completionBlock(nil, railsError);
				 else
					 completionBlock(rawResult, nil);
			 }
		 }];
	}
	//SYNC
	else
	{
		NSError *appleError = nil;
		NSURLResponse *response = nil;

		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&appleError];
		
		//if there's an error here there must have been an issue connecting to the server.
		if (appleError)
		{
			NSRLogError(appleError);
			
			if (error)
				*error = appleError;
			
			return nil;
		}
		
		NSInteger code = [(NSHTTPURLResponse *)response statusCode];

		NSString *rawResult = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		
#ifndef ARC_ENABLED
		[rawResult autorelease];
#endif
		
		//int casting done to suppress Mac OS precision loss warnings
		[self logResponse:rawResult statusCode:(int)code];

		//see if there's an error from this response using this helper method
		NSError *railsError = [self errorForResponse:rawResult statusCode:[(NSHTTPURLResponse *)response statusCode]];
		if (railsError)
		{
			if (error)
				*error = railsError;
			
			return nil;
		}
		return rawResult;
	}
	return nil;
}


- (NSError *) errorForResponse:(NSString *)response statusCode:(NSInteger)statusCode
{
	BOOL err = (statusCode < 0 || statusCode >= 400);
	
	if (err)
	{
		if (self.succinctErrorMessages)
		{
			//if error message is in HTML,
			if ([response rangeOfString:@"</html>"].location != NSNotFound)
			{
				NSArray *pres = [response componentsSeparatedByString:@"<pre>"];
				if (pres.count > 1)
				{
					//get the value between <pre> and </pre>
					response = [[[pres objectAtIndex:1] componentsSeparatedByString:@"</pre"] objectAtIndex:0];
					//some weird thing rails does, will send html tags &quot; for quotes
					response = [response stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
				}
			}
		}
		
		NSMutableDictionary *inf = [NSMutableDictionary dictionaryWithObject:response
																	  forKey:NSLocalizedDescriptionKey];
		
		//422 means there was a validation error
		if (statusCode == 422)
		{
			NSDictionary *validationErrors = [response JSONValue];
			if (validationErrors)
				[inf setObject:validationErrors forKey:NSRValidationErrorsKey];
		}
		
		NSError *statusError = [NSError errorWithDomain:NSRRemoteErrorDomain
												   code:statusCode
											   userInfo:inf];
		
		NSRLogError(statusError);
		
		return statusError;
	}
	
	return nil;
}
				
- (NSURLRequest *) HTTPRequestForRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route
{
	NSString *url = [NSString stringWithFormat:@"%@/%@",appURL,route];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
														   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
													   timeoutInterval:timeoutInterval];
	
	[request setHTTPMethod:type];
	[request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	if (self.appUsername && self.appPassword)
	{
		//add auth header encoded in base64
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.appUsername, self.appPassword];
		NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
		NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
		
		[request setValue:authHeader forHTTPHeaderField:@"Authorization"]; 
	}
	
	if (requestStr)
	{
		NSData *requestData = [NSData dataWithBytes:[requestStr UTF8String] length:[requestStr length]];
		
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody: requestData];
		
		[request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
 	}
	
	return request;
}

#pragma mark -
#pragma mark Contextual stuff

+ (NSRConfig *) overrideConfig
{
	//return the last config on the stack (last in first out)
	//if stack is nil or empty, this will be nil, signifying that there's no overriding context
	
	return [[overrideConfigStack lastObject] config];
}

- (void) use
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		overrideConfigStack = [[NSMutableArray alloc] init];
	});
	
	// make a new stack element for this config (explained at top of the file) and push it to the stack

	NSRConfigStackElement *c = [NSRConfigStackElement elementForConfig:self];
	[overrideConfigStack addObject:c];
}

- (void) end
{
	//start at the end of the stack
	for (NSInteger i = overrideConfigStack.count-1; i >= 0; i--)
	{
		NSRConfigStackElement *c = [overrideConfigStack objectAtIndex:i];
		if (c.config == self)
		{
			[overrideConfigStack removeObjectAtIndex:i];
			break;
		}
	}
}

- (void) useIn:(void (^)(void))block
{
	[self use];
	block();
	[self end];
}

@end
