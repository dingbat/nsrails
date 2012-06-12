/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRRemoteObject.h
 
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
#import "NSRails.h"

@class NSRRelationship;
@class NSRRequest;

/*************************************************************************
 *************************************************************************
 
  See this documentation all pretty at http://dingbat.github.com/nsrails/

 *************************************************************************
 *************************************************************************/


/**
 
 `NSRRemoteObject` is the primary class in NSRails - any classes that inherit from it will be treated with a "remote correspondance" and ActiveResource-like APIs will be available.
  
 Note that you do not have to define an `id` property for your Objective-C class, as your subclass will inherit `NSRRemoteObject`'s remoteID property. Foreign keys are optional but also unnecessary (see [nesting](https://github.com/dingbat/nsrails/wiki/Nesting) on the NSRails wiki).
 
 ## NSRMap
 
 NSRMap is a macro used to define specific properties to be shared with Rails, along with configurable behaviors. 
 
 It is optional (if omitted, will default to all properties being used). Usage:
 
	@implementation Article
	@synthesize title, content, createdAt;
	NSRMap(*, createdAt -r);
	
	…
 
	@end
 
 Please see its more detailed description on [the NSRails wiki](https://github.com/dingbat/nsrails/wiki/NSRMap).
 
 ## Validation Errors
 
 If a create or update failed due to validation reasons, NSRails will package the validation failures into a dictionary. This can be retrieved using the key constant `NSRValidationErrorsKey` in the `userInfo` property of the error. This dictionary contains **each failed property as a key**, with each respective object being **an array of the reasons that property failed validation**. For instance,
 
	 NSError *error;
	 [user createRemote:&error];
	 if (error)
	 {
		 NSDictionary *validationErrors = [[error userInfo] objectForKey:NSRValidationErrorsKey];
		 
		 for (NSString *property in validationErrors)
		 {
			 for (NSString *reasonForFailure in [validationErrors objectForKey:property])
			 {
				 NSLog(@"%@ %@",property,reasonForFailure);  //=> "Name can't be blank"
			 }
		 }
	 }
 
 <a name="overriding"></a>
 
 ## Overriding
 
 ### Custom model name
 
 remoteModelName should be overriden if the name of this class in Objective-C is different than its corresponding model on your server.
 
 Recommended overriding behavior is to return a string literal:
 
	 @implementation User
	 
	 + (NSString *) remoteModelName
	 {
		 return @"subscriber";
	 }
	 
	 @end
 
 The above example would be needed if the same class is called `User` in Objective-C but `Subscriber` on your server.
 
 **Default Behavior** (when not overriden)
 
 Returns the name of the subclass, lowercase and underscored if [enabled](NSRConfig.html#//api/name/autoinflectsClassNames), and with its prefix stripped if [enabled](NSRConfig.html#//api/name/ignoresClassPrefixes).

 ### Custom controller name
 
 The name of this class's controller on the server - where actions for this class should be routed.
 
 The default behavior (when not overriden) is to pluralize remoteModelName, so if your class was called `User`, by default requests involving its controller would be routed to `/users`. In the example above for custom model names, it would go to `/subscribers` since remoteModelName was overridden.

 However, this can be overridden as well (can also be overridden on its own.)
 
	 @implementation User
 
	 + (NSString *) remoteModelName
	 {
		 return @"subscriber";
	 }
 
	 + (NSString *) remoteControllerName
	 {
		 return @"subscriberz";
	 }
 
	 @end
 
 (I can't even come up with a good example for when this would be necessary.)
 
 ### Nested resource paths
 
 The objectUsedToPrefixRequest: method should be overridden if instances of your subclass class should have their resource path be based off an association.
 
 This may be needed if you define your routes in Rails to look something like:
 
	 MySweetApp::Application.routes.draw do
		 resources :users
			 resources :invites
		 end
	 end
 
 And invites are accessed in relation to some user:
 
	 GET    /users/1/invites.json
	 POST   /users/1/invites.json
	 GET    /users/1/invites/3.json
	 DELETE /users/1/invites/3.json
 
 Typically, this method is overriden with an instance variable that represents a parent:
 
	 @implementation Invite
	 @synthesize user, foo;
	 NSRMap(*, user -b);
	 
	 - (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)request
	 {
		 return user;
	 }
	 
	 @end
 
 Note that if `user`'s remoteID is `nil`, an exception will be thrown (its ID is needed in constructing the route). 
 
 You may also filter requests that you don't want to prefix using the **request** parameter. Let's say you only want this behavior for POST and GET, but want to keep DELETE and PATCH with their traditional routes:
 
	 GET    /users/3/invites.json  "get all the invites for user 3"
	 POST   /users/3/invites.json  "create an invite for user 3"
	 PATCH  /invites/28.json       "update user invite 28"
	 DELETE /invites/28.json       "delete user invite 28"
 
 This could be done by checking **request**'s [httpMethod](NSRRequest.html#//api/name/httpMethod):
 
	 - (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)request
	 {
		 if ([request.httpMethod isEqualToString:@"GET"] || [request.httpMethod isEqualToString:@"POST"])
			 return user;
		 return nil;
	 }
 
 ### Custom encoding/decoding
 
 This method should be overridden if you have a property whose JSON representation should be different than its actual object value when sending and retrieving to/from Rails.
 
	@interface MyClass : NSRRemoteObject

	@property (nonatomic, strong) NSURL *URL;         //on the server this is a plain string
	@property (nonatomic, strong) NSArray *csvArray;  //on the server this is a comma-separated string

	@end
 
 In the example above, we want `URL` to be an NSURL locally and `csvArray` to be an NSArray locally, but have them interact with Rails them as a strings.
 
 Override the encodeValueForKey: method to define custom encodings:
 
	@implementation MyClass

	- (id) encodeValueForProperty:(NSString *)property
	{
		if ([property isEqualToString:@"csvArray"])
		{
			return [csvArray componentsJoinedByString:@","];
		}
		if ([property isEqualToString:@"URL"])
		{
			return [URL absoluteString];	
		}

		return [super encodeValueForProperty:property];
	}
 
 And the decoders: 
 
	- (void) decodeValue:(id)railsObject forProperty:(NSString *)property change:(BOOL *)change
	{
		if ([property isEqualToString:@"csvArray"])
		{
			self.csvArray = [railsObject componentsSeparatedByString:@","];
		}
		else if ([property isEqualToString:@"URL"])
		{
			self.URL = [NSURL URLWithString:railsObject];
		}
		else
		{
			[super decodeValue:railsObj forProperty:property change:change];
		}
	}

	@end
 
 - It is important to make a call to super if your property doesn't require custom encoding/decoding, as the base class implementation will automatically encode/decode nested classes (translate dicts/arrays into instances of their respective NSRRemoteObject subclasses), as well as automatically convert to and from NSDates.
 
 - The `change` parameter can be ignored unless you wish to define a custom check for changes. If the value of `change` is not modified, NSRails will use its own change detection mechanism. This is used to return a value in remoteFetch:changes:.
 
 - Overriding encodeValueForProperty: can be used to define remote-only properties (ie, if your Rails server expects an attribute that you don’t want defined in your Objective-C class). Note here that `uniqueDeviceID` isn’t even a property of the Person class:
	
	@implementation Person
	@synthesize name, age;
	NSRMap(name, age, uniqueDeviceID -s)  //send-only
	 
	- (id) encodeValueForProperty:(NSString *)property
	{
		if ([property isEqualToString:@"uniqueDeviceID"])
		{
			return [[UIDevice currentDevice] uniqueIdentifier];
		}
		
		return [super encodeValueForProperty:property];
	}
	 
	@end
  */

