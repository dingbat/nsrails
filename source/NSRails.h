//
//  NSRails.h
/*
 
 _|      _|    _|_|_|  _|_|_|              _|  _|            
 _|_|    _|  _|        _|    _|    _|_|_|      _|    _|_|_|  
 _|  _|  _|    _|_|    _|_|_|    _|    _|  _|  _|  _|_|      
 _|    _|_|        _|  _|    _|  _|    _|  _|  _|      _|_|  
 _|      _|  _|_|_|    _|    _|    _|_|_|  _|  _|  _|_|_| 
 
 */
//
//  Created by Dan Hassin on 1/10/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "NSRConfig.h"

@class NSRPropertyCollection;

@interface NSRailsModel : NSObject <NSCoding>
{
	//used if initialized with initWithCustomSyncProperties
	NSRPropertyCollection *customProperties;
}

@property (nonatomic) BOOL remoteDestroyOnNesting;
@property (nonatomic, strong) NSNumber *remoteID;
@property (nonatomic, strong, readonly) NSDictionary *remoteAttributes;


/// =============================================================================================
#pragma mark - CRUD
/// =============================================================================================

// Synchronous, with error dereference

- (BOOL) remoteGetLatest:(NSError **)error;
- (void) remoteUpdate:(NSError **)error;
- (void) remoteCreate:(NSError **)error;
- (void) remoteDestroy:(NSError **)error;

+ (NSArray *) remoteAll:(NSError **)error;
+ (id) remoteObjectWithID:(NSInteger)mID error:(NSError **)error;


// Asynchronous
 
typedef void(^NSRBasicCompletionBlock)(NSError *error);
typedef void(^NSRGetLatestCompletionBlock)(NSError *error, BOOL changed);
typedef void(^NSRGetAllCompletionBlock)(NSArray *allRemote, NSError *error);
typedef void(^NSRGetObjectCompletionBlock)(id object, NSError *error);

- (void) remoteGetLatestAsync:(NSRGetLatestCompletionBlock)completionBlock;
- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock;
- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock;
- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock;

+ (void) remoteAllAsync:(NSRGetAllCompletionBlock)completionBlock;
+ (void) remoteObjectWithID:(NSInteger)mID async:(NSRGetObjectCompletionBlock)completionBlock;


/// =============================================================================================
#pragma mark - Non-CRUD instance methods
/// =============================================================================================

- (NSString *)	remoteGETRequestWithRoute:(NSString *)route error:(NSError **)error;
- (void)		remoteGETRequestWithRoute:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;

// (will send JSON representation of itself as requestBody)
- (NSString *)	remoteRequestSendingSelf:(NSString *)httpVerb route:(NSString *)route error:(NSError **)error;
- (void)		remoteRequestSendingSelf:(NSString *)httpVerb route:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;

- (NSString *)	remoteRequest:(NSString *)httpVerb requestBody:(NSString *)body route:(NSString *)route error:(NSError **)error;
- (void)		remoteRequest:(NSString *)httpVerb requestBody:(NSString *)body route:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;


/// =============================================================================================
#pragma mark - Non-CRUD class methods
//            if called on a subclass, will direct it to the controller ([User makeGET:@"foo"] => myapp.com/users/foo)
//            if called on NSRailsModel, will direct it to the app's root ([NSRailsModel makeGET:@"foo"] => myapp.com/foo)
/// =============================================================================================

+ (NSString *)	remoteGETRequestWithRoute:(NSString *)httpVerb error:(NSError **)error;
+ (void)		remoteGETRequestWithRoute:(NSString *)httpVerb async:(NSRHTTPCompletionBlock)completionBlock;

+ (NSString *)	remoteRequest:(NSString *)httpVerb requestBody:(NSString *)body route:(NSString *)route error:(NSError **)error;
+ (void)		remoteRequest:(NSString *)httpVerb requestBody:(NSString *)body route:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;

+ (NSString *)	remoteRequest:(NSString *)httpVerb sendObject:(NSRailsModel *)obj route:(NSString *)route error:(NSError **)error;
+ (void)		remoteRequest:(NSString *)httpVerb sendObject:(NSRailsModel *)obj route:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;


/// =============================================================================================
#pragma mark - Manual JSON encoding/decoding
//             (Takes into account NSRailsSync)
/// =============================================================================================

- (NSString *) remoteJSONRepresentation;
- (NSDictionary *) dictionaryOfRemoteProperties;

