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

//needed for block typedefs
#import "NSRConfig.h"

@class NSRRequest;

/*************************************************************************
 *************************************************************************
 
  See this documentation all pretty at http://dingbat.github.com/nsrails/

 *************************************************************************
 *************************************************************************/


/**
 
 `NSRRemoteObject` is the primary class in NSRails - any classes that subclass it will be treated with a "remote correspondance" and ActiveResource-like APIs will be available.
  
 Note that you do not have to define an `id` property for your Objective-C class, as your subclass will inherit NSRRemoteObject's `remoteID` property.
  
 # CoreData
 
 To use NSRails with CoreData, subclass <NSRRemoteManagedObject>.
 
 # Validation Errors
 
 If a create or update failed due to validation reasons, NSRails will package the validation failures into a dictionary. This can be retrieved using the key constant `NSRErrorResponseBodyKey` in the `userInfo` property of the error. This dictionary contains **each failed property as a key**, with each respective object being **an array of the reasons that property failed validation**. For instance,
 
	 NSError *error;
	 if (![user createRemote:&error])
	 {
		 NSDictionary *validationErrors = [[error userInfo] objectForKey:NSRErrorResponseBodyKey];
		 
		 for (NSString *property in validationErrors)
		 {
			 for (NSString *reasonForFailure in [validationErrors objectForKey:property])
			 {
				 NSLog(@"%@ %@",property,reasonForFailure);  //=> "Name can't be blank"
			 }
		 }
	 }
 
 # Overriding Behavior
 
 See the "Methods to Override" section of this class reference. These methods can be overriden for custom per-property behavior.
 
 Remember, **these are not delegate methods**. You **must** make a call to `super` if you're not overriding behavior for that property.
 
 Finally, check out the [NSRails Cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook) for quick overriding recipes.
  */

#ifdef NSR_USE_COREDATA
#define _NSR_SUPERCLASS		NSManagedObject
#else
#define _NSR_SUPERCLASS		NSObject
#endif

@interface NSRRemoteObject : _NSR_SUPERCLASS <NSCoding>

/// =============================================================================================
/// @name Properties
/// =============================================================================================

/**
 The corresponding local property for remote attribute `id`.
 
 It should be noted that this property will be automatically updated after remoteCreate, as will anything else that is returned from that create.
 */
@property (nonatomic, strong) NSNumber *remoteID;

/**
 The most recent dictionary of all properties returned by Rails, exactly as it returned it. (read-only)
 
 This will include properties that you may not have defined in your Objective-C class, allowing you to dynamically add fields to your app if the server-side model changes. This dictionary won't go through any of the encoding methods - it'll be exactly the dictionary as was sent in JSON.
 
 You're safe to use this property after any method that sets your object's properties from remote. For example:
	
	NSError *error;
	if ([myObj remoteFetch:&error])
	{
		NSDictionary *hashSentByRails = myObj.remoteAttributes;
		…
	}
 
 Calling `<setPropertiesUsingRemoteDictionary:>` will also update remoteAttributes to the dictionary passed in.
 */
@property (nonatomic, strong, readonly) NSDictionary *remoteAttributes;

/**
 If true, will remotely destroy this object if sent nested.
 
 If true, this object will include a `_destroy` key on send (ie, when the model nesting it is sent during a `<remoteUpdate:>` or `<remoteCreate:>`).
 
 This can be useful if you have a lot of nested models you need to destroy - you can do it in one request instead of several repeated destroys on each object.
 
 Note that this is relevant for a nested object only. And, for this to work, make sure `:allow_destroy => true` [is set in your Rails model](https://github.com/dingbat/nsrails/wiki/Nesting).
 */
@property (nonatomic) BOOL remoteDestroyOnNesting;


// =============================================================================================
/// @name Common controller requests
// =============================================================================================

/**
 Returns an array of all remote objects (as instances of receiver's class.) Each instance’s properties will be set to those returned by Rails.
 
 Makes a GET request to `/objects` (where `objects` is the pluralization of receiver's model name.)
 
 Request made synchronously. See `<remoteAllAsync:>` for asynchronous operation.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return NSArray of instances of receiver's class. Each object’s properties will be set to those returned by Rails.
 */
