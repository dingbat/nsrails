/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
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


//Environments
static NSString * const NSRConfigEnvironmentDevelopment = @"NSRConfigEnvironmentDevelopment";
static NSString * const NSRConfigEnvironmentProduction	= @"NSRConfigEnvironmentProduction";

//Keys
static NSString * const NSRValidationErrorsKey			= @"NSRValidationErrorsKey";

//Exceptions+Domains
static NSString * const NSRRemoteErrorDomain				= @"NSRRemoteErrorDomain";
static NSString * const NSRailsSyncException				= @"NSRailsSyncException";
static NSString * const NSRailsInvalidJSONEncodingException = @"NSRailsInvalidJSONEncodingException";
static NSString * const NSRailsDateConversionException		= @"NSRailsDateConversionException";
static NSString * const NSRailsMissingURLException			= @"NSRailsMissingURLException";

////////////////////////////////

/**
 
 ### Summary
 
 The NSRails configuration class is `NSRConfig`, a class that stores your Rails app's configuration settings (server URL, etc) for either your app globally or in specific instances. It also supports basic HTTP authentication and can be subclassed to fit specific implementations.
 
 ### Universal Config
 
 This should meet the needs of the vast majority of Rails apps. Somewhere in your app setup, set your server URL (and optionally a username and password) using the `defaultConfig` singleton:

	 //AppDelegate.m
	 
	 #import "NSRConfig.h"
	 
	 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	 {
		 [[NSRConfig defaultConfig] setAppURL:@"http://myapp.com"];
		 
		 //Similarly, if using HTTP Authentication, you can set your app's username and password like this:
		 //[[NSRConfig defaultConfig] setAppUsername:@"username"];
		 //[[NSRConfig defaultConfig] setAppPassword:@"password"];
		 ...
	 }
 
 ### Config environments
 
 `NSRConfig` supports several environments if you have a test and production server and don't want to switch between the two all the time. The constants `NSRConfigEnvironmentDevelopment` and `NSRConfigEnvironmentProduction` can be used, but any string will do.
 
	 // Environment is set to Development by default, so [NSRConfig defaultConfig] can be used here too
	 NSRConfig *devConfig = [NSRConfig configForEnvironment:NSRConfigEnvironmentDevelopment];
	 devConfig.appURL = @"http://localhost:3000";
	 
	 NSRConfig *prodConfig = [NSRConfig configForEnvironment:NSRConfigEnvironmentProduction];
	 prodConfig.appURL = @"http://myapp.com";
	 prodConfig.appUsername = @"username";
	 prodConfig.appPassword = @"password";
	 
	 // Now set your environment for the rest of the app...
	 [NSRConfig setCurrentEnvironment:NSRConfigEnvironmentDevelopment];
	 // And the relevant config will be used in future calls to "defaultConfig" or in any "remote<X>" methods.
 
 The environment in which a config exists (production, development, or your own) has no bearing on its behavior in sending/receiving from your server.
 
 ### Using several configs in one project
 
 - If you simply need to direct different models to different URLs, you can use the [NSRailsUseConfig](https://github.com/dingbat/nsrails/wiki/Macros) macro.
 - If specific actions must be called using a separate config, an `NSRConfig` instance can be used to define a context block in which to call those config-specific methods:
		
		NSRConfig *myConfig = [[NSRConfig alloc] initWithAppURL:@"http://secondrailsapp.com/"];
		
		[myConfig use];
		NSArray *peopleFromOtherServer = [Person getAllRemote];
		[myConfig end];
 
	Or, using block notation:
 
		NSArray *peopleToTransfer = [Person getAllRemote];
		NSRConfig *myConfig = [[NSRConfig alloc] initWithAppURL:@"http://secondrailsapp.com/"];
		[myConfig useIn:^
			{
				for (Person *p in peopleToTransfer)
				{
					[p remoteCreate];
				}
			}
		];
 
	In these examples, everything within the blocks will be called using the config context specified, regardless of @defaultConfig@ or any class-specific config (as defined like in the *Classes* section above).
 
	You can nest several config contexts within each other.


 ### Subclassing `NSRConfig`
 
 Subclassing `NSRConfig` can be useful if you want to implement a connection method that's not HTTP (for example, HTTPS), or if you're using a non-Rails REST service with different standards. Moreover, it can be used to generate errors specific to your app.
 
 Please see [this wiki page](https://github.com/dingbat/nsrails/wiki/NSRConfig) if this interests you.
 
 */

@interface NSRConfig : NSObject
{
	NSDateFormatter *dateFormatter;
	NSOperationQueue *asyncOperationQueue; //used for async requests
}


/// =============================================================================================
/// @name Properties
/// =============================================================================================


/**
 When true, all Obj-C property and class names will have a default equivalent for their under_scored versions.
 
 For instance, `myProperty` in Obj-C will change to `my_property` when sending/receiving to/from Rails.
 
 When false, names must be identical to their corresponding elements in Rails.
 
 If there are just a few cases where you don't want this, see the NSRailsSync macro to override equivalents.
 
 **Default:** `YES`.
 */
