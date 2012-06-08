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
extern NSString * const NSRCoreDataException;

////////////////////////////////

/**
 
 The NSRails configuration class is `NSRConfig`, a class that stores your Rails app's configuration settings (server URL, etc) for either your app globally or in specific instances. It also supports basic HTTP authentication and very simple OAuth authentication.
 
 ## Universal Config
 
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
 
 ## Config environments
 
 `NSRConfig` supports several environments if you have a test and production server and don't want to switch between the two all the time. The constants `NSRConfigEnvironmentDevelopment` and `NSRConfigEnvironmentProduction` can be used, but any string will do.
 
	NSRConfig *devConfig = [[NSRConfig alloc] initWithAppURL:@"http://localhost:3000"];
	[devConfig useAsDefaultForEnvironment:NSRConfigEnvironmentDevelopment];
	
	NSRConfig *prodConfig = [[NSRConfig alloc] initWithAppURL:@"http://myapp.com"];
	prodConfig.appUsername = @"username";
	prodConfig.appPassword = @"password";
	[prodConfig useAsDefaultForEnvironment:NSRConfigEnvironmentProduction];
	 
	// Now set your environment for the rest of the app... (set to Development by default so this isn't even necessary)
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentDevelopment];
	// And the relevant config will be used in future calls to "defaultConfig" or in any "remote<X>" methods.
 
 The environment in which a config exists (production, development, or your own) has no bearing on its behavior in sending/receiving from your server.
 
 ## Using several configs in one project
 
 - If you simply need to direct different objects to different URLs, use the useForClass: method. Base URLs, autoinflection, date formats, and any other NSRConfig configurations will be used for NSRails actions called on this class or its instances:
 
		NSRConfig *peopleServer = [[NSRConfig alloc] initWithAppURL:@"http://secondrailsapp.com"];
		[peopleServer useForClass:[Person class]];

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
 
	In these examples, everything within the blocks will be called using the config context specified, regardless of `defaultConfig` or any class-specific config (they take highest precedence).
 
	You can nest several config contexts within each other.
 
 ## Config precedence
 
 When an NSRails method is called, NSRails uses the following hierarchy to find an NSRConfig to use:
 
 - **"Override" config:** If use was called (explicitly or implicity via a block). If they are nested, whichever one is on top of the stack (latest one).
 - **Instance-specific config**: If the method is an instance method and the instance was initialized with initWithCustomMap:customConfig:, will use that config.
 - **Class-specific config**: If the receiving class of the method (class or instance) defines a custom class with useForClass:.
 - **Default config**: (Most frequent case.) Uses the config set to default of the current environment. (Current environment is `NSRConfigEnvironmentDevelopment` by default.
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
 Root URL for your Rails server.
 */
@property (nonatomic, strong) NSString *appURL;

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



/// =============================================================================================
/// @name Routing
/// =============================================================================================

/**
 When true, all Objective-C class names will have a default equivalence to their under_scored versions.
 
 For instance, the class `DataType` in Objective-C will change to `data_type` when sending/receiving to/from Rails.
 
 When false, names must be identical to their corresponding models in Rails.
 
 If there are just a few cases where you don't want this, you can override model names [like this](NSRRemoteObject.html#overriding).
 
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
 When converting class names to their Rails equivalents, prefixes will be omitted.
 
 Example: `NSRClass` will simply become `class`, instead of `nsr_class`.
 
 **Default:** `YES`.
 */
@property (nonatomic) BOOL ignoresClassPrefixes;

/// =============================================================================================
/// @name Authentication
/// =============================================================================================

/**
 Username for basic HTTP authentication (if used by server.)
 */
@property (nonatomic, strong) NSString *appUsername;

/**
 Password for basic HTTP authentication (if used by server.)
 */
@property (nonatomic, strong) NSString *appPassword;

/**
 Token for OAuth authentication (if used by server.)
 */
@property (nonatomic, strong) NSString *appOAuthToken;

/// =============================================================================================
/// @name Server-side settings
/// =============================================================================================

/**
 HTTP method used for updating objects.
 
 Rails is currently at 3.2.3 and using PUT, but 4.0 will use PATCH by default.
 
 **Default:** `@"PUT"`

 @warning When Rails 4.0 is released, this default value will be changed to `@"PATCH"`.
 */
@property (nonatomic, strong) NSString *updateMethod;

/**
 Date [format]("https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/DataFormatting/Articles/dfDateFormatting10_4.html%23//apple_ref/doc/uid/TP40002369-SW4") used if a property of type NSDate is encountered, to "encode" and "decode" NSDate objects.
 
 This should not be changed unless the format is also changed server-side; the default is the default Rails format.
 
 **Default:** `"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"` (Rails default).
 */
@property (nonatomic, strong) NSString *dateFormat;

/// =============================================================================================
/// @name CoreData
/// =============================================================================================

/**
 Managed object context for CoreData support. **(Required if CoreData is enabled)**
 
 This is the context into which NSRails will insert any new objects created by various internal methods, or search for any existing objects. 
 
 Should stay `nil` (default) if CoreData is not being used.
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
/// @name Managing the global environment
/// =============================================================================================

/**
 Returns the default configuration for a given environment.
 
 Creates and sets one if one for the given environment hasn't been set yet.
 
 @param environment Environment identifier.
 @return Configuration set for *environment*.
 */
+ (NSRConfig *) configForEnvironment: (NSString *)environment;

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
/// @name Using configs in specific locations
/// =============================================================================================

/**
 Begins a context block of code to use the receiver as the default config.
 
 Highest config precedence.

 @see end.
 */
- (void) use;

/**
 Ends a context block of code to use the receiver as the default config.
 
 Highest config precedence.
 
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

/**
 Specifies for all NSRails actions (instance and class methods) in a given class to use the receiver.
 
 Has precedence over a `defaultConfig`, but is trumped by a config specified for a block (with use and end, or useIn:). (This is the same precedence as instances which declare custom configs.)
 
 This should be used somewhere in your app setup, before any NSRails actions. 
 
 @param class Class to use this config.
 */
- (void) useForClass:(Class)class;

/**
 Specifies for all NSRails actions in the current environment to use the receiver.
 
 Lowest config precedence.
 */
- (void) useAsDefault;

/**
 Specifies for all NSRails actions in a given environment to use the receiver.
 
 Lowest config precedence.
 
 @param environment Environment identifier. Can be your own custom string or the constants NSRConfigEnvironmentDevelopment or NSRConfigEnvironmentProduction.
 */
- (void) useAsDefaultForEnvironment:(NSString *)environment;


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

@end

