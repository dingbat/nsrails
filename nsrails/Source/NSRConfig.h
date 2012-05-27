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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#if TARGET_OS_IPHONE
//UIKit needed for managing activity indicator
#import <UIKit/UIKit.h>
#endif

//Common Blocks
typedef void(^NSRHTTPCompletionBlock)(id jsonRep, NSError *error);

typedef void(^NSRBasicCompletionBlock)(NSError *error);
typedef void(^NSRFetchCompletionBlock)(BOOL changed, NSError *error);
typedef void(^NSRFetchAllCompletionBlock)(NSArray *allRemote, NSError *error);
typedef void(^NSRFetchObjectCompletionBlock)(id object, NSError *error);


//Environments
extern NSString * const NSRConfigEnvironmentDevelopment;
extern NSString * const NSRConfigEnvironmentProduction;

//Keys
extern NSString * const NSRValidationErrorsKey;

//Exceptions+Domains
extern NSString * const NSRRemoteErrorDomain;
extern NSString * const NSRMapException;
extern NSString * const NSRJSONParsingException;
extern NSString * const NSRInternalError;
extern NSString * const NSRMissingURLException;
extern NSString * const NSRNullRemoteIDException;

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
 
 - If you simply need to direct different models to different URLs, you can use the [NSRUseConfig](https://github.com/dingbat/nsrails/wiki/Macros) macro.
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


 ### Subclassing NSRConfig
 
 Subclassing NSRConfig can be useful if you want to implement a connection method that's not HTTP (for example, HTTPS), or if you're using a non-Rails REST service with different standards. Moreover, it can be used to generate errors specific to your app.
 
 - The main method to override if you wish to do so is responseForRequestType:requestBody:url:sync:orAsync:. This method is called internally by NSRails and expects a Foundation objects that correspond to the returned JSON (ie, NSArray, NSDictionary).
 
 - This should also set the `NSError **error` or perform the `NSRHTTPCompletionBlock completionBlock`, whichever one is present.
	- In determining errors, it is highly recommend to use the helper method errorForResponse:statusCode:. This method will return you any Rails-specific errors (like validation errors), as well as make the error message succinct. In addition to being used, it is also possible to override this method (making sure to check if a `super` call to it returns anything) if your Rails app has specific errors you want to handle.
 
 - You can set your new `NSRConfig` subclass to be the default config like so (this would be instead of the first code example of course):
 
		CustomConfig *myConfig = [[CustomConfig alloc] initWithAppURL:@"http://localhost:3000"];
 
		//set custom myConfig properties...
		[NSRConfig setAsDefaultConfig:myConfig];
 
		//or, to a specific environment:
		[NSRConfig setAsDefaultConfig:myConfig forEnvironment:NSRConfigEnvironmentProduction];
 
	Or, if only a _certain_ action requires it, you can use your new instance for a block of code just as you would in the section above.
 */

@interface NSRConfig : NSObject <NSCoding>
{
	NSDateFormatter *dateFormatter;
	NSOperationQueue *asyncOperationQueue; //used for async requests
}


/// =============================================================================================
/// @name Properties
/// =============================================================================================


/**
 When true, all Objective-C class names will have a default equivalence to their under_scored versions.
 
 For instance, the class `DataType` in Objective-C will change to `data_type` when sending/receiving to/from Rails.
 
 When false, names must be identical to their corresponding models in Rails.
 
 If there are just a few cases where you don't want this, see the NSRUseModelName macro to override model names.
 
 **Default:** `YES`.
 */
@property (nonatomic) BOOL autoinflectsClassNames;

/**
 When true, all Objective-C property names will have a default equivalence to their under_scored versions.
 
 For instance, `myProperty` in Obj-C will change to `my_property` when sending/receiving to/from Rails.
 
 When false, names must be identical to their corresponding attributes in Rails.
 
 If there are just a few cases where you don't want this, see the NSRMap macro to override equivalents.
 
 **Default:** `YES`.
 */
@property (nonatomic) BOOL autoinflectsPropertyNames;

/**
 When true, the completion blocks passed into asynchronous `remote` methods will be called on the main thread.
 
 This can be useful if you wish to update view elements from this block (where iOS would otherwise lock up).
 
 Not sure when this couldn't be useful, but leaving disabling it as an option. Maybe performance?
 
 **Default:** `YES`.
 */
@property (nonatomic) BOOL performsCompletionBlocksOnMainThread;

/**
 The network activity indicator (gray spinning wheel on the status bar) will automatically turn on and off with requests.
 
 This is only supported for asynchronous requests, as otherwise the main thread is blocked.
 
 Also only supported in iOS development.
 
 **Default:** `NO`.
 */
@property (nonatomic) BOOL managesNetworkActivityIndicator;

/**
 When converting class names to their Rails equivalents, prefixes will be omitted.
 
 Example: `NSRClass` will simply become `class`, instead of `nsr_class`.
 
 **Default:** `YES`.
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

/**
 Managed object context if CoreData is being used.
 
 Should stay `nil` if CoreData is not being used.
 
 **Default:** `nil`.
 */
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;


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
 Begins a context block of code to use the receiver as the default config.
 
 @see end.
 */
- (void) use;

/**
 Ends a context block of code to use the receiver as the default config.
 
 @see use.
 */
- (void) end;

/**
 Executes a given block with the receiver as the default config in that block.
 
 @param block Block to be executed with the default config context of receiver.
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


/// =============================================================================================
/// @name Making custom requests
/// =============================================================================================

/**
 Makes a custom request. Returns the response string if synchronous; otherwise executes given block.
 
 Used by every remote NSRRemoteObject method.
 
 @warning Do not override this method if you wish to override NSRConfig, since this method contains important workflows such as checking if the appURL is nil, managing the network activity indicator, and logging. Rather, override responseForRequestType:requestBody:url:sync:orAsync:.
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param body Request body (needs to be a JSON parsable object, or will throw exception (NSDictionary, NSArray)).
 @param route The route to which the request will be made. This is appended to the `appURL`, so not the full URL. For instance, `articles/1`.
 @param sync Pointer to an `NSError` object. Only used if *completionBlock* is `NULL`. May be `NULL`.
 @param completionBlock If this parameter is not `NULL`, the request will be made asynchronously and this block will be executed when the request is complete. If this parameter is `NULL`, request will be made synchronously and the *sync* paramter may be used.
 @return The response representation (parsed from JSON), only if request is made synchronously. Otherwise, will return `nil`.
 */
- (id) makeRequest:(NSString *)httpVerb requestBody:(id)body route:(NSString *)route sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock;


/// =============================================================================================
/// @name Methods to override
/// =============================================================================================

/**
 If you wish to define your own method of making a connection that's not HTTP (eg HTTPS), or include a custom header, etc, this is the method to override.
 
 You should continue to make calls to makeRequest:requestBody:route:sync:orAsync: - it will call this method internally. It is important to do so because it contains workflows that your override will hide.
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param body Request body (needs to be a JSON parsable object, or will throw exception (NSDictionary, NSArray)).
 @param url The url to which the request will be made (full URL.)
 @param sync Pointer to an `NSError` object. Only used if *completionBlock* is `NULL`. May be `NULL`.
 @param completionBlock If this parameter is not `NULL`, the request will be made asynchronously and this block will be executed when the request is complete. If this parameter is `NULL`, request will be made synchronously and the *sync* paramter may be used.
 @return The response representation (parsed from JSON), only if request is made synchronously. Otherwise, will return `nil`. 
 */
- (id) responseForRequestType:(NSString *)httpVerb requestBody:(id)body url:(NSString *)url sync:(NSError **)error orAsync:(NSRHTTPCompletionBlock)completionBlock;

/**
 (Typically only used when subclassing NSRConfig.) It is recommended to use this method after implementing your own request method, as it will generate some Rails-specific errors (like validation errors).
 
 Will give you any Rails-specific errors (like validation errors) and make the error message succinct (if enabled).
 
 You can also override this on its own if you have errors you want handled that NSRails doesn't take of already.
 
 @param response Response representation given by a server.
 @param statusCode Status code that was returned with the response.
 @return Error if one could be extracted - otherwise nil.
 */
- (NSError *) errorForResponse:(id)jsonResponse statusCode:(NSInteger)statusCode;

@end

