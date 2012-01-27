//
//  RailsModel.h
//  Storyline
//
//  Created by Dan Hassin on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RailsConfig.h"

#define MakeRails(rails_properties) \
	+ (NSString*) MakeRails { return [[super MakeRails] stringByAppendingFormat:@", %@", rails_properties]; }
#define MakeRailsNoSuper(rails_properties) \
	+ (NSString*) MakeRailsNoSuper { return rails_properties; }

#define ModelName(exact_rails_model) \
	+ (NSString*) ModelName { return exact_rails_model; }
#define ModelNameWithPlural(exact_rails_model,exact_rails_model_plural) \
	+ (NSString*) ModelName { return exact_rails_model; } + (NSString*) PluralModelName { return exact_rails_model_plural; }

@interface RailsModel : NSObject
{
	NSNumber *modelID;
	NSDictionary *attributes;
	
	NSMutableArray *sendableProperties;
	NSMutableArray *retrievableProperties;
	NSMutableArray *encodeProperties;
	NSMutableArray *decodeProperties;
	NSMutableDictionary *modelRelatedProperties;
	NSMutableDictionary *propertyEquivalents;
	
	//for nested models
	//remember that rails-side needs to implement ":allow_destroy => true" on accepts_nested_attributes_for
	//this won't destroy this object, only destroy its RELATION. to destroy it use destroyRemote
	BOOL destroyOnNesting;
}

@property (nonatomic, strong) NSNumber *modelID;
@property (nonatomic, strong, readonly) NSDictionary *attributes;

@property (nonatomic) BOOL destroyOnNesting;

//config
+ (void) setAppURL:(NSString *)str;
+ (void) setAppUsername:(NSString *)str;
+ (void) setAppPassword:(NSString *)str;


//rails methods
+ (id) getRemoteObjectWithID:(int)mID;
+ (id) getRemoteObjectWithID:(int)mID error:(NSError **)error;

- (BOOL) getRemoteLatest;
- (BOOL) updateRemote;
- (BOOL) createRemote;
- (BOOL) destroyRemote;
+ (NSArray *) getAllRemote;

- (BOOL) getRemoteLatest:(NSError **)error;
- (BOOL) updateRemote:(NSError **)error;
- (BOOL) createRemote:(NSError **)error;
- (BOOL) destroyRemote:(NSError **)error;
+ (NSArray *) getAllRemote:(NSError **)error;

- (BOOL) updateRemote:(NSError **)error excluding:(NSString *)exc, ... NS_REQUIRES_NIL_TERMINATION;
- (BOOL) createRemote:(NSError **)error excluding:(NSString *)exc, ... NS_REQUIRES_NIL_TERMINATION;

- (BOOL) updateRemoteExcludingNilValues:(NSError **)error;
- (BOOL) createRemoteExcludingNilValues:(NSError **)error;

//custom methods (not CRUD)
- (NSString *) makeGETRequestWithMethod:(NSString *)method error:(NSError **)error;
- (NSString *) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error;

//if called on a subclass, will direct it to the controller ([User makeGET:@"hello"] => myapp.com/users/hello)
//if called on RailsModel, will direct it to the app's root ([RailsModel makeGET:@"hello"] => myapp.com/hello)
+ (NSString *) makeGETRequestWithMethod:(NSString *)method error:(NSError **)error;
+ (NSString *) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error;

// will use whatever inputted in RailsMake()
- (NSString *) JSONRepresentation;
- (BOOL) setAttributesAsPerJSON:(NSString *)json;


+ (NSString *) MakeRails;


@end