@interface NSRRemoteObject : NSObject <NSCoding>

/// =============================================================================================
/// @name Properties
/// =============================================================================================

/**
 The corresponding local property for `id`.
 
 It should be noted that this property will be automatically updated after remoteCreate:, as will anything else that is returned from that create.
 
 **CoreData**

 This property is used as a "primary key". Trying to insert two objects of the same subclass with the same remoteID in the same context will raise an exception.
 */
@property (nonatomic, strong) NSNumber *remoteID;

/**
 The most recent dictionary of all properties returned by Rails, exactly as it returned it. (read-only)
 
 This will include properties that you may not have defined in your Objective-C class, allowing you to dynamically add fields to your app if the server-side model changes.
 
 Moreover, this will not take into account anything in NSRMap - it is exactly the hash as was sent by Rails.
 
 You're safe to use this property after any method that sets your object's properties from remote. For example:
	
	NSError *error;
	if ([myObj remoteFetch:&error])
	{
		NSDictionary *hashSentByRails = myObj.remoteAttributes;
		…
	}
 
 Calling setPropertiesUsingRemoteDictionary: will also update remoteAttributes to the dictionary passed in.
 */
@property (nonatomic, strong, readonly) NSDictionary *remoteAttributes;

/**
 If true, will remotely destroy this object if sent nested.
 
 If true, this object will include a `_destroy` key on send (ie, when the model nesting it is sent during a remoteUpdate: or remoteCreate:).
 
 This can be useful if you have a lot of nested models you need to destroy - you can do it in one request instead of several repeated destroys on each object.
 
 Note that this is relevant for a nested object only. And, for this to work, make sure `:allow_destroy => true` [is set in your Rails model](https://github.com/dingbat/nsrails/wiki/Nesting).

 **CoreData**

 This property leaves your managed object **unaffected**. You will have to delete it from your context manually if your request was successful.
 */