@property (nonatomic) BOOL autoInflectsNamesAndProperties;

/**
 The network activity indicator (gray spinning wheel on the status bar) will automatically turn on and off with requests.
 
 This is only supported for asynchronous requests, as otherwise the main thread is blocked.
 
 Also only supported in iOS development.
 
 **Default:** `YES`.
 */
@property (nonatomic) BOOL managesNetworkActivityIndicator;

/**
 When converting class names to their Rails equivalents, prefixes will be omitted.
 
 Example: `NSRClass` will simply become `class`, instead of `nsr_class`.
 
 **Default:** `NO`.
 */
@property (nonatomic) BOOL ignoresClassPrefixes;

/**
 Cleaner error messages when generating `NSError` objects.
 
 For example, simply `Couldn't find Person with id=15`, instead of [this mess](https://gist.github.com/1725475).
 
 May not be effective with non-Rails servers.
 
 **Default:** `YES`.
 */
@property (nonatomic) BOOL succinctErrorMessages;

/**
 Timeout interval for HTTP requests.
 
 The minimum timeout interval for POST requests is 240 seconds (set by Apple).
 
 **Default:** `60`.
 */
@property (nonatomic) NSTimeInterval timeoutInterval;

/**
 Root URL for your Rails server.
 */
@property (nonatomic, strong) NSString *appURL;

/**
 Username for basic HTTP authentication (if used by server.)
 */
@property (nonatomic, strong) NSString *appUsername;

/**
 Password for basic HTTP authentication (if used by server.)
 */
@property (nonatomic, strong) NSString *appPassword;

/**
 Date [format]("https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html%23//apple_ref/doc/uid/TP40002369-SW4") used if a property of type NSDate is encountered, to "encode" and "decode" NSDate objects.
 
 This should not be changed unless the format is also changed server-side; the default is the default Rails format.
 
 **Default:** `"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"` (Rails default).
 */
@property (nonatomic, strong) NSString *dateFormat;

/// =============================================================================================
/// @name Retrieving the default config
/// =============================================================================================

/**
 Returns the current default configuration.
 
 @return The configuration set for the current environment.
 */
+ (NSRConfig *) defaultConfig;

/// =============================================================================================
/// @name Using custom configs as default
/// =============================================================================================

/**
 Sets the current default configuration to a custom-made config.
 
 Can be useful if `NSRConfig` is subclassed with a custom implementation which you'd like to use for the entirety of your app.
 
 @param config Config to be set as default for the current environment.
 */
+ (void) setConfigAsDefault:(NSRConfig *)config;

/**
 Sets a custom-made config to be the default for a given environment.
  
 @param config Config to be set as default for *environment*.
 @param environment Environment identifier. Can be your own custom string or the constants NSRConfigEnvironmentDevelopment or NSRConfigEnvironmentProduction.
 */
+ (void) setConfig:(NSRConfig *)config asDefaultForEnvironment:(NSString *)environment;

/**
 Returns the default configuration for a given environment
 
 @param environment Environment identifier.
 @return Configuration set for *environment*.
 */
+ (NSRConfig *) configForEnvironment: (NSString *)environment;

/// =============================================================================================
/// @name Managing the global environment
/// =============================================================================================


/**
 Sets the global environment for `NSRConfig`.
 
 @param environment Environment identifier. Can be your own custom string or the constants NSRConfigEnvironmentDevelopment or NSRConfigEnvironmentProduction.
 */
+ (void) setCurrentEnvironment:(NSString *)environment;

/**
 Returns the identifier for the current global environment.
 
 @return The identifier for the current global environment.
 */
+ (NSString *) currentEnvironment;

/// =============================================================================================
/// @name Using a specific config as default for a block of code
/// =============================================================================================

/**
 Begins a context block of code to use the sender as the default config.
 
 @see end.
 */
- (void) use;

/**
 Ends a context block of code to use the sender as the default config.
 
 @see use.
 */
- (void) end;

/**
 Executes a given block with the sender as the default config in that block.
 
 @param block Block to be executed with the default config context of sender.
 @see use.
 @see end.
 */
- (void) useIn:(void(^)(void))block;

/// =============================================================================================
/// @name Date conversions
/// =============================================================================================

/**
 Returns a string representation of a given date formatted using dateFormat.
 
 This method is used internally to convert an `NSDate` property in an object to a Rails-readable string.
 
 @param date The date to format.
 @see dateFromString:.
 */
- (NSString *) stringFromDate:(NSDate *)date;

/**
 Returns a date representation of a given string interpreted using dateFormat.
 
 This method is used internally to convert a Rails-sent datetime string representation into an `NSDate` for an object property.
 
 @param string The string to parse.
 @see stringFromDate:.
 */
- (NSDate *) dateFromString:(NSString *)string;

/// =============================================================================================
/// @name Initializing a config
/// =============================================================================================

/**
 Initializes a new `NSRConfig` instance with an app URL.
 
 @param url App URL to be set to the new instance.
 */
- (id) initWithAppURL:(NSString *)url;

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

