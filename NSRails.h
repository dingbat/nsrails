//
//  RailsModel.h
//  Storyline
//
//  Created by Dan Hassin on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSRConfig.h"

#define NSRLogError(error)	NSLog(@"Error Domain=%@ Code=%d \"%@\"",error.domain,error.code,[error localizedDescription]);

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

/* is this bad practice?
 
- (BOOL) updateRemoteExcluding:(NSArray *)exc error:(NSError **)error;
- (BOOL) updateRemoteExcluding:(NSArray *)exc async:(void(^)(NSError *error))completionBlock;

- (BOOL) createRemoteExcluding:(NSArray *)exc error:(NSError **)error;
- (BOOL) createRemoteExcluding:(NSArray *)exc async:(void(^)(NSError *error))completionBlock;

- (BOOL) getRemoteLatestExcluding:(NSArray *)exc error:(NSError **)error;
- (BOOL) getRemoteLatestExcluding:(NSArray *)exc async:(void(^)(NSError *error))completionBlock;

- (BOOL) getRemoteLatestOnlyForProperties:(NSArray *)exc error:(NSError **)error;
- (BOOL) getRemoteLatestOnlyForProperties:(NSArray *)exc async:(void(^)(NSError *error))completionBlock;
*/

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
//if called on RailsModel, will direct it to the app's root ([RailsModel makeGET:@"hello"] => myapp.com/hello)
///////////////////////////////////////

+ (NSString *)	makeGETRequestWithMethod:(NSString *)method error:(NSError **)error;
+ (void)		makeGETRequestWithMethod:(NSString *)method async:(void(^)(NSString *result, NSError *error))completionBlock;

+ (NSString *)	makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error;
+ (void)		makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method async:(void(^)(NSString *result, NSError *error))completionBlock;

///////////////////////////////////////////
//manual json encoding/decoding
//will use whatever inputted in RailsMake()
///////////////////////////////////////////

- (NSString *) JSONRepresentation;
- (BOOL) setAttributesAsPerJSON:(NSString *)json;



//macros
+ (NSString *) MakeRails;
#define MakeRails(rails_properties) \
+ (NSString*) MakeRails { return [[super MakeRails] stringByAppendingFormat:@", %@", rails_properties]; }
#define MakeRailsNoSuper(rails_properties) \
+ (NSString*) MakeRailsNoSuper { return rails_properties; }

#define ModelName(exact_rails_model) \
+ (NSString*) ModelName { return exact_rails_model; }
#define ModelNameWithPlural(exact_rails_model,exact_rails_model_plural) \
+ (NSString*) ModelName { return exact_rails_model; } + (NSString*) PluralModelName { return exact_rails_model_plural; }


@end