@property (nonatomic) BOOL remoteDestroyOnNesting;


// =============================================================================================
/// @name Common class requests
// =============================================================================================

/**
 Returns an array of all remote objects (as instances of receiver's class.) Each instance’s properties will be set to those returned by Rails.
 
 Makes a GET request to `/objects` (where `objects` is the pluralization of receiver's model name.)
 
 Request done synchronously. See remoteAllAsync: for asynchronous operation.
 
 **CoreData**

 Each object returned in the array may be an existing or newly inserted object. All objects will reflect properites set to those returned by your server.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return NSArray of instances of receiver's class. Each object’s properties will be set to those returned by Rails.
 */
+ (NSArray *) remoteAll:(NSError **)error;

/**
 Returns an array of all remote objects (as instances of receiver's class), constructed with a parent prefix. Each instance’s properties will be set to those returned by Rails.
 
 Makes a GET request to `/parents/3/objects` (where `parents/3` is the path for the **parentObject**, and `objects` is the pluralization of this model name.)
 
 Request done synchronously. See remoteAllViaObject:async: for asynchronous operation.
 
 **CoreData**
 
 Each object returned in the array may be an existing or newly inserted object. All objects will reflect properites set to those returned by your server.
 
 @param parentObject Remote object by which to request the collection from - establishes pattern for resources depending on nesting. Raises an exception if this object's `remoteID` is nil, as it is used to construct the route.
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return NSArray of instances of receiver's class. Each object’s properties will be set to those returned by Rails.
 */
+ (NSArray *) remoteAllViaObject:(NSRRemoteObject *)parentObject error:(NSError **)error;

/**
 Retrieves an array of all remote objects (as instances of receiver's class.) Each instance’s properties will be set to those returned by Rails.
 
 Asynchronously makes a GET request to `/objects` (where `objects` is the pluralization of receiver's model name.)

 **CoreData**

 Each object returned in the array may be an existing or newly inserted object. All objects will reflect properites set to those returned by your server.
 
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteAllAsync:(NSRFetchAllCompletionBlock)completionBlock;

/**
 Retrieves an array of all remote objects (as instances of receiver's class.) Each instance’s properties will be set to those returned by Rails.
 
 Asynchronously makes a GET request to `/parents/3/objects` (where `parents/3` is the path for the **parentObject**, and `objects` is the pluralization of this model name.)
 
 **CoreData**
 
 Each object returned in the array may be an existing or newly inserted object. All objects will reflect properites set to those returned by your server.
 
 @param parentObject Remote object by which to request the collection from - establishes pattern for resources depending on nesting. Raises an exception if this object's `remoteID` is nil, as it is used to construct the route.
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteAllViaObject:(NSRRemoteObject *)parentObject async:(NSRFetchAllCompletionBlock)completionBlock;


/**
 Returns an instance of receiver's class corresponding to the remote object with that ID.
 
 Makes a GET request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is *objectID*
 
 Request done synchronously. See remoteObjectWithID:async: for asynchronous operation.
 
 **CoreData**

 If request is successful, will attempt to find an existing local object with *objectID*, and update its properties to the server's response. If it cannot find an existing local object with that remoteID, will inserta  new object into the context, with those properties.

 @param objectID The ID of the remote object.
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return Instance of receiver's class with properties from the remote object with that ID.
 */
