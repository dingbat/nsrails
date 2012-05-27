/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
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


//Environments
NSString * const NSRConfigEnvironmentDevelopment		= @"NSRConfigEnvironmentDevelopment";
NSString * const NSRConfigEnvironmentProduction			= @"NSRConfigEnvironmentProduction";


NSString * const NSRValidationErrorsKey					= @"NSRValidationErrorsKey";

NSString * const NSRRemoteErrorDomain				= @"NSRRemoteErrorDomain";
NSString * const NSRMapException					= @"NSRMapException";
NSString * const NSRJSONParsingException			= @"NSRJSONParsingException";
NSString * const NSRInternalError					= @"NSRInternalError";
NSString * const NSRMissingURLException				= @"NSRMissingURLException";
NSString * const NSRNullRemoteIDException			= @"NSRNullRemoteIDException";


// Logging

                     //undefined, NSRails will log nothing
//#define NSRLog 1   //As 1, NSRails will log HTTP verbs with their outgoing URLs and any server errors being returned.
#define NSRLog 2     //As 2, NSRails will also log any JSON going out/coming in.


#if NSRLog > 0
#define NSRLogError(x)	NSLog(@"%@",x);
#else
#define NSRLogError(x)
#endif


@implementation NSRConfig
@synthesize appURL, appUsername, appPassword;
@synthesize autoinflectsClassNames, autoinflectsPropertyNames, managesNetworkActivityIndicator, timeoutInterval, ignoresClassPrefixes, succinctErrorMessages, performsCompletionBlocksOnMainThread, managedObjectContext;
@dynamic dateFormat;

#pragma mark -
#pragma mark Config inits

static NSMutableDictionary *configEnvironments = nil;
static NSMutableArray *overrideConfigStack = nil;
static NSString *currentEnvironment = nil;

//purely for test purposes
+ (void) resetConfigs
{
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
		
		self.autoinflectsClassNames = YES;
		self.autoinflectsPropertyNames = YES;
		self.ignoresClassPrefixes = YES;
		
		self.succinctErrorMessages = YES;
		self.timeoutInterval = 60.0f;
		self.performsCompletionBlocksOnMainThread = YES;
		
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


#pragma mark - Date Formatting

- (void) setDateFormat:(NSString *)dateFormat
{
	[dateFormatter setDateFormat:dateFormat];
}

- (NSString *) dateFormat
{
	return dateFormatter.dateFormat;
}

- (NSString *) stringFromDate:(NSDate *)date
{
	return [dateFormatter stringFromDate:date];
}

- (NSDate *) dateFromString:(NSString *)string
{
	NSDate *date = [dateFormatter dateFromString:string];
	
	if (!date && string)
	{
		[NSException raise:NSRInternalError format:@"Attempted to convert remote date string (\"%@\") into an NSDate object, but conversion failed. Please check your config's dateFormat (used format \"%@\" for this operation).",string,dateFormatter.dateFormat];
		return nil;
	}
	
	return date;
}




#pragma mark -
#pragma mark HTTP stuff


//Do not override this method - it includes a check to see if there's no AppURL specified
- (id) makeRequest:(NSString *)httpVerb requestBody:(id)body route:(NSString *)route sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock
{
#if TARGET_OS_IPHONE
	static int networkActivityRequests = 0;

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
		[NSException raise:NSRMissingURLException format:@"No server root URL specified. Set your rails app's root with +[[NSRConfig defaultConfig] setAppURL:] somewhere in your app setup. (env=%@)", [NSRConfig currentEnvironment]];
		
		return nil;
	}
	
	NSRHTTPCompletionBlock blockPlusNetworkActivity = completionBlock;
	
#if TARGET_OS_IPHONE
	if (self.managesNetworkActivityIndicator && completionBlock)
	{
		blockPlusNetworkActivity = ^(id jsonRep, NSError *error)
		{
			completionBlock(jsonRep, error);
			
			networkActivityRequests--;
			if (networkActivityRequests == 0)
			{
				[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			}
		};
	}
#endif
	
	NSString *url = [NSString stringWithFormat:@"%@/%@",appURL,route ? route : @""];
	
#if NSRLog > 0
	NSLog(@" ");
	NSLog(@"%@ to %@",httpVerb,url);
#if NSRLog > 1
	NSLog(@"OUT===> %@",body);
#endif
#endif
	
	//If you want to override handling the connection, override the following method	
	NSDictionary *result = [self responseForRequestType:httpVerb requestBody:body url:url sync:error orAsync:blockPlusNetworkActivity];	
	return result;
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
		
		NSRLogError(error);
		
		return error;
	}
	
	return nil;
}