+ (NSArray *) remoteAll:(NSError **)error;

/**
 Returns an array of all remote objects (as instances of receiver's class), constructed with a parent prefix. Each instance’s properties will be set to those returned by Rails.
 
 Makes a GET request to `/parents/3/objects` (where `parents/3` is the path for the **parentObject**, and `objects` is the pluralization of this model name.)
 
 Request made synchronously. See `<remoteAllViaObject:async:>` for asynchronous operation.
 
 @param parentObject Remote object by which to request the collection from - establishes pattern for resources depending on nesting. Raises an exception if this object's `remoteID` is nil, as it is used to construct the route.
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return NSArray of instances of receiver's class. Each object’s properties will be set to those returned by Rails.
 */
+ (NSArray *) remoteAllViaObject:(NSRRemoteObject *)parentObject error:(NSError **)error;

/**
 Retrieves an array of all remote objects (as instances of receiver's class.) Each instance’s properties will be set to those returned by Rails.
 
 Asynchronously makes a GET request to `/objects` (where `objects` is the pluralization of receiver's model name.)
 
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteAllAsync:(NSRFetchAllCompletionBlock)completionBlock;

/**
 Retrieves an array of all remote objects (as instances of receiver's class.) Each instance’s properties will be set to those returned by Rails.
 
 Asynchronously makes a GET request to `/parents/3/objects` (where `parents/3` is the path for the **parentObject**, and `objects` is the pluralization of this model name.)
 
 @param parentObject Remote object by which to request the collection from - establishes pattern for resources depending on nesting. Raises an exception if this object's `remoteID` is nil, as it is used to construct the route.
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteAllViaObject:(NSRRemoteObject *)parentObject async:(NSRFetchAllCompletionBlock)completionBlock;


/**
 Returns an instance of receiver's class corresponding to the remote object with that ID.
 
 Makes a GET request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is *objectID*
 
 Request made synchronously. See `<remoteObjectWithID:async:>` for asynchronous operation.
 
 @param objectID The ID of the remote object.
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return Instance of receiver's class with properties from the remote object with that ID.
 */
+ (id) remoteObjectWithID:(NSNumber *)objectID error:(NSError **)error;

/**
 Retrieves an instance receiver's class corresponding to the remote object with that ID.
 
 Asynchronously makes a GET request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is *objectID*)
  
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
 
 Request made synchronously. See `<remoteFetchAsync:>` for asynchronous operation.
 
 Requires presence of `<remoteID>`, or will throw an `NSRNullRemoteIDException`.
 
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`. 
 @return `YES` if fetch was successful. Returns `NO` if an error occurred.
 */
- (BOOL) remoteFetch:(NSError **)error;

/**
 Retrieves the latest remote data for receiver and sets its properties to received response.
 
 Asynchronously sends a `GET` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 
 Requires presence of `<remoteID>, or will throw an `NSRNullRemoteIDException`.
 
 @param completionBlock Block to be executed when the request is complete.
 */
- (void) remoteFetchAsync:(NSRBasicCompletionBlock)completionBlock;


/**
 Updates receiver's corresponding remote object.
 
 Sends a request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 Will use the HTTP method defined in the relevant config's [`updateMethod`](NSRConfig.html#//api/name/updateMethod) property (default `PUT`).
 
 Request made synchronously. See `<remoteUpdateAsync:>` for asynchronous operation.

 Requires presence of `<remoteID>, or will throw an `NSRNullRemoteIDException`.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if update was successful. Returns `NO` if an error occurred.

 @warning No local properties will be set, as (by default) Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (BOOL) remoteUpdate:(NSError **)error;

/**
 Updates receiver's corresponding remote object.
 
 Sends a request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's remoteID).
 Will use the HTTP method defined in the relevant config's [`updateMethod`](../NSRConfig.html#//api/name/updateMethod) property(default `PUT`).
 
 Requires presence of `<remoteID>, or will throw an `NSRNullRemoteIDException`.
 
 @param completionBlock Block to be executed when the request is complete.
 
 @warning No local properties will be set, as (by default) Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock;


/**
 Creates the receiver remotely. Receiver's properties will be set to those given by Rails (including remoteID).
 
 Sends a `POST` request to `/objects` (where `objects` is the pluralization of receiver's model name), with the receiver's remoteDictionaryRepresentationWrapped:YES as its body.
 Request made synchronously. See remoteCreateAsync: for asynchronous operation.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if create was successful. Returns `NO` if an error occurred.
 */