+ (id) remoteObjectWithID:(NSNumber *)objectID error:(NSError **)error;

/**
 Retrieves an instance receiver's class corresponding to the remote object with that ID.
 
 Asynchronously makes a GET request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is *objectID*)
 
 **CoreData**

 If request is successful, will attempt to find an existing local object with *objectID*, and update its properties to the server's response. If it cannot find an existing local object with that remoteID, will inserta  new object into the context, with those properties.
 
 @param objectID The ID of the remote object.
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteObjectWithID:(NSNumber *)objectID async:(NSRFetchObjectCompletionBlock)completionBlock;



/// =============================================================================================
/// @name CRUD
/// =============================================================================================

/**
 Retrieves the latest remote data for receiver and sets its properties to received response.
 
 Sends a `GET` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 Request made synchronously. See remoteFetchAsync: for asynchronous operation.
 
 Requires presence of remoteID, or will throw an `NSRNullRemoteIDException`.
 
 **CoreData**

 If successful and changes are present, will save its managed object context.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`. 
 @return `YES` if fetch was successful. Returns `NO` if an error occurred.
 
 @see remoteFetch:changes:
 */
- (BOOL) remoteFetch:(NSError **)error;

/**
 Retrieves the latest remote data for receiver and sets its properties to received response.
 
 Sends a `GET` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 Request made synchronously. See remoteFetchAsync: for asynchronous operation.
 
 Requires presence of remoteID, or will throw an `NSRNullRemoteIDException`.
 
 **CoreData**

 If successful and changes are present, will save its managed object context.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`. 
 @param changesPtr Pointer to boolean value set to whether or not the receiver changed in any way after the fetch (ie, if this fetch modified one of receiver's local properties due to a change in value server-side). This will also take into account diffs to any nested `NSRRemoteObject` objects that are affected by this fetch (done recursively).
 
 Note that because this only tracks differences in local changes, properties that changed server-side that are not defined in the receiver's class will *not* report back a change (ie, if receiver's class doesn't implement an `updated_at` property and `updated_at` is changed in your remote DB, no change will be reported.) This parameter may be `NULL` if this information is not useful, or use remoteFetch:.
 @return `YES` if fetch was successful. Returns `NO` if an error occurred.
 
 @see remoteFetch:
 */
- (BOOL) remoteFetch:(NSError **)error changes:(BOOL *)changesPtr;


/**
 Retrieves the latest remote data for receiver and sets its properties to received response.
 
 Asynchronously sends a `GET` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 
 Requires presence of remoteID, or will throw an `NSRNullRemoteIDException`.
 
 **CoreData**

 If successful and changes are present, will save its managed object context.

 @param completionBlock Block to be executed when the request is complete. The second parameter passed in is a BOOL whether or not there was a *local* change. This means changes in `updated_at`, etc, will only apply if your Objective-C class implement this as a property as well. This also applies when updating any of its nested objects (done recursively).
 */
- (void) remoteFetchAsync:(NSRFetchCompletionBlock)completionBlock;


/**
 Updates receiver's corresponding remote object.
 
 Sends a request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 Will use the HTTP method defined in the relevant config's [updateMethod](NSRConfig.html#//api/name/updateMethod) property (default `PUT`).
 
 Request made synchronously. See remoteUpdateAsync: for asynchronous operation.

 Requires presence of remoteID, or will throw an `NSRNullRemoteIDException`.
 
 **CoreData**

 If successful, will save its managed object context. Note that changes to the local object will remain even if the request was unsuccessful. It is recommended to implement an undo manager for your managed object context to rollback any changes in this case.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if update was successful. Returns `NO` if an error occurred.

 @warning No local properties will be set, as (by default) Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (BOOL) remoteUpdate:(NSError **)error;

/**
 Updates receiver's corresponding remote object.
 
 Sends a request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 Will use the HTTP method defined in the relevant config's [updateMethod](../NSRConfig.html#//api/name/updateMethod) property(default `PUT`).
 
 Requires presence of remoteID, or will throw an `NSRNullRemoteIDException`.
 
 **CoreData**

 If successful, will save its managed object context. Note that changes to the local object will remain even if the request was unsuccessful. It is recommended to implement an undo manager for your managed object context to rollback any changes in this case.

 @param completionBlock Block to be executed when the request is complete.
 
 @warning No local properties will be set, as (by default) Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock;


/**
 Creates the receiver remotely. Receiver's properties will be set to those given by Rails (including remoteID).
 
 Sends a `POST` request to `/objects` (where `objects` is the pluralization of receiver's model name), with the receiver's remoteDictionaryRepresentationWrapped:YES as its body.
 Request made synchronously. See remoteCreateAsync: for asynchronous operation.

 **CoreData**

 If successful, will save its managed object context to update changed properties like remoteID.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if create was successful. Returns `NO` if an error occurred.
 */