- (BOOL) setPropertiesUsingRemoteJSON:(NSString *)json;
- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict;

- (id) initWithRemoteDictionary:(NSDictionary *)railsDict;


/// =============================================================================================
#pragma mark - Initializers
//             (Sets custom sync properties for that instance - will not use its class's NSRailsSync)
/// =============================================================================================

- (id) initWithCustomSyncProperties:(NSString *)str;


@end



/// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /
/// =============================================================================================
#pragma mark - Macro definitions
/// =============================================================================================
/// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /// /


/// =============================================================================================
#pragma mark - Helpers
/// =============================================================================================

//clever macro trick to allow "overloading" macro functions thanks to orj's gist: https://gist.github.com/985501
#define _CAT(a, b) _PRIMITIVE_CAT(a, b)
#define _PRIMITIVE_CAT(a, b) a##b
#define _N_ARGS(...) _N_ARGS_1(__VA_ARGS__, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define _N_ARGS_1(...) _N_ARGS_2(__VA_ARGS__)
#define _N_ARGS_2(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, n, ...) n

//maco to convert cstring to NSString
#define NSRStringFromCString(cstr)	[NSString stringWithCString:cstr encoding:NSUTF8StringEncoding]

//adding a # before va_args will simply make its contents a cstring
#define _MAKE_STR(...)	NSRStringFromCString(#__VA_ARGS__)


/// =============================================================================================
#pragma mark NSRailsSync
/// =============================================================================================

//define NSRailsSync to create a method called NSRailsSync, which returns the entire param list
#define NSRailsSync(...) \
+ (NSString*) NSRailsSync { return _MAKE_STR(__VA_ARGS__); }

//define NSRNoCarryFromSuper as "_NSR_NO_SUPER" - not a string, since it's placed directly in the macro
#define NSRNoCarryFromSuper			_NSR_NO_SUPER_

//returns the string version of NSRNoCarryFromSuper so we can find it when evaluating NSRailsSync string
#define _NSRNoCarryFromSuper_STR	_MAKE_STR(_NSR_NO_SUPER_)



/// =============================================================================================
#pragma mark NSRailsUseModelName
/// =============================================================================================

//define NSRailsUseModelName to concat either _NSR_Name1(x) or _NSR_Name2(x,y), depending on the number of args passed in
#define NSRailsUseModelName(...) _CAT(_NSR_Name,_N_ARGS(__VA_ARGS__))(__VA_ARGS__)

//using default is the same thing as passing nil for both model name + plural name
#define NSRailsUseDefaultModelName _NSR_Name2(nil,nil)

//_NSR_Name1 (only with 1 parameter, ie, custom model name but default plurality), creates NSRailsUseModelName method that returns param, return nil for plural to make it go to default
#define _NSR_Name1(name) \
+ (NSString*) NSRailsUseModelName { return name; } \
+ (NSString*) NSRailsUsePluralName { return nil; }

//_NSR_Name2 (2 parameters, ie, custom model name and custom plurality), creates NSRailsUseModelName and NSRailsUsePluralName
#define _NSR_Name2(name,plural)  \
+ (NSString*) NSRailsUseModelName { return name; } \
+ (NSString*) NSRailsUsePluralName { return plural; }


/// =============================================================================================
#pragma mark NSRailsUseConfig
/// =============================================================================================

//works the same way as NSRailsUseModelName

#define NSRailsUseConfig(...) _CAT(_NSR_Config,_N_ARGS(__VA_ARGS__))(__VA_ARGS__)
#define NSRailsUseDefaultConfig \
+ (NSRConfig *) NSRailsUseConfig { return [NSRConfig defaultConfig]; }
#define _NSR_Config1(url) \
+ (NSRConfig *) NSRailsUseConfig { NSRConfig *config = [[NSRConfig alloc] init]; config.appURL = url; return config; }
#define _NSR_Config3(url,user,pass)  \
+ (NSRConfig *) NSRailsUseConfig { NSRConfig *config = [[NSRConfig alloc] init]; config.appURL = url; config.appUsername = user; config.appPassword = pass; return config; }

/// =============================================================================================
#pragma mark - NSRails
/// =============================================================================================

//this will be the NSRailsSync for NSRailsModel, basis for all subclasses
//use remoteID as equivalent for rails property id
#define NSRAILS_BASE_PROPS @"remoteID=id"

//log NSR errors by default
#define NSRLogErrors 0

#if NSRLogErrors
#define NSRWarn	NSLog
#else
#define NSRWarn(...)
#endif