- (BOOL) remoteCreate:(NSError **)error;

/**
 Creates the receiver remotely. Receiver's properties will be set to those given by Rails (including `remoteID`).
 
 Asynchronously sends a `POST` request to `/objects` (where `objects` is the pluralization of receiver's model name), with the receiver's remote dictionary representation as its body.
 
 @param completionBlock Block to be executed when the request is complete.
 */
- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock;


/**
 Destroys receiver's corresponding remote object. Local object will be unaffected.
 
 Sends a `DELETE` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
 Request made synchronously. See `<remoteDestroyAsync:>` for asynchronous operation.
  
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if destroy was successful. Returns `NO` if an error occurred.
 */
- (BOOL) remoteDestroy:(NSError **)error;

/**
 Destroys receiver's corresponding remote object. Local object will be unaffected.
 
 Asynchronously sends a `DELETE` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
  
 @param completionBlock Block to be executed when the request is complete.
 */
- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock;

/**
 "Places" receiver's corresponding remote object.
 
 Sends an `PUT` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
 
 The distinction between this method and `<remoteUpdate:>` is that this method will always use the `PUT` HTTP method, while `<remoteUpdate:>` is configurable. This is to allow servers that use `PATCH` to update attributes using `<remoteUpdate:>` and keep `remoteReplace:` for a more accurate "placement" procedure that should occur with the `PUT` method. More discussion [here](http://weblog.rubyonrails.org/2012/2/25/edge-rails-patch-is-the-new-primary-http-method-for-updates/).
 
 Request made synchronously. See remoteReplaceAsync: for asynchronous operation.
 
 Requires presence of `<remoteID>, or will throw an `NSRNullRemoteIDException`.
 
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if place was successful. Returns `NO` if an error occurred.
 
 @warning No local properties will be set, as (by default) Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (BOOL) remoteReplace:(NSError **)error;

/**
 "Places" receiver's corresponding remote object.
 
 Asynchronously sends an `PUT` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
 
 The distinction between this method and `<remoteUpdateAsync:>` is that this method will always use the `PUT` HTTP method, while `<remoteUpdateAsync:>` is configurable. This is to allow servers that use `PATCH` to update attributes using `<remoteUpdateAsync:>` and keep `remoteReplaceAsync:` for a more accurate "placement" procedure that should occur with the `PUT` method. More discussion [here](http://weblog.rubyonrails.org/2012/2/25/edge-rails-patch-is-the-new-primary-http-method-for-updates/).
 
 Requires presence of `<remoteID>, or will throw an `NSRNullRemoteIDException`.
 
 @param completionBlock Block to be executed when the request is complete.
 
 @warning No local properties will be set, as (by default) Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (void) remoteReplaceAsync:(NSRBasicCompletionBlock)completionBlock;


/// =============================================================================================
/// @name Setting and retrieving JSON representations
/// =============================================================================================


/**
 Serializes the receiver's properties into a dictionary.
  
 Uses the coding methods.

 @param wrapped If `YES`, wraps the dictionary with a key of the model name:
 
	{"user"=>{"name"=>"x", "email"=>"y"}}
 
 @return The receiver's properties as a dictionary.
 */
- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped;

/**
 Sets the receiver's properties given a dictionary.
 
 Uses the coding methods.
 
 Will set `<remoteAttributes>` to *dictionary*.

 @param dictionary Dictionary to be evaluated. 
 */