- (BOOL) remoteCreate:(NSError **)error;

/**
 Creates the receiver remotely. Receiver's properties will be set to those given by Rails (including remoteID).
 
 Asynchronously sends a `POST` request to `/objects` (where `objects` is the pluralization of receiver's model name), with the receiver's remote dictionary representation as its body.
 
 **CoreData**

 If successful, will save its managed object context to update changed properties like remoteID.

 @param completionBlock Block to be executed when the request is complete.
 */
- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock;



/**
 Destroys receiver's corresponding remote object. Local object will be unaffected.
 
 Sends a `DELETE` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 Request made synchronously. See remoteDestroyAsync: for asynchronous operation.
 
 **CoreData**

 If successful, will delete itself from its managed object context and save the context.
 
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if destroy was successful. Returns `NO` if an error occurred.
 */
- (BOOL) remoteDestroy:(NSError **)error;

/**
 Destroys receiver's corresponding remote object. Local object will be unaffected.
 
 Asynchronously sends a `DELETE` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 
 **CoreData**

 If successful, will delete itself from its managed object context and save the context.
 
 @param completionBlock Block to be executed when the request is complete.
 */
- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock;

/**
 "Places" receiver's corresponding remote object.
 
 Sends an `PUT` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 
 The distinction between this method and remoteUpdate: is that this method will always use the `PUT` HTTP method, while remoteUpdate: is configurable. This is to allow servers that use `PATCH` to update attributes using remoteUpdate: and keep remoteReplace: for a more accurate "placement" procedure that should occur with the `PUT` method. More discussion [here](http://weblog.rubyonrails.org/2012/2/25/edge-rails-patch-is-the-new-primary-http-method-for-updates/).
 
 Request made synchronously. See remoteReplaceAsync: for asynchronous operation.
 
 Requires presence of remoteID, or will throw an `NSRNullRemoteIDException`.
 
 **CoreData**
 
 If successful, will save its managed object context. Note that changes to the local object will remain even if the request was unsuccessful. It is recommended to implement an undo manager for your managed object context to rollback any changes in this case.
 
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if place was successful. Returns `NO` if an error occurred.
 
 @warning No local properties will be set, as (by default) Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (BOOL) remoteReplace:(NSError **)error;

/**
 "Places" receiver's corresponding remote object.
 
 Asynchronously sends an `PUT` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 
 The distinction between this method and remoteUpdateAsync: is that this method will always use the `PUT` HTTP method, while remoteUpdateAsync: is configurable. This is to allow servers that use `PATCH` to update attributes using remoteUpdateAsync: and keep remoteReplaceAsync: for a more accurate "placement" procedure that should occur with the `PUT` method. More discussion [here](http://weblog.rubyonrails.org/2012/2/25/edge-rails-patch-is-the-new-primary-http-method-for-updates/).
 
 Requires presence of remoteID, or will throw an `NSRNullRemoteIDException`.
 
 **CoreData**
 
 If successful, will save its managed object context. Note that changes to the local object will remain even if the request was unsuccessful. It is recommended to implement an undo manager for your managed object context to rollback any changes in this case.
 
 @param completionBlock Block to be executed when the request is complete.
 
 @warning No local properties will be set, as (by default) Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (void) remoteReplaceAsync:(NSRBasicCompletionBlock)completionBlock;


/// =============================================================================================
/// @name Setting and retrieving JSON representations
/// =============================================================================================


/**
 Serializes the receiver's properties into a dictionary.
  
 @param wrapped If `YES`, wraps the dictionary with a key of the model name:
 
	{"user"=>{"name"=>"x", "email"=>"y"}}
 
 @return The receiver's properties as a dictionary (takes into account rules in NSRMap).
 */
- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped;

/**
 Sets the receiver's properties given a dictionary.
 
 Takes into account rules in NSRMap.
 
 Will set remoteAttributes to *dictionary*.
 
 @param dictionary Dictionary to be evaluated. 
 @return YES if any changes were made to the local object, NO if object was identical before/after.
 */
- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dictionary;

/// =============================================================================================
/// @name Initializers
/// =============================================================================================


/**
 Initializes a new instance of the receiver's class with a given dictionary input.
 
 Takes into account rules in NSRMap.
 
 **CoreData**:
 
 Inserts this new instance into the managed object context set in the currently relevant config.
 
 *Note*: With CoreData, it is highly encouraged to use the findOrInsertObjectUsingRemoteDictionary: instead of this. findOrInsertObjectUsingRemoteDictionary: uses a find-or-create strategy to ensure that an object with the same remoteID doesn't already exist in the store (which would raise an exception otherwise).
 
 @param dictionary Dictionary to be evaluated. The keys in this dictionary (being a *remote* dictionary) should have remote keys, since this will pass through NSRMap (eg, "id", not "remoteID", and if a special equivalence isn't defined, "my_property", not "myProperty").
 
 Note that this dictionary needs to be JSON-parasable, meaning all keys are strings and all objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
 @return A new instance of the receiver's class with properties set using *dictionary*.
 */
+ (id) objectWithRemoteDictionary:(NSDictionary *)dictionary;

/// =============================================================================================
/// @name Methods to override
/// =============================================================================================

/**
 The equivalent name of this class on your server.
 
 See [overriding](#overriding) for more details.

 **Default Behavior** (when not overriden)
 
 Returns the name of the subclass, lowercase and underscored if [enabled](NSRConfig.html#//api/name/autoinflectsClassNames), and with its prefix stripped if [enabled](NSRConfig.html#//api/name/ignoresClassPrefixes).
 
 @warning When overriding this method, NSRails will no longer autoinflect for determining this class name! What you enter will be used exactly.
 */
+ (NSString *) remoteModelName;

/**
 The name of this class's controller on the server.
 
 See [overriding](#overriding) for more details.
 
 **Default Behavior** (when not overriden)
 
 Pluralizes remoteModelName.
 */
+ (NSString *) remoteControllerName;

/**
 Used if instances of this class should have their resource path be based off an association.

 See [overriding](#overriding) for more details.

 @param request The request whose path is currently being evalutated. Its [route](NSRRequest.html#//api/name/route) will be the route *before* adding the prefix (ie, the route used if the behavior is not desired).
 
 @return An object (typically an instance variable) that represents a parent to this class, or `nil` if this behavior is not desired.
 */
- (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)request;

/**
 Should return the remote representation for each property.
 
 See [overriding](#overriding) for more details.
 
 @param property Name of the property.
 @return Remote representation for *key*. Must be JSON-parsable (NSDictionary, NSArray, NSString, NSNumber, or (NSNull or nil)).
 
 @warning Make sure you make a call to super if a certain property shouldn't be custom-coded.
 */
- (id) encodeValueForProperty:(NSString *)property;

/**
 Should set what you want an Objective-C property to be set to, based off a remote representation.
 
 See [overriding](#overriding) for more details.
 
 @param railsObject Remote representation of this key. Will be a JSON-parsed object (NSDictionary, NSArray, NSString, NSNumber, or nil).
 @param property Name of the property.
 @param change Reference to a change boolean. This can (and usually will) be ignored.
  
 @warning Make sure you make a call to super if a certain property shouldn't be custom-coded.
 */
- (void) decodeValue:(id)railsObject forProperty:(NSString *)property change:(BOOL *)change;

/** 
 Undocumented
 */
- (BOOL) shouldSendProperty:(NSString *)property nested:(BOOL)nested;

- (NSString *) remoteEquivalenceForProperty:(NSString *)property;
- (NSString *) remoteKeyForProperty:(NSString *)property;
- (NSString *) propertyForRemoteKey:(NSString *)remoteAttributeKey;

/**
 Undocumented
 */
- (NSRRelationship *) relationshipForProperty:(NSString *)property;

/**
 Undocumented
 */
+ (NSDictionary *) remoteProperties;

@end

