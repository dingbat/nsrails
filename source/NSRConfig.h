//
//  NSRConfig.h
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

/////////////////////////////
//  OPTIONS
// for documentation on these, see https://github.com/dingbat/nsrails/wiki/Compile-config

#define NSRLog 2
#define NSRCompileWithARC
#define NSRSuccinctErrorMessages
//#define NSRCrashOnError

//NSRConfig.h
/////////////////////////////

#import "JSONFramework.h"

typedef void(^NSRHTTPCompletionBlock)(NSString *result, NSError *error);

#define NSRValidationErrorsKey	@"validation errors"

@interface NSRConfig : NSObject
{
	NSOperationQueue *asyncOperationQueue; //used for async requests
}

@property (nonatomic, strong) NSString *appURL;
@property (nonatomic, strong) NSString *appUsername;
@property (nonatomic, strong) NSString *appPassword;

@property (nonatomic, strong) NSString *dateFormat;
@property (nonatomic) BOOL automaticallyUnderscoreAndCamelize;

+ (NSRConfig *) defaultConfig;
+ (void) setAsDefaultConfig:(NSRConfig *)config;

- (id) initWithAppURL:(NSString *)url;

- (void) use;
- (void) end;

- (void) useIn:(void(^)(void))block;


////////////////////////////
//SUBCLASSING NSRAILSCONFIG
////////////////////////////

//If you wish to define your own method of making a connection that's not HTTP (SSL, etc)
//this is the method to override:

- (NSString *) makeRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock;

///////////////////////////////////////////////////////
//Some helper methods that could be useful
//These shouldn't really be used outside of subclassing NSRailsConfig

//Will give you any rails-specific errors (like validation errors) and make the error message succinct
//Highly recommended that you use this on your result string to check for errors
//You can also override this on its own if you have server-specific errors you want handled

- (NSError *) errorForResponse:(NSString *)response statusCode:(NSInteger)statusCode;

//Will return an NSURLRequest object with the given params
//Should only be used if you're overriding the makeRequestType:requestBody:route:sync:orAsync: method above

- (NSURLRequest *) HTTPRequestForRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route;

//Will log stuff for you

- (void) logRequest:(NSString *)requestStr httpVerb:(NSString *)httpVerb url:(NSString *)url;
- (void) logResponse:(NSString *)response statusCode:(NSInteger)code;


@end