- (void) setPropertiesUsingRemoteDictionary:(NSDictionary *)dictionary;

/// =============================================================================================
/// @name Initializers
/// =============================================================================================


/**
 Initializes a new instance of the receiver's class with a given dictionary input.
   
 @param remoteDictionary Remote dictionary to be evaluated. (e.g., keys are "id", not "remoteID"; "my_property", not "myProperty").
 
 Note that this dictionary needs to be JSON-parasable, meaning all keys are strings and all objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
 @return A new instance of the receiver's class with properties set using *dictionary*.
 */
+ (id) objectWithRemoteDictionary:(NSDictionary *)remoteDictionary;


/// =============================================================================================
/// @name Methods to override
/// =============================================================================================

#define NSRMap(...) \
+ (void) NSRMap __attribute__ ((unavailable("You're now encouraged to override NSRRemoteObject methods for custom property behavior. See nsrails.com for details."))) { } \
+ (void) map_dep { [self NSRMap]; }

/**
 The equivalent name of this class on your server.
 
 remoteModelName should be overriden if the name of this class in Objective-C is different than its corresponding model on your server. Recommended overriding behavior is to return a string literal:
 
     @implementation User
     
     + (NSString *) remoteModelName
     {
         return @"subscriber";
     }
     
     @end
 
 The above example would be needed if the same class is called `User` in Objective-C but `Subscriber` on your server.
 
 **Default Behavior** (when not overriden)
 
 Returns the name of the subclass, lowercase and underscored if [enabled](NSRConfig.html#//api/name/autoinflectsClassNames), and with its prefix stripped if [enabled](NSRConfig.html#//api/name/ignoresClassPrefixes).
 
 @warning When overriding this method, NSRails will no longer autoinflect for determining this class name! What you enter will be used exactly, so make sure it's lowercase, etc.
 */
+ (NSString *) remoteModelName;

/**
 The name of this class's controller on the server - where actions for this class should be routed.
 
 The default behavior (when not overriden) is to pluralize `<remoteModelName>, so if your class was called `User`, by default requests involving its controller would be routed to `/users`. In the example above for custom model names, it would go to `/subscribers` since remoteModelName was overridden.
 
 However, this can be overridden as well, if, lets say, you have an irregular plural: 
 
     @implementation Cactus
     
     + (NSString *) remoteControllerName
     {
        return @"cacti";
     }
     
     @end
     
 **Default Behavior** (when not overriden)
 
 Pluralizes `<remoteModelName>`.
 */
+ (NSString *) remoteControllerName;

#define NSRUseModelName(...) \
+ (void) NSRUseModelName __attribute__ ((unavailable("Override +[NSRRemoteObject remoteModelName] and/or +[NSRRemoteObject remoteControllerName] and return a string literal instead."))) { } \
+ (void) name_dep { [self NSRUseModelName]; }

/**
 Should be overridden if instances of your subclass class should have their resource path be based off an association.
 
 This may be needed if you define your routes in Rails to look something like:
 
     MySweetApp::Application.routes.draw do
       resources :users
         resources :invites
       end
     end
 
 Typically, this method is overriden with an instance variable that represents a parent:
 
     @implementation Invite
     @synthesize user, foo;
 
     - (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)request
     {
         return user;
     }
     
     @end
 
 Now, invites will be accessed in relation to the given user (assume its `remoteID` is 1):
 
     GET    /users/1/invites.json
     POST   /users/1/invites.json
     GET    /users/1/invites/3.json
     DELETE /users/1/invites/3.json

 Note that if `user`'s `<remoteID>` is `nil`, an exception will be thrown (its ID is needed in constructing the route). 
 
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

 @param request The request whose path is currently being evalutated. Its [route](NSRRequest.html#//api/name/route) will be the route *before* adding the prefix (ie, the route used if the behavior is not desired).
 
 @return An object (typically an instance variable) that represents a parent to this class, or `nil` if this behavior is not desired.
 */