- (id) receiveResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError **)error
{
	NSInteger code = [(NSHTTPURLResponse *)response statusCode];
	
	NSLog(@"IN<=== Code %d;",(int)code);
	
	id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
	if (!jsonResponse)
		jsonResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	//see if there's an error from this response using this helper method
	NSError *railsError = [self errorForResponse:jsonResponse statusCode:code];
	if (railsError)
	{
		if (error)
			*error = railsError;
		
		return nil;
	}

	
#if NSRLog > 1
	NSLog(@"  <=== %@",jsonResponse);
#endif
	
	return jsonResponse;
}

//Overide THIS method if necessary (for SSL etc)
- (id) responseForRequestType:(NSString *)type requestBody:(id)body url:(NSString *)url sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock
{
	NSURLRequest *request = [self HTTPRequestForRequestType:type requestBody:body url:url];
	
	//ASYNC
	if (completionBlock)
	{
		[NSURLConnection sendAsynchronousRequest:request queue:asyncOperationQueue completionHandler:
		 ^(NSURLResponse *response, NSData *data, NSError *appleError) 
		 {
			 dispatch_queue_t queue = (self.performsCompletionBlocksOnMainThread ? 
									   dispatch_get_main_queue() : dispatch_get_current_queue());
			 
			 //if there's an error from the request there must have been an issue connecting to the server.
			 if (appleError)
			 {
				 NSRLogError(appleError);
				 
				 dispatch_sync(queue, ^{ completionBlock(nil, appleError); } );
			 }
			 else
			 {
				 NSError *e = nil;
				 id jsonResp = [self receiveResponse:(NSHTTPURLResponse *)response data:data error:&e];
				 				 
				 dispatch_sync(queue, ^{ completionBlock((e ? nil : jsonResp), e); } );
			 }
		 }];
	}
	//SYNC
	else
	{
		NSError *appleError = nil;
		NSHTTPURLResponse *response = nil;
		
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&appleError];
		
		//if there's an error here there must have been an issue connecting to the server.
		if (appleError)
		{
			NSRLogError(appleError);
			
			if (error)
				*error = appleError;
			
			return nil;
		}
		
		return [self receiveResponse:response data:data error:error];
	}
	return nil;
}
			
- (NSURLRequest *) HTTPRequestForRequestType:(NSString *)type requestBody:(id)body url:(NSString *)url
{	
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

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		asyncOperationQueue = [[NSOperationQueue alloc] init];
		
		self.dateFormat = [aDecoder decodeObjectForKey:@"dateFormat"];
		
		self.autoinflectsClassNames = [aDecoder decodeBoolForKey:@"autoinflectsClassNames"];
		self.autoinflectsPropertyNames = [aDecoder decodeBoolForKey:@"autoinflectsPropertyNames"];
		self.ignoresClassPrefixes = [aDecoder decodeBoolForKey:@"ignoresClassPrefixes"];

		self.succinctErrorMessages = [aDecoder decodeBoolForKey:@"succinctErrorMessages"];
		self.performsCompletionBlocksOnMainThread = [aDecoder decodeBoolForKey:@"performsCompletionBlocksOnMainThread"];
		self.timeoutInterval = [aDecoder decodeDoubleForKey:@"timeoutInterval"];

		self.managesNetworkActivityIndicator = [aDecoder decodeBoolForKey:@"managesNetworkActivityIndicator"];

		self.appURL = [aDecoder decodeObjectForKey:@"appURL"];
		self.appUsername = [aDecoder decodeObjectForKey:@"appUsername"];
		self.appPassword = [aDecoder decodeObjectForKey:@"appPassword"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.dateFormat forKey:@"dateFormat"];

	[aCoder encodeBool:autoinflectsClassNames forKey:@"autoinflectsClassNames"];
	[aCoder encodeBool:autoinflectsPropertyNames forKey:@"autoinflectsPropertyNames"];
	[aCoder encodeBool:ignoresClassPrefixes forKey:@"ignoresClassPrefixes"];
	
	[aCoder encodeBool:succinctErrorMessages forKey:@"succinctErrorMessages"];
	[aCoder encodeBool:performsCompletionBlocksOnMainThread forKey:@"performsCompletionBlocksOnMainThread"];
	[aCoder encodeDouble:timeoutInterval forKey:@"timeoutInterval"];
	
	[aCoder encodeBool:managesNetworkActivityIndicator forKey:@"managesNetworkActivityIndicator"];
	
	[aCoder encodeObject:self.appURL forKey:@"appURL"];
	[aCoder encodeObject:self.appUsername forKey:@"appUsername"];
	[aCoder encodeObject:self.appPassword forKey:@"appPassword"];
}


@end
