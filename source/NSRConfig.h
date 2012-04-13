/*
 
 _|_|_|    _|_|_|  _|_|    _|_|  _|  _|    _|_|           
 _|  _|  _|_|_|    _|  _|  _|_|  _|  _|  _|_|_| 
 
 NSRConfig.h
 
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

//Logging
/////////
                     //undefined, NSRails will log nothing
//#define NSRLog 1   //As 1, NSRails will log HTTP verbs with their outgoing URLs and any server errors being returned.
#define NSRLog 2     //As 2, NSRails will also log any JSON going out/coming in.


//Test if ARC is enabled
////////////////////////
// (thanks to http://www.learn-cocos2d.com/2011/11/everything-know-about-arc/ )
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


//Common Blocks
////////////////////////

typedef void(^NSRHTTPCompletionBlock)(NSString *result, NSError *error);

typedef void(^NSRBasicCompletionBlock)(NSError *error);
typedef void(^NSRGetLatestCompletionBlock)(BOOL changed, NSError *error);
typedef void(^NSRGetAllCompletionBlock)(NSArray *allRemote, NSError *error);
typedef void(^NSRGetObjectCompletionBlock)(id object, NSError *error);

#define NSRConfigEnvironmentDevelopment	@"development"
#define NSRConfigEnvironmentProduction	@"production"

#define NSRValidationErrorsKey	@"validation errors"

#define NSRRemoteErrorDomain				@"NSRRemoteErrorDomain"
#define NSRailsSyncException				@"NSRailsSyncException"
#define NSRailsInvalidJSONEncodingException @"NSRailsInvalidJSONEncodingException"
#define NSRailsDateConversionException		@"NSRailsDateConversionException"

////////////////////////////////


@interface NSRConfig : NSObject
{
	NSDateFormatter *dateFormatter;
	NSOperationQueue *asyncOperationQueue; //used for async requests
}

@property (nonatomic) BOOL automaticallyInflects, managesNetworkActivityIndicator, ignoresClassPrefixes, succinctErrorMessages;
@property (nonatomic) NSTimeInterval timeoutInterval;

@property (nonatomic, strong) NSString *appURL, *appUsername, *appPassword;

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

- (void) setDateFormat:(NSString *)dateFormat;
- (NSString *) dateFormat;

- (NSString *) convertDateToString:(NSDate *)date;
- (NSDate *) convertStringToDate:(NSString *)string;


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

