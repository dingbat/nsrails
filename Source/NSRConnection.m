//
//  NSRConnection.m
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRConnection.h"
#import "NSData+Additions.h"
#import "NSRails.h"

@implementation NSRConnection

static NSOperationQueue *queue = nil;

+ (NSOperationQueue *) sharedQueue
{
	if (!queue)
	{
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:5];
	}
	return queue;
}

+ (NSString *) resultWithRequest:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error
{
	int statusCode = -1;
	BOOL err;
	NSString *result;
	//if no response, the server must be down and log an error
	if (!response || !data)
	{
		err = YES;
		statusCode = 0;
		result = [NSString stringWithFormat:@"Connection with %@ failed.",[NSRConfig appURL]];
	}
	else
	{
		//otherwise, get the statuscode from the response (it'll be an NSHTTPURLResponse but to be safe check if it responds)
		if ([response respondsToSelector:@selector(statusCode)])
		{
			statusCode = [((NSHTTPURLResponse *)response) statusCode];
		}
		err = (statusCode == -1 || statusCode >= 400);
		
		result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		
#ifndef NSRCompileWithARC
		[request release];
		[result autorelease];
#endif
		
#if NSRLog > 1
		NSLog(@"IN<=== Code %d; %@\n\n",statusCode,(err ? @"[see ERROR]" : result));
		NSLog(@" ");
#endif
	}
	
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
		NSDictionary *inf = [NSDictionary dictionaryWithObject:result
														forKey:NSLocalizedDescriptionKey];
		NSError *statusError = [NSError errorWithDomain:@"rails"
												   code:statusCode
											   userInfo:inf];
		
		if (error)
		{
			*error = statusError;
		}
		
#if NSRLog > 0
		NSRLogError(statusError);
		NSLog(@" ");
#endif
		
#ifdef NSRCrashOnError
		[NSException raise:[NSString stringWithFormat:@"Rails error code %d",statusCode] format:result];
#endif
		
		return nil;
	}
	
	return result;
}

+ (NSString *) makeRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(void(^)(NSString *result, NSError *error))completionBlock;
{
	//make sure the app URL is set
	if (![NSRConfig appURL])
	{
		NSError *err = [NSError errorWithDomain:@"rails" code:0 userInfo:[NSDictionary dictionaryWithObject:@"No server root URL specified. Set your rails app's root with +[NSRConfig setAppURL:] somewhere in your app setup." forKey:NSLocalizedDescriptionKey]];
		if (error)
			*error = err;
		if (completionBlock)
			completionBlock(nil, err);
		
#ifdef NSRLogErrors
		NSRLogError(err);
		NSLog(@" ");
#endif
		
		return nil;
	}
	
	//generate url based on base URL + route given
	NSString *url = [NSString stringWithFormat:@"%@/%@",[NSRConfig appURL],route];
	
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
	if ([NSRConfig appUsername] && [NSRConfig appPassword])
	{
		//add auth header encoded in base64
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", [NSRConfig appUsername], [NSRConfig appPassword]];
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
	
	//send request!
	if (completionBlock)
	{
		[NSURLConnection sendAsynchronousRequest:request queue:[[self class] sharedQueue] completionHandler:
		 ^(NSURLResponse *response, NSData *data, NSError *error) 
		 {
			 if (error)
			 {
				 completionBlock(nil,error);
			 }
			 NSError *e = nil;
			 NSString *result = [self resultWithRequest:response data:data error:&e];
			 
			 completionBlock(result,e);
		 }];
		
		return nil;
	}
	else
	{
		NSURLResponse *response = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
		
		return [self resultWithRequest:response data:data error:error];
	}
}

@end
