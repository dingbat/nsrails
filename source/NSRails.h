//
//  NSRails.h
//  NSRails
//
//  Created by Dan Hassin on 1/10/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSRConfig.h"

#define NSRLogError(error)	NSLog(@"Error Domain=%@ Code=%d \"%@\"",error.domain,error.code,[error localizedDescription]);
#define NSRValidationErrorsKey	@"validation errors"

//log NSR errors by default
#define NSRLogErrors

@interface NSRailsModel : NSObject
{
	NSNumber *modelID;
	NSDictionary *attributes;
	
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
@property (nonatomic, strong, readonly) NSDictionary *attributes;

@property (nonatomic) BOOL destroyOnNesting;

//////
//CRUD
//////

//sync, no error retrieval
- (BOOL) getRemoteLatest;
- (BOOL) updateRemote;
- (BOOL) createRemote;
- (BOOL) destroyRemote;

+ (NSArray *) getAllRemote;
+ (id) getRemoteObjectWithID:(int)mID;

//sync
- (BOOL) getRemoteLatest:(NSError **)error;
- (BOOL) updateRemote:(NSError **)error;
- (BOOL) createRemote:(NSError **)error;
- (BOOL) destroyRemote:(NSError **)error;

+ (NSArray *) getAllRemote:(NSError **)error;
+ (id) getRemoteObjectWithID:(int)mID error:(NSError **)error;

//async
- (void) getRemoteLatestAsync:(void(^)(NSError *error))completionBlock;
- (void) updateRemoteAsync:(void(^)(NSError *error))completionBlock;
- (void) createRemoteAsync:(void(^)(NSError *error))completionBlock;
- (void) destroyRemoteAsync:(void(^)(NSError *error))completionBlock;

+ (void) getAllRemoteAsync:(void(^)(NSArray *allRemote, NSError *error))completionBlock;
+ (void) getRemoteObjectWithID:(int)mID async:(void(^)(id object, NSError *error))completionBlock;


///////////////////////////////////////
//custom methods (not CRUD) on instance
///////////////////////////////////////

- (NSString *)	makeGETRequestWithMethod:(NSString *)method error:(NSError **)error;
- (void)		makeGETRequestWithMethod:(NSString *)method async:(void(^)(NSString *result, NSError *error))completionBlock;

- (NSString *)	makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error;
- (void)		makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method async:(void(^)(NSString *result, NSError *error))completionBlock;


///////////////////////////////////////
//custom methods (not CRUD) on class
//if called on a subclass, will direct it to the controller ([User makeGET:@"hello"] => myapp.com/users/hello)
//if called on NSRailsModel, will direct it to the app's root ([NSRailsModel makeGET:@"hello"] => myapp.com/hello)
///////////////////////////////////////

+ (NSString *)	makeGETRequestWithMethod:(NSString *)method error:(NSError **)error;
+ (void)		makeGETRequestWithMethod:(NSString *)method async:(void(^)(NSString *result, NSError *error))completionBlock;

+ (NSString *)	makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error;
+ (void)		makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method async:(void(^)(NSString *result, NSError *error))completionBlock;


///////////////////////////////////////////
//manual json encoding/decoding
//will use whatever inputted in NSRailsUse()
///////////////////////////////////////////

- (NSString *) JSONRepresentation;
- (BOOL) setAttributesAsPerJSON:(NSString *)json;


+ (void) setClassConfig:(NSRConfig *)config;


//macros

//#define NSRPropertyMacro		NSRailsUse
//#define NSRModelNameMacro		NSRailsModelName
//#define NSRModelNamePlMacro		NSRailsModelNameWithPlural
//#define NSRConfigMacro			NSRailsSetConfig
//#define NSRConfigAuthMacro		NSRailsSetConfigAuth

#define NSRStringFromCString(cstr)	[NSString stringWithCString:cstr encoding:NSUTF8StringEncoding]

+ (NSString *) NSRailsUse;

#define NSRailsUse(rails_properties) \
+ (NSString*) NSRailsUse { return [[super NSRailsUse] stringByAppendingFormat:@", %@", NSRStringFromCString(rails_properties)]; }
#define NSRailsUseNoSuper(rails_properties) \
+ (NSString*) NSRailsUseNoSuper { return NSRStringFromCString(rails_properties); }

#define NSRailsModelName(exact_rails_model) \
+ (NSString*) NSRailsModelName { return NSRStringFromCString(exact_rails_model); }

#define NSRailsModelNameWithPlural(exact_rails_model,exact_rails_model_plural) \
+ (NSString*) NSRailsModelName { return NSRStringFromCString(exact_rails_model); } + (NSString*) NSRailsModelNameWithPlural { return NSRStringFromCString(exact_rails_model_plural); }

#define NSRailsSetConfig(app_url_for_model) \
+ (NSRConfig *) NSRailsSetConfig { NSRConfig *config = [[NSRConfig alloc] init]; config.appURL = NSRStringFromCString(app_url_for_model); return config; }

#define NSRailsSetConfigAuth(app_url_for_model, username, password) \
+ (NSRConfig *) NSRailsSetConfigAuth { NSRConfig *config = [[NSRConfig alloc] init]; config.appURL = NSRStringFromCString(app_url_for_model); config.appUsername = username; config.appPassword = password; return config; }


@end

