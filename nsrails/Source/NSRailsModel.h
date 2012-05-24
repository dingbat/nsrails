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

/**
 
 ### Summary
 
 `NSRailsModel` is the primary class in NSRails - any classes that inherit from it will be treated with a "remote correspondance" and ActiveResource-like APIs will be available.
  
 Note that you do not have to define an `id` property for your Objective-C class, as your subclass will inherit `NSRailsModel`'s `remoteID` property. Foreign keys are optional but also unnecessary (see [nesting](https://github.com/dingbat/nsrails/wiki/Nesting) on the NSRails wiki).
 
 About this document:
 
 - You'll notice that almost all `NSRailsModel` properties and methods are prefixed with `remote`, so you can quickly navigate through them with autocomplete.
 - When this document refers to an object's "model name", that means (by default) the name of its class. If you wish to define a custom model name (if the name of your model in Rails is distinct from your class name), use the `NSRUseModelName()` macro.
 - Before exploring this document, make sure that your class inherits from `NSRailsModel`, or of course these methods & properties will not be available.
 
 ### Available Macros
 
 - `NSRailsSync()` - define specific properties to be shared with Rails, along with configurable behaviors.
 - `NSRUseModelName()` - define a custom model name for your class, optionally with a custom plural. Takes string literal(s).
 - `NSRUseConfig()` - define a custom app URL for your class, optionally with username/password. Takes string literal(s).
 
 These macros can be defined right inside your subclass's implementation:
 
	@implementation Article  NSRUseModelName(@"post")
	@synthesize title, content;
	NSRailsSync(title, content)
	
	@end
 
 Please see their detailed descriptions on [the NSRails wiki](https://github.com/dingbat/nsrails/wiki/Macros).
 
 ### Validation Errors
 
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
 
 
 */


@interface NSRailsModel : NSObject <NSCoding>
{
	//used if initialized with initWithCustomSyncProperties
	NSRPropertyCollection *customProperties;
}

/// =============================================================================================
/// @name Properties
/// =============================================================================================

/**
 The corresponding local property for `id`.
 
 It should be noted that this property will be automatically updated after remoteCreate:, as will anything else that is returned from that create.
 */
@property (nonatomic, strong) NSNumber *remoteID;

/**
 The most recent dictionary of all properties returned by Rails, exactly as it returned it. (read-only)
 
 This will include properties that you may not have defined in your Objective-C class, allowing you to dynamically add fields to your app if the server-side model changes.
 
 Moreover, this will not take into account anything in NSRailsSync - it is exactly the hash as was sent by Rails.
 
 You're safe to use this property after any method that sets your object's properties from remote. For example:
	
	NSError *error;
	if ([myObj remoteFetch:&error])
	{
		NSDictionary *hashSentByRails = myObj.remoteAttributes;
		...
 
 Methods that will update `remoteAttributes` include initWithRemoteDictionary:, remoteFetch: and remoteCreate:. Objects returned with remoteObjectWithID:, and remoteAll: will also have an accurate `remoteAttributes`.
 
 */
@property (nonatomic, strong, readonly) NSDictionary *remoteAttributes;

/**
 If true, will remotely destroy this object if sent nested.
 
 If true, this object will include a `_destroy` key on send (ie, when the model nesting it is sent during a remoteUpdate: or remoteCreate:).
 
 This can be useful if you have a lot of nested models you need to destroy - you can do it in one request instead of several repeated destroys on each object.
 
 @warning Relevant for a nested object only. And, for this to work, make sure `:allow_destroy => true` [is set in your Rails model](https://github.com/dingbat/nsrails/wiki/Nesting).
 */
@property (nonatomic) BOOL remoteDestroyOnNesting;


// =============================================================================================
/// @name Class requests (Common)
// =============================================================================================

/**
 Returns an array of all remote objects (as instances of receiver's class.) Each instance’s properties will be set to those returned by Rails.
 
 Makes a GET request to `/objects` (where `objects` is the pluralization of receiver's model name.)
 
 Request done synchronously. See remoteAllAsync: for asynchronous operation.
 
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return NSArray of instances of receiver's class. Each object’s properties will be set to those returned by Rails.
 */
+ (NSArray *) remoteAll:(NSError **)error;

