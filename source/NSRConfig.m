//
//  NSRConfig.m
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRConfig.h"

#import "NSData+Additions.h"
#import "JSONFramework.h"

//this small helper class is used to keep track of which config is contextually relevant
//a stack is used so that -[NSRConfig use] commands can be nested
//the problem with simply adding the NSRConfig to the stack is that the NSMutableArray will act funny if it's added multiple times (since an instance can only exist once in an array) and removing is even more of a nightmare
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

@implementation NSRConfig
@synthesize appURL, appUsername, appPassword;

static NSRConfig *defaultConfig = nil;
static NSMutableArray *overrideConfigStack = nil;

+ (NSRConfig *) defaultConfig
{
	//singleton
	
	if (!defaultConfig) [self setDefaultConfig:[[NSRConfig alloc] init]];
	return defaultConfig;
}

+ (void) setDefaultConfig:(NSRConfig *)config
{
	defaultConfig = config;
}

- (id) initWithAppURL:(NSString *)url
{
	if ((self = [super init]))
	{
		asyncOperationQueue = [[NSOperationQueue alloc] init];
		[asyncOperationQueue setMaxConcurrentOperationCount:5];
		
		[self setAppURL:url];
	}
	return self;
}

- (void) setAppURL:(NSString *)str
{
	//get rid of trailing /
	if ([[str substringFromIndex:str.length-1] isEqualToString:@"/"])
		str = [str substringToIndex:str.length-1];
	
	//add http:// if not included already
	NSString *http = (str.length < 7 ? nil : [str substringToIndex:7]);
	if (![http isEqualToString:@"http://"] && ![http isEqualToString:@"https:/"])
	{
		str = [@"http://" stringByAppendingString:str];
	}
	
	appURL = str;
}

#pragma mark HTTP stuff

+ (void) crashWithError:(NSError *)error
{
	//purpose of this method is to factor printing out an error message (if NSRLog allows) and crash if necessary
	
#if NSRLog > 0
	NSLog(@"%@",error);
	NSLog(@" ");
#endif
	
#ifdef NSRCrashOnError
	[NSException raise:[NSString stringWithFormat:@"%@ error code %d",[error domain],[error code]] format:[error localizedDescription]];
#endif
}

