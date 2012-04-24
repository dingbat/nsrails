/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRails.h
 
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
#import "NSRConfig.h"

@class NSRPropertyCollection;

static NSString * const NSRailsNullRemoteIDException = @"NSRailsNullRemoteIDException";

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

// returns YES if any changes were made to the local object, NO if object was identical before/after
- (BOOL) setPropertiesUsingRemoteJSON:(NSString *)json;
- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict;

- (id) initWithRemoteDictionary:(NSDictionary *)railsDict;
- (id) initWithRemoteJSON:(NSString *)json;


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

//macro to convert cstring to NSString
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
_NSR_Config3(nil, nil, nil)

#define _NSR_Config1(url) \
_NSR_Config3(url, nil, nil)

#define _NSR_Config3(url,user,pass)  \
+ (NSRConfig *) NSRailsUseConfigURL { return url; } \
+ (NSRConfig *) NSRailsUseConfigUsername { return user; } \
+ (NSRConfig *) NSRailsUseConfigPassword { return pass; }