- (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)request;

#define NSRUseResourcePrefix(...) \
+ (void) NSRUseResourcePrefix __attribute__ ((unavailable("Override -[NSRRemoteObject objectUsedToPrefixRequest:] and return the instance variable instead."))) { } \
+ (void) prefix_dep { [self NSRUseResourcePrefix]; }

/**
 Should return the remote representation for each property, optionally modifying the remote key.
 
 This method should be overridden if you have a property whose JSON representation should be different than its actual object value when sending and retrieving to/from Rails.
 
     @interface MyClass : NSRRemoteObject
     
     @property (nonatomic, strong) NSURL *URL;         //on the server this is a plain string
     @property (nonatomic, strong) NSArray *csvArray;  //on the server this is a comma-separated string
     
     @end
 
 In the example above, we can't send these objects to a server as-is, since the server expects strings for both of these. We want to send `URL` as its actual content (remember, NSURL is not JSON-encodable), and send the array `csvArray` as a plain, comma-separated string. Here's a possible overridden implementation:
 
     @implementation MyClass
     
     - (id) encodeValueForProperty:(NSString *)property remoteKey:(NSString **)remoteKey
     {
         if ([property isEqualToString:@"csvArray"])
             return [csvArray componentsJoinedByString:@","];
         
         if ([property isEqualToString:@"URL"])
             return [URL absoluteString];
         
         return [super encodeValueForProperty:property remoteKey:remoteKey];
     }
 
     @end

 Moreover, custom remote keys can be defined here, if the names of your Objective-C property and remote attribute differ. Simply set the contents of the *remoteKey* reference. That's the key it will be sent with.
 
     - (id) encodeValueForProperty:(NSString *)property remoteKey:(NSString **)remoteKey
     {
         if ([property isEqualToString:@"objcProperty"])
             *remoteKey = @"rails_attr";
         
         return [super encodeValueForProperty:property remoteKey:remoteKey];
     }

 Note: the default implementation of this method will automatically take care of NSDates for you, encoding them into a date format string that's Rails-friendly. The format used can be changed in [this](NSRConfig.html#//api/name/dateFormat) NSRConfig property.

 @param property Name of the property.
 @param remoteKey Reference to an NSString that contains the key that should be put into the JSON going out. Will contain the key that would be sent by default (ie, underscored, if [enabled](NSRConfig.html#//api/name/autoinflectsPropertyNames)).
 
 @return Remote representation for this property. Return value must be JSON-parsable (NSDictionary, NSArray, NSString, NSNumber, or (NSNull or nil)).
 
 @warning Make sure you make a call to super if a certain property shouldn't be custom-coded.
 */
- (id) encodeValueForProperty:(NSString *)property remoteKey:(NSString **)remoteKey;

/**
 Should set what you want an Objective-C property to be set to, based off a remote representation.
 
 This method should be overridden if you have a property whose JSON representation should be different than its actual object value when sending and retrieving to/from Rails.
 
     @interface MyClass : NSRRemoteObject
     
     @property (nonatomic, strong) NSURL *URL;         //on the server this is a plain string
     @property (nonatomic, strong) NSArray *csvArray;  //on the server this is a comma-separated string
 
     @end
 
 In the example above, we want `URL` to be decoded (saved) as an NSURL locally and `csvArray` to be decoded as an NSArray locally, but Rails sends them to us as plain strings. Here's a possible overridden implementation:
 
     - (void) decodeValue:(id)remoteObject forRemoteKey:(NSString *)remoteKey
     {
         if ([forRemoteKey isEqualToString:@"csv_array"])
         {
            self.csvArray = [remoteObject componentsSeparatedByString:@","];
         }
         else if ([forRemoteKey isEqualToString:@"url"])
         {
            self.URL = [NSURL URLWithString:remoteObject];
         }
         else
		 {
            [super decodeValue:remoteObject forRemoteKey:remoteKey];
		 }
     }

 Note: the default implementation of this method will automatically take care of NSDates for you, decoding them into an NSDate object using the Rails date format. The format used can be changed in [this](NSRConfig.html#//api/name/dateFormat) NSRConfig property.
 
 Also note that this should not be overridden for only a simple change in local/remote property naming. If your server has a different property name than your Objective-C code, but otherwise decodes the same, simply override `<propertyForRemoteKey:>`.
 
 @param remoteObject Remote representation of this key. Will be a JSON-parsed object (NSDictionary, NSArray, NSString, NSNumber, or nil).
 @param remoteKey The remote key returned from Rails. Use `<propertyForRemoteKey:>` if you want the Objective-C property version of this key.
  
 @warning Make sure you make a call to super if a certain property shouldn't be custom-coded.
 */