/**
 Retrieves an array of all remote objects (as instances of receiver's class.) Each instance’s properties will be set to those returned by Rails.
 
 Asynchronously makes a GET request to `/objects` (where `objects` is the pluralization of receiver's model name.)
  
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteAllAsync:(NSRFetchAllCompletionBlock)completionBlock;



/**
 Returns an instance of receiver's class corresponding to the remote object with that ID.
 
 Makes a GET request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is *objectID*
 
 Request done synchronously. See remoteObjectWithID:async: for asynchronous operation.
 
 @param objectID The ID of the remote object.
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return Instance of receiver's class with properties from the remote object with that ID.
 */
+ (id) remoteObjectWithID:(NSInteger)objectID error:(NSError **)error;

/**
 Retrieves an instance receiver's class corresponding to the remote object with that ID.
 
 Asynchronously makes a GET request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is *objectID*)
 
 @param objectID The ID of the remote object.
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteObjectWithID:(NSInteger)objectID async:(NSRFetchObjectCompletionBlock)completionBlock;



// =============================================================================================
/// @name Class requests (Custom)
// =============================================================================================

/**
 Returns the JSON response for a GET request to a custom method.
 
 Calls remoteRequest:method:body:error: with `GET` for *httpVerb* and `nil` for *body*.
 
 Request done synchronously. See remoteGET:async: for asynchronous operation.

 @param customRESTMethod Custom REST method to be called on the subclass's controller. If `nil`, will route to index.
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return JSON response object (could be an `NSArray` or `NSDictionary`).
 */
+ (id) remoteGET:(NSString *)customRESTMethod error:(NSError **)error;

/**
 Makes a GET request to a custom method.
 
 Calls remoteRequest:method:body:async: with `GET` for *httpVerb* and `nil` for *body*.
 
 @param customRESTMethod Custom REST method to be called on the subclass's controller. If `nil`, will route to index.
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteGET:(NSString *)customRESTMethod async:(NSRHTTPCompletionBlock)completionBlock;



/**
 Returns the JSON response for a request with a custom method, sending an `NSRailsModel` subclass instance as the body.

 Calls remoteRequest:method:body:error: with `obj`'s remote dictionary representation for *body*.

 Request done synchronously. See remoteRequest:method:bodyAsObject:async: for asynchronous operation.
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param customRESTMethod Custom REST method to be called on the subclass's controller. If `nil`, will route to index.
 @param obj NSRailsModel subclass instance - object you want to send in the body.
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return JSON response object (could be an `NSArray` or `NSDictionary`).
 */
+ (id) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod bodyAsObject:(NSRailsModel *)obj error:(NSError **)error;

/**
 Makes a request with a custom method, sending an `NSRailsModel` subclass instance as the body.
 
 Calls remoteRequest:method:body:error: with `obj`'s remote dictionary representation for *body*.
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param customRESTMethod Custom REST method to be called on the subclass's controller. If `nil`, will route to index.
 @param obj NSRailsModel subclass instance - object you want to send in the body.
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod bodyAsObject:(NSRailsModel *)obj async:(NSRHTTPCompletionBlock)completionBlock;


/**
 Returns the JSON response for a request with a custom method.
 
 If called on a subclass, makes the request to `/objects/method` (where `objects` is the pluralization of receiver's model name, and `method` is *customRESTMethod*).
 
 If called on `NSRailsModel`, makes the request to `/method` (where `method` is *customRESTMethod*).
 
 `/method` is omitted if `customRESTMethod` is nil.
 
	 [Article remoteRequest:@"POST" method:nil body:json error:&e];           ==> POST /articles
	 [Article remoteRequest:@"POST" method:@"register" body:json error:&e];   ==> POST /articles/register
	 [NSRailsModel remoteGET:@"root" error:&e];                               ==> GET /root
 
 Request made synchronously. See remoteRequest:method:body:async: for asynchronous operation.
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param customRESTMethod The REST method to call (appended to the route). If `nil`, will call index. See above for examples.
 @param body Request body (needs to be a JSON parsable object, or will throw exception (NSDictionary, NSArray)).
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return JSON response object (could be an `NSArray` or `NSDictionary`).
 */
+ (id) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(id)body error:(NSError **)error;

