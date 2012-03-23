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

//NSRConfig.h
/////////////////////////////


// Test if ARC is enabled (thanks to http://www.learn-cocos2d.com/2011/11/everything-know-about-arc/ )
// define some LLVM3 macros if the code is compiled with a different compiler (ie LLVMGCC42)
#ifndef __has_feature
#define __has_feature(x) 0
#endif

#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#define ARC_ENABLED
#endif // __has_feature(objc_arc)


////////////////////////////////

typedef void(^NSRHTTPCompletionBlock)(NSString *result, NSError *error);

#define NSRConfigEnvironmentDevelopment	@"development"
#define NSRConfigEnvironmentProduction	@"production"

#define NSRValidationErrorsKey	@"validation errors"

#define NSRLocalErrorDomain @"NSRLocalErrorDomain"
#define NSRRemoteErrorDomain @"NSRRemoteErrorDomain"


////////////////////////////////


@interface NSRConfig : NSObject
{
	NSOperationQueue *asyncOperationQueue; //used for async requests
}

@property (nonatomic) BOOL automaticallyInflects, managesNetworkActivityIndicator, ignoresClassPrefixes, succinctErrorMessages;
@property (nonatomic) NSTimeInterval timeoutInterval;

@property (nonatomic, strong) NSString *appURL, *appUsername, *appPassword;
@property (nonatomic, strong) NSString *dateFormat;

+ (NSRConfig *) defaultConfig;
+ (void) setConfigAsDefault:(NSRConfig *)config;
+ (void) setConfig:(NSRConfig *)config asDefaultForEnvironment:(NSString *)environment;

+ (NSRConfig *) configForEnvironment: (NSString *)environment;
+ (void) setCurrentEnvironment:(NSString *)environment;
+ (NSString *) currentEnvironment;

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

- (void) logRequestWithBody:(NSString *)requestStr httpVerb:(NSString *)httpVerb url:(NSString *)url;
- (void) logResponse:(NSString *)response statusCode:(int)code;

@end


#if NSRLog > 0
#define NSRLogError(x)	NSLog(@"%@",x);
#else
#define NSRLogError(x)
#endif

