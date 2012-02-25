//
//  NSRails.h
//  NSRails
//
//  Created by Dan Hassin on 1/10/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSRConfig.h"

//log NSR errors by default
#define NSRLogErrors

typedef void(^NSRBasicCompletionBlock)(NSError *error);
typedef void(^NSRGetAllCompletionBlock)(NSArray *allRemote, NSError *error);
typedef void(^NSRGetObjectCompletionBlock)(id object, NSError *error);

@interface NSRailsModel : NSObject
{
	NSNumber *modelID;
	NSDictionary *remoteAttributes;
	
	NSMutableArray *sendableProperties;
	NSMutableArray *retrievableProperties;
	NSMutableArray *encodeProperties;
	NSMutableArray *decodeProperties;
	NSMutableDictionary *nestedModelProperties;
	NSMutableDictionary *propertyEquivalents;
	
	//for nested models
	//remember that rails-side needs to implement ":allow_destroy => true" on accepts_nested_attributes_for
	BOOL destroyOnNesting;
}

@property (nonatomic, strong) NSNumber *modelID;
@property (nonatomic, strong, readonly) NSDictionary *remoteAttributes;

@property (nonatomic) BOOL destroyOnNesting;

///////
//CRUD
///////

/////////////////////////
//sync, no error retrieval
- (BOOL) remoteGetLatest;
- (BOOL) remoteUpdate;
- (BOOL) remoteCreate;
- (BOOL) remoteDestroy;

+ (NSArray *) remoteAll;
+ (id) remoteObjectWithID:(NSInteger)mID;

/////////////////////////
//sync
- (BOOL) remoteGetLatest:(NSError **)error;
- (BOOL) remoteUpdate:(NSError **)error;
- (BOOL) remoteCreate:(NSError **)error;
- (BOOL) remoteDestroy:(NSError **)error;

+ (NSArray *) remoteAll:(NSError **)error;
+ (id) remoteObjectWithID:(NSInteger)mID error:(NSError **)error;

///////////////////////////
//async
- (void) remoteGetLatestAsync:(NSRBasicCompletionBlock)completionBlock;
- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock;
- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock;
- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock;

+ (void) remoteAllAsync:(NSRGetAllCompletionBlock)completionBlock;
+ (void) remoteObjectWithID:(NSInteger)mID async:(NSRGetObjectCompletionBlock)completionBlock;


///////////////////////////////////////
//custom methods (not CRUD) on instance
///////////////////////////////////////

- (NSString *)	remoteMakeGETRequestWithRoute:(NSString *)route error:(NSError **)error;
- (void)		remoteMakeGETRequestWithRoute:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;

//will send itself as requestBody
- (NSString *)	remoteMakeRequestSendingSelf:(NSString *)httpVerb route:(NSString *)route error:(NSError **)error;
- (void)		remoteMakeRequestSendingSelf:(NSString *)httpVerb route:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;

- (NSString *)	remoteMakeRequest:(NSString *)httpVerb requestBody:(NSString *)body route:(NSString *)route error:(NSError **)error;
- (void)		remoteMakeRequest:(NSString *)httpVerb requestBody:(NSString *)body route:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;


///////////////////////////////////////
//custom methods (not CRUD) on class
//if called on a subclass, will direct it to the controller ([User makeGET:@"hello"] => myapp.com/users/hello)
//if called on NSRailsModel, will direct it to the app's root ([NSRailsModel makeGET:@"hello"] => myapp.com/hello)
///////////////////////////////////////

+ (NSString *)	remoteMakeGETRequestWithRoute:(NSString *)httpVerb error:(NSError **)error;
+ (void)		remoteMakeGETRequestWithRoute:(NSString *)httpVerb async:(NSRHTTPCompletionBlock)completionBlock;

+ (NSString *)	remoteMakeRequest:(NSString *)httpVerb requestBody:(NSString *)body route:(NSString *)route error:(NSError **)error;
+ (void)		remoteMakeRequest:(NSString *)httpVerb requestBody:(NSString *)body route:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;