- (void) decodeRemoteValue:(id)remoteObject forRemoteKey:(NSString *)remoteKey;

/** 
 Should return whether or not a certain property should be sent in the outgoing dictionary.
 
 Default behavior is to **not** send if:
 
 - Property is `<remoteID>` and it is `nil`, or, `nested` is false. (Sending `id` is only relevant to ensure nested objects are not re-created.)
 - Property is not a timestamp (`created at`, `updated at`).
 - Property is a relationship, would send the full `_attributes`, and `nested` is true (ie, only send "shallow" copies of objects when they are being nested. This is to prevent infinite loops when recursively sending nested properties that could also include this object).
 - Property is a relationship, but the value of the property is either `nil` or an empty collection. (No reason to send empty `_attributes`).
 
 Otherwise the property is sent. So typically, this method is overridden if you do not wish to have a property in an outgoing request. Overriding this method would look like this:
 
     - (BOOL) shouldSendProperty:(NSString *)property whenNested:(BOOL)nested
     {
        //never send retrieveOnlyProperty to your server
        if ([property isEqualToString:@"retrieveOnlyProperty"])
            return NO;
 
        //deepNest is a property with a has-one/has-many relationship that would otherwise not be sent when this object is *nested*
        if ([property isEqualToString:@"deepNest"] && nested)
            return YES;
     
        return [super shouldSendProperty:property whenNested:nested];
     }
 
 The equivalent for this method for *retrieving* properties ("shouldSetProperty") is done through `<decodeRemoteValue:forRemoteKey:>`. Simply override it and do nothing for that property if you do not want to decode & set it from a remote value.
 
 @param property The name of the property.
 @param nested Whether or not the receiving object is being nested.
 @return YES if the property should be included in the dictionary, NO if it shouldn't.
 
 @warning Make sure you make a call to super if a certain property shouldn't be manually managed.
 */
- (BOOL) shouldSendProperty:(NSString *)property whenNested:(BOOL)nested;

/**
 Should return the class for the nested object stored in the property, or nil if it is not a nested object.
 
 The default behavior is to simply return the *type* of the property if it is a subclass of NSRRemoteObject. Otherwise, returns `nil`.
 
 This must be overriden for any to-many relationships (since the property type is just an array, and NSRails doesn't know what kind of object should be stored).
 
     - (Class) nestedClassForProperty:(NSString *)property
     {
		 // Only necessary for 'responses' (to-many)
		 // By default, the Author class (to-one) will be picked up through its property type
         if ([property isEqualToString:@"responses"])
             return [Response class];
         
         return [super nestedClassForProperty:property];
     }

 **Ruby**:
 
 
     # Because Ruby is not statically typed, this must be overriden for all relationships (necessary for both)
     # NSRails can't "guess" what class you want to nest in a property
 
     def nestedClassForProperty(property)
       return Response if property == "responses"
       return Author if property == "author"
     end
  
 @param property Name of the property.
 @return The class for the nested object stored in the property, or nil if it is not a nested object.
 
 @warning In Objective-C, make sure you make a call to super.
 */
- (Class) nestedClassForProperty:(NSString *)property;