/**
 Makes a request with a custom method.
 
 If called on a subclass, makes the request to `/objects/method` (where `objects` is the pluralization of receiver's model name, and `method` is *customRESTMethod*).
 
 If called on `NSRailsModel`, makes the request to `/method` (where `method` is *customRESTMethod*).
 
 `/method` is omitted if `customRESTMethod` is nil.
 
	 [Article remoteRequest:@"POST" method:nil body:json async:block];           ==> POST /articles
	 [Article remoteRequest:@"POST" method:@"register" body:json async:block];   ==> POST /articles/register
	 [NSRailsModel remoteRequest:@"GET" method:@"root" body:nil async:block];    ==> GET /root
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param customRESTMethod The REST method to call (appended to the route). If `nil`, will call index. See above for examples.
 @param body Request body (needs to be a JSON parsable object, or will throw exception (NSDictionary, NSArray)).
 @param completionBlock Block to be executed when the request is complete.
 */
+ (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(id)body async:(NSRHTTPCompletionBlock)completionBlock;

/// =============================================================================================
/// @name Instance requests (CRUD)
/// =============================================================================================

/**
 Retrieves the latest remote data for receiver and sets its properties to received response.
 
 Sends a `GET` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
 Request made synchronously. See remoteFetchAsync: for asynchronous operation.
 
 Requires presence of `remoteID`, or will throw an `NSRNullRemoteIDException`.
 
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`. 
 @return `YES` if fetch was successful. Returns `NO` if an error occurred.
 
 @see remoteFetch:changes:
 */
- (BOOL) remoteFetch:(NSError **)error;

/**
 Retrieves the latest remote data for receiver and sets its properties to received response.
 
 Sends a `GET` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
 Request made synchronously. See remoteFetchAsync: for asynchronous operation.
 
 Requires presence of `remoteID`, or will throw an `NSRNullRemoteIDException`.
 
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`. 
 @param changesPtr Pointer to boolean value set to whether or not the receiver changed in any way after the fetch (ie, if this fetch modified one of receiver's local properties due to a change in value server-side). This will also take into account diffs to any nested `NSRailsModel` objects that are affected by this fetch (done recursively).
 
 Note that because this only tracks differences in local changes, properties that changed server-side that are not defined in the receiver's class will *not* report back a change (ie, if receiver's class doesn't implement an `updated_at` property and `updated_at` is changed in your remote DB, no change will be reported.) This parameter may be `NULL` if this information is not useful, or use remoteFetch:.
 @return `YES` if fetch was successful. Returns `NO` if an error occurred.
 
 @see remoteFetch:
 */
- (BOOL) remoteFetch:(NSError **)error changes:(BOOL *)changesPtr;


/**
 Retrieves the latest remote data for receiver and sets its properties to received response.
 
 Asynchronously sends a `GET` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
 
 Requires presence of `remoteID`, or will throw an `NSRNullRemoteIDException`.

 @param completionBlock Block to be executed when the request is complete. The second parameter passed in is a BOOL whether or not there was a *local* change. This means changes in `updated_at`, etc, will only apply if your Objective-C class implement this as a property as well. This also applies when updating any of its nested objects (done recursively).
 */
- (void) remoteFetchAsync:(NSRFetchCompletionBlock)completionBlock;


/**
 Updates receiver's corresponding remote object.
 
 Sends an `UPDATE` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
 Request made synchronously. See remoteUpdateAsync: for asynchronous operation.

 Requires presence of `remoteID`, or will throw an `NSRNullRemoteIDException`.
 
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return `YES` if update was successful. Returns `NO` if an error occurred.

 @warning No local properties will be set, as Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (BOOL) remoteUpdate:(NSError **)error;

/**
 Updates receiver's corresponding remote object.
 
 Asynchronously sends an `UPDATE` request to `/objects/1` (where `objects` is the pluralization of receiver's model name, and `1` is the receiver's `remoteID`).
 
 Requires presence of `remoteID`, or will throw an `NSRNullRemoteIDException`.
 
 @param completionBlock Block to be executed when the request is complete.
 
 @warning No local properties will be set, as Rails does not return anything for this action. This means that if you update an object with the creation of new nested objects, those nested objects will not locally update with their respective IDs.
 */
- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock;


/**
 Creates the receiver remotely. Receiver's properties will be set to those given by Rails (including `remoteID`).
 
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
 Request made synchronously. See remoteDestroyAsync: for asynchronous operation.
 
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


/// =============================================================================================
/// @name Instance requests (Custom)
/// =============================================================================================

/**
 Returns the JSON response for a GET request to a custom method.
 
 Calls remoteRequest:method:body:error: with `GET` for *httpVerb* and `nil` for *body*.
 
 Request done synchronously. See remoteGET:async: for asynchronous operation.
 
 @param customRESTMethod Custom REST method to be called on the remote object corresponding to the receiver. If `nil`, will route to only the receiver (objects/1).
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return JSON response object (could be an `NSArray` or `NSDictionary`).
 */
- (id) remoteGET:(NSString *)customRESTMethod error:(NSError **)error;

/**
 Makes a GET request to a custom method.
 
 Calls remoteRequest:method:body:async: with `GET` for *httpVerb* and `nil` for *body*.
 
 @param customRESTMethod Custom REST method to be called on the remote object corresponding to the receiver. If `nil`, will route to only the receiver (objects/1).
 @param completionBlock Block to be executed when the request is complete.
 */
- (void) remoteGET:(NSString *)customRESTMethod async:(NSRHTTPCompletionBlock)completionBlock;


/**
 Returns the JSON response for a request with a custom method, sending the JSON representation of the receiver as the request body.
 
 Calls remoteRequest:method:body:error: with `obj`'s remote dictionary representation for *body*.
 
 Request done synchronously. See remoteRequest:method:bodyAsObject:async: for asynchronous operation.
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param customRESTMethod Custom REST method to be called on the remote object corresponding to the receiver. If `nil`, will route to only the receiver (objects/1).
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return JSON response object (could be an `NSArray` or `NSDictionary`).
 */
- (id) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod error:(NSError **)error;

/**
 Makes a request with a custom method, sending the JSON representation of the receiver as the request body.
 
 Calls remoteRequest:method:body:async: with receiver's remote dictionary representation for *body*.
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param customRESTMethod Custom REST method to be called on the remote object corresponding to the receiver. If `nil`, will route to only the receiver (objects/1).
 @param completionBlock Block to be executed when the request is complete.
 */
- (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod async:(NSRHTTPCompletionBlock)completionBlock;


/**
 Returns the JSON response for a request with a custom method on the receiver's corresponding remote object.
 
 Makes a request to `/objects/1/method` (where `objects` is the pluralization of receiver's model name, `1` is the receiver's `remoteID`, and `method` is *customRESTMethod*).
  
 `/method` is omitted if `customRESTMethod` is nil.
 
	[myArticle remoteRequest:@"PUT" method:nil body:json error:&e];           ==> PUT /articles/1
	[myArticle remoteRequest:@"PUT" method:@"register" body:json error:&e];   ==> PUT /articles/1/register
 
 Request made synchronously. See remoteRequest:method:body:async: for asynchronous operation.
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param customRESTMethod The REST method to call (appended to the route). If `nil`, will call index. See above for examples.
 @param body Request body (needs to be a JSON parsable object, or will throw exception (NSDictionary, NSArray)).
 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return JSON response object (could be an `NSArray` or `NSDictionary`).
 */
- (id) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(id)body error:(NSError **)error;

/**
 Makes a request with a custom method on the receiver's corresponding remote object.
 
 Asynchronously akes a request to `/objects/1/method` (where `objects` is the pluralization of receiver's model name, `1` is the receiver's `remoteID`, and `method` is *customRESTMethod*).
  
 `/method` is omitted if `customRESTMethod` is nil.
 
	[myArticle remoteRequest:@"PUT" method:nil body:json error:&e];           ==> PUT /articles/1
	[myArticle remoteRequest:@"PUT" method:@"register" body:json error:&e];   ==> PUT /articles/1/register
 
 @param httpVerb The HTTP method to use (`GET`, `POST`, `PUT`, `DELETE`, etc.)
 @param customRESTMethod The REST method to call (appended to the route). If `nil`, will call index. See above for examples.
 @param body Request body (needs to be a JSON parsable object, or will throw exception (NSDictionary, NSArray)).
 @param completionBlock Block to be executed when the request is complete.
 */
- (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(id)body async:(NSRHTTPCompletionBlock)completionBlock;



/// =============================================================================================
/// @name Setting and retrieving JSON representations
/// =============================================================================================


/**
 Serializes the receiver's properties into a dictionary.
  
 @param wrapped If `YES`, wraps the dictionary with a key of the model name:
 
	{"user"=>{"name"=>"x", "email"=>"y"}}
 
 @return The receiver's properties as a dictionary (takes into account rules in NSRailsSync).
 */
- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped;

/**
 Sets the receiver's properties given a dictionary.
 
 Takes into account rules in NSRailsSync.
 
 @param dictionary Dictionary to be evaluated. 
 @return YES if any changes were made to the local object, NO if object was identical before/after.
 */
- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dictionary;

/// =============================================================================================
/// @name Initializers
/// =============================================================================================


/**
 Initializes a new instance of the receiver's class with a given dictionary input.
 
 Takes into account rules in NSRailsSync.
 
 @param dictionary Dictionary to be evaluated. 
 @return YES if any changes were made to the local object, NO if object was identical before/after.
 */
- (id) initWithRemoteDictionary:(NSDictionary *)dictionary;

/**
 Initializes a new instance of the receiver's class with a custom NSRailsSync string.
 
 The given NSRailsSync string will be used only for this **instance**. This instance will not use its class's NSRailsSync. This is very uncommon and triple checking is recommended before going with this implementation strategy.
 
 Pass in a string as you would type it into NSRailsSync():
	Person *zombie = [[Person alloc] initWithCustomSyncProperties:@"*, brain -x"];

 
 @param str String to become this instance's NSRailsSync - pass as you would an NSRailsSync string (see above). 
 @return YES if any changes were made to the local object, NO if object was identical before/after.
 */
- (id) initWithCustomSyncProperties:(NSString *)str;

/**
 Initializes a new instance of the receiver's class with a custom NSRailsSync string and config.
 
 The given NSRailsSync string and config will be used only for this **instance**. This instance will not use its class's NSRailsSync or NSRUseConfig or any default configs (although any config in a context block (with use or useIn) will take precedence). This is very uncommon and triple checking is recommended before going with this implementation strategy.
 
 Pass in a string as you would type it into NSRailsSync():
	Person *zombie = [[Person alloc] initWithCustomSyncProperties:@"*, brain -x" customConfig:nonInflectingConfig];
 
 @param str String to become this instance's NSRailsSync - pass as you would an NSRailsSync string (see above).  
 @param config Config to become this instance's config. 
 @return YES if any changes were made to the local object, NO if object was identical before/after.
 */
- (id) initWithCustomSyncProperties:(NSString *)str customConfig:(NSRConfig *)config;


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


//adding a # before va_args will simply make its contents a cstring
#define _MAKE_STR(...)	[NSString stringWithCString:(#__VA_ARGS__) encoding:NSUTF8StringEncoding]


/// =============================================================================================
#pragma mark NSRailsSync
/// =============================================================================================

//define NSRailsSync to create a method called NSRailsSync, which returns the entire param list
#define NSRailsSync(...) \
+ (NSString*) NSRailsSync { return _MAKE_STR(__VA_ARGS__); }

//define NSRNoCarryFromSuper as NSRNoCarryFromSuper - not a string, since it's placed directly in the macro
#define NSRNoCarryFromSuper			NSRNoCarryFromSuper

//returns the string version of NSRNoCarryFromSuper so we can find it when evaluating NSRailsSync string
#define _NSRNoCarryFromSuper_STR	_MAKE_STR(NSRNoCarryFromSuper)


/// =============================================================================================
#pragma mark NSRUseModelName
/// =============================================================================================

//define NSRUseModelName to concat either _NSR_Name1(x) or _NSR_Name2(x,y), depending on the number of args passed in
#define NSRUseModelName(...) _CAT(_NSR_Name,_N_ARGS(__VA_ARGS__))(__VA_ARGS__)

//using default is the same thing as passing nil for both model name + plural name
#define NSRUseDefaultModelName _NSR_Name2(nil,nil)

//_NSR_Name1 (only with 1 parameter, ie, custom model name but default plurality), creates NSRUseModelName method that returns param, return nil for plural to make it go to default
#define _NSR_Name1(name)	_NSR_Name2(name, nil)

//_NSR_Name2 (2 parameters, ie, custom model name and custom plurality), creates NSRUseModelName and NSRUsePluralName
#define _NSR_Name2(name,plural)  \
+ (NSString*) NSRUseModelName { return name; } \
+ (NSString*) NSRUsePluralName { return plural; }


/// =============================================================================================
#pragma mark NSRUseConfig
/// =============================================================================================

//works the same way as NSRUseModelName

#define NSRUseConfig(...) _CAT(_NSR_Config,_N_ARGS(__VA_ARGS__))(__VA_ARGS__)

#define NSRUseDefaultConfig	_NSR_Config3(nil, nil, nil)

#define _NSR_Config1(url)	_NSR_Config3(url, nil, nil)

#define _NSR_Config3(url,user,pass)  \
+ (NSString *) NSRUseConfigURL { return url; } \
+ (NSString *) NSRUseConfigUsername { return user; } \
+ (NSString *) NSRUseConfigPassword { return pass; }