- (NSString *) resultWithResponse:(NSString *)response error:(NSError **)error
{
	int statusCode = -1;
	BOOL err;
	NSString *result;
	
	//otherwise, get the statuscode from the response (it'll be an NSHTTPURLResponse but to be safe check if it responds)
	if ([response respondsToSelector:@selector(statusCode)])
	{
		statusCode = [((NSHTTPURLResponse *)response) statusCode];
	}
	err = (statusCode == -1 || statusCode >= 400);
		
#ifndef NSRCompileWithARC
	[request release];
	[result autorelease];
#endif
	
#if NSRLog > 1
	NSLog(@"IN<=== Code %d; %@\n\n",statusCode,(err ? @"[see ERROR]" : result));
	NSLog(@" ");
#endif
	
	if (err)
	{
#ifdef NSRSuccinctErrorMessages
		//if error message is in HTML,
		if ([result rangeOfString:@"</html>"].location != NSNotFound)
		{
			NSArray *pres = [result componentsSeparatedByString:@"<pre>"];
			if (pres.count > 1)
			{
				//get the value between <pre> and </pre>
				result = [[[pres objectAtIndex:1] componentsSeparatedByString:@"</pre"] objectAtIndex:0];
				//some weird thing rails does, will send html tags &quot; for quotes
				result = [result stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
			}
		}
#endif
		
		//make a new error
		NSMutableDictionary *inf = [NSMutableDictionary dictionaryWithObject:result
																	  forKey:NSLocalizedDescriptionKey];
		//means there was a validation error - the specific errors were sent in JSON
		if (statusCode == 422)
		{
			[inf setObject:[result JSONValue] forKey:NSRValidationErrorsKey];
		}
		
		NSError *statusError = [NSError errorWithDomain:@"Rails"
												   code:statusCode
											   userInfo:inf];
		
		if (error)
		{
			*error = statusError;
		}
		
		[NSRConfig crashWithError:statusError];
		
		return nil;
	}
	
	return result;
}

- (NSString *) resultForRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(void(^)(NSString *result, NSError *error))completionBlock
{
	//make sure the app URL is set
	if (!self.appURL)
	{
		NSError *err = [NSError errorWithDomain:@"NSRails" code:0 userInfo:[NSDictionary dictionaryWithObject:@"No server root URL specified. Set your rails app's root with +[[NSRConfig defaultConfig] setAppURL:] somewhere in your app setup." forKey:NSLocalizedDescriptionKey]];
		if (error)
			*error = err;
		if (completionBlock)
			completionBlock(nil, err);
		
		[NSRConfig crashWithError:err];
		
		return nil;
	}
	
	if (error)
	{
		NSString *raw = [self makeRequestType:type requestBody:requestStr route:route sync:error orAsync:nil];
		return [self resultWithResponse:raw error:error];
	}
	else if (completionBlock)
	{
		[self makeRequestType:type requestBody:requestStr route:route sync:nil orAsync:^
		 (NSString *raw, NSError *error)
		 {
			 if (error)
			 {
				 completionBlock(nil, error); 
			 }
			 else
			 {
				 NSString *result = [self resultWithResponse:raw error:&error];
				 completionBlock(result, error);
			 }
		 }];
	}
	return nil;
}

- (NSError *) errorWithErrorCodeFromReponse:(NSHTTPURLResponse *)reponse
{
	int statusCode = -1;
	
	//otherwise, get the statuscode from the response (it'll be an NSHTTPURLResponse but to be safe check if it responds)
	if ([response respondsToSelector:@selector(statusCode)])
	{
		statusCode = [((NSHTTPURLResponse *)response) statusCode];
	}
	err = (statusCode == -1 || statusCode >= 400);
	
	
}
				
- (NSURLRequest *) requestForRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route
{
	//generate url based on base URL + route given
	NSString *url = [NSString stringWithFormat:@"%@/%@",appURL,route];
	
#ifdef NSRAutomaticallyMakeURLsLowercase
	url = [url lowercaseString];
#endif
	
	//log relevant stuff
#if NSRLog > 0
	NSLog(@" ");
	NSLog(@"%@ to %@",type,url);
#if NSRLog > 1
	NSLog(@"OUT===> %@",requestStr);
#endif
#endif
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
	
	[request setHTTPMethod:type];
	[request setHTTPShouldHandleCookies:NO];
	//set for json content
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	//if username & password set, assume basic HTTP authentication
	if (self.appUsername && self.appPassword)
	{
		//add auth header encoded in base64
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.appUsername, self.appPassword];
		NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
		NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
		
		[request setValue:authHeader forHTTPHeaderField:@"Authorization"]; 
	}
	
	//if there's an actual request, add the body
	if (requestStr)
	{
		NSData *requestData = [NSData dataWithBytes:[requestStr UTF8String] length:[requestStr length]];
		
		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody: requestData];
		
		[request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
 	}
	return request;
}

- (NSString *) makeRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(void(^)(NSString *result, NSError *error))completionBlock
{	
	NSURLRequest *request = [self requestForRequestType:type requestBody:requestStr route:route];
	
	//send request!
	if (completionBlock)
	{
		[NSURLConnection sendAsynchronousRequest:request queue:asyncOperationQueue completionHandler:
		 ^(NSURLResponse *response, NSData *data, NSError *error) 
		 {
			 if (error)
			 {
				 completionBlock(nil,error);
			 }
			 else
			 {
				 NSString *rawResult = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]; 
				 completionBlock(rawResult, nil);
			 }
		 }];
		
		return nil;
	}
	else
	{
		NSError *connectionError;
		NSURLResponse *response = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&connectionError];
		
		//if there's an error here there must have been an issue connecting to the server.
		if (connectionError)
		{
			//if there was a dereferenced error passed in, set it to Apple's
			if (error)
				*error = connectionError;
			
			return nil;
		}
		
		NSString *rawResult = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		return rawResult;
	}
}


#pragma mark Contextual stuff

+ (NSRConfig *) overrideConfig
{
	//return the last config on the stack
	//if stack is nil or empty, this will be nil, signifying that there's no overriding context
	
	return [[overrideConfigStack lastObject] config];
}

- (void) use
{
	//this will signal the beginning of a config context block
	//if the stack doesn't exist yet, create it.
	
	if (!overrideConfigStack)
		overrideConfigStack = [[NSMutableArray alloc] init];
	
	// make a new stack element for this config (explained above)
	NSRConfigStackElement *c = [NSRConfigStackElement elementForConfig:self];
	
	//push to the "stack"
	[overrideConfigStack addObject:c];
}

- (void) end
{
	//start at the end of the stack
	for (int i = overrideConfigStack.count-1; i >= 0; i--)
	{
		//see if any element matches this config
		NSRConfigStackElement *c = [overrideConfigStack objectAtIndex:i];
		if (c.config == self)
		{
			//remove it
			[overrideConfigStack removeObjectAtIndex:i];
			break;
		}
	}
}

- (void) useIn:(void (^)(void))block
{
	//self-explanatory
	
	[self use];
	block();
	[self end];
}

@end