/**
 Should return whether or not a nested object should be sent with its entire body (`x_attributes`), or just ID (`x_id`).
 
 The default behavior is to return `NO`. (You don't have to make a call to super here.)
 
 This is useful if you have a property whose relationship is "belongs to". Meaning, the receiving object on the server holds the foreign key - it has, say, a `parent_id`, which you want sent instead of `parent_attributes` (which would anger Rails).
 
     - (BOOL) shouldOnlySendIDKeyForNestedObjectProperty:(NSString *)property
     {
        return [property isEqualToString:"group"];
     }
 
 @param property Name of the property.
 @return YES if only the `x_id` key should be sent for this nested property, NO if the full `x_attributes` should be sent.
 */
- (BOOL) shouldOnlySendIDKeyForNestedObjectProperty:(NSString *)property;

/**
 Should return the equivalent Objective-C property for a given remote key.
 
 For example, will return `updatedAt` (the Objective-C property) for the `updated_at` key in an incoming dictionary, assuming that your class defines an `updatedAt` property.
 
 The default behavior is to autoinflect into camelCase (if [enabled](NSRConfig.html#//api/name/autoinflectsPropertyNames)), or convert `id` to `remoteID`. If the resulting conversion is not found as a property in the class, returns `nil`.
 
 Overriding example:
 
     - (NSString *) propertyForRemoteKey:(NSString *)remoteKey
     {
         //the "rails" key given from a Rails hash will be translated to the "objc" property when decoding
         if ([remoteKey isEqualToString:@"rails"])
             return @"objc";
         
         return [super propertyForRemoteKey:remoteKey];
     }

 It is possible to also override decodeRemoteValue:forRemoteKey: and setting the `objc` property manually for a remoteKey of "rails", but since `<decodeRemoteValue:forRemoteKey:>` uses this method internally, it is cleaner to just override this method.

 The inverse method remoteKeyForProperty does not exist - instead override `<encodeValueForProperty:remoteKey:>` and modify the remote key.
 
 @param remoteKey The key sent in the remote dictionary.
 @return The Objective-C property equivalent for a remote key. If your class doesn't define a property for this remote key, this should return `nil`.
 */
- (NSString *) propertyForRemoteKey:(NSString *)remoteKey;

/**
 Should return a configuration for this class and its members.
 
 The default behavior is to return <NSRConfig's> `contextuallyRelevantConfig`.
 
 @return A configuration for this class and its members.
 */
+ (NSRConfig *) config;

/// =============================================================================================
/// @name Methods to override (Ruby-specific)
/// =============================================================================================

/**
 Should return an array of all properties to be used by NSRails.
 
 Default behavior is to introspect into the class and return an array of all non-primitive type properties. This also escalates up the class hierarchy to NSRRemoteObject's properties as well (ie, `remoteID`).
 
 If you want to override this, you should add or remove objects from super:
 
     - (NSMutableArray *) remoteProperties
     {
         NSMutableArray *props = [super remoteProperties];
         
         //remove an object from NSRails entirely
         [props removeObject:@"totallyLocal"];
         
         //can even add a property not defined in your class - encodable in encodeValueForProperty:remoteKey:
         [props addObject:@"totallyRemote"];
         
         return props;
     }
 
 **Ruby**:
 
 Overriding this method, adding on all of your instance variables is necessary in RubyMotion because properties are created on runtime and Objective-C introspection won't apply.
 
     def remoteProperties
       super + ["author", "content", "created_at"]
     end
 
 @return An array of all properties to be used by NSRails.
 */
- (NSMutableArray *) remoteProperties;

/**
 Should return whether or not this property should be encoded/decoded to/from a Date object.
 
 NSRails has no idea what types your properties are in Ruby, so to benefit from automatic Date -> string and string -> Date, it needs to know what properties are dates.
 
 This is unnecessary in Objective-C.
 
     def propertyIsDate(property)
       (property == "birthday") || super
     end

 Note that `created_at` and `updated_at` are already taken care of as dates.

 @param property Name of the property.
 @return Whether or not this property should be encoded/decoded to/from a Date object.
 
 @warning Make a call to super.
 */
- (BOOL) propertyIsDate:(NSString *)property;


@end