+ (NSString *)	remoteMakeRequest:(NSString *)httpVerb sendObject:(NSRailsModel *)obj route:(NSString *)route error:(NSError **)error;
+ (void)		remoteMakeRequest:(NSString *)httpVerb sendObject:(NSRailsModel *)obj route:(NSString *)route async:(NSRHTTPCompletionBlock)completionBlock;


///////////////////////////////////////////
//manual json encoding/decoding
//will use whatever inputted in NSRailsSync()
///////////////////////////////////////////

- (NSString *) remoteJSONRepresentation;
- (NSDictionary *) dictionaryOfRemoteProperties;

- (BOOL) setAttributesAsPerRemoteJSON:(NSString *)json;
- (void) setAttributesAsPerRemoteDictionary:(NSDictionary *)dict;
- (id) initWithRemoteAttributesDictionary:(NSDictionary *)railsDict;

//manual sync properties string, specific for that instance
- (id) initWithRailsSyncProperties:(NSString *)str;



///////////////////
//macro definitions
///////////////////

//clever macro trick to allow "overloading" macro functions thanks to orj's gist: https://gist.github.com/985501
#define CAT(a, b) _PRIMITIVE_CAT(a, b)
#define _PRIMITIVE_CAT(a, b) a##b
#define N_ARGS(...) N_ARGS_1(__VA_ARGS__, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define N_ARGS_1(...) N_ARGS_2(__VA_ARGS__)
#define N_ARGS_2(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, n, ...) n

//maco to convert cstring to NSString
#define NSRStringFromCString(cstr)	[NSString stringWithCString:cstr encoding:NSUTF8StringEncoding]
//adding a # before va_args will simply make its contents a cstring
#define _MAKE_STR(...)	NSRStringFromCString(#__VA_ARGS__)

//NSRails macros

//////////////
//NSRailsSync
//define NSRailsSync to create a method called NSRailsSync, which returns the entire param list
#define NSRailsSync(...) \
+ (NSString*) NSRailsSync { return _MAKE_STR(__VA_ARGS__); }

//define NSRNoCarryFromSuper as "_NSR_NO_SUPER" - not a string, since it's placed directly in the macro
#define NSRNoCarryFromSuper			_NSR_NO_SUPER_

//returns the string version of NSRNoCarryFromSuper so we can find it when evaluating NSRailsSync string
#define _NSRNoCarryFromSuper_STR	_MAKE_STR(_NSR_NO_SUPER_)

////////////
//NSRailsUseModelName
//define NSRailsUseModelName to concat either _NSR_Name1(x) or _NSR_Name2(x,y), depending on the number of args passed in
#define NSRailsUseModelName(...) CAT(_NSR_Name,N_ARGS(__VA_ARGS__))(__VA_ARGS__)

//using default is the same thing as passing nil for both model name + plural name
#define NSRailsUseDefaultModelName _NSR_Name2(nil,nil)

//_NSR_Name1 (only with 1 parameter, ie, custom model name but default plurality), creates NSRailsUseModelName method that returns param, return nil for plural to make it go to default
#define _NSR_Name1(x) \
+ (NSString*) NSRailsUseModelName { return x; } \
+ (NSString*) NSRailsUsePluralName { return nil; }

//_NSR_Name2 (2 parameters, ie, custom model name and custom plurality), creates NSRailsUseModelName and NSRailsUsePluralName
#define _NSR_Name2(x,y)  \
+ (NSString*) NSRailsUseModelName { return x; } \
+ (NSString*) NSRailsUsePluralName { return y; }

/////////////
//NSRailsUseConfig

//works the same way as NSRailsUseModelName

#define NSRailsUseConfig(...) CAT(_NSR_Config,N_ARGS(__VA_ARGS__))(__VA_ARGS__)
#define NSRailsUseDefaultConfig \
+ (NSRConfig *) NSRailsUseConfig { return [NSRConfig defaultConfig]; }
#define _NSR_Config1(x) \
+ (NSRConfig *) NSRailsUseConfig { NSRConfig *config = [[NSRConfig alloc] init]; config.appURL = x; return config; }
#define _NSR_Config3(x,y,z)  \
+ (NSRConfig *) NSRailsUseConfig { NSRConfig *config = [[NSRConfig alloc] init]; config.appURL = x; config.appUsername = y; config.appPassword = z; return config; }


@end

