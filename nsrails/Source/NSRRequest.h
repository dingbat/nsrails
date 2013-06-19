/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRRequest.h
 
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

@class NSRRemoteObject;
@class NSRConfig;

/**
 NSRRequest is a class used internally by NSRRemoteObject to make `remoteX` requests, but can also be used directly to construct custom resource paths, etc.
 
 The methods in this class are set up so that making requests is concise and visually logical:
 
	//GET to /posts/1
	id response = [[[NSRRequest GET] routeToObject:post] sendSynchronous:&e];
  
	//PATCH to /posts/1 with post as body
	NSRRequest *request = [NSRRequest PATCH];
	[request routeToObject:post];
	[request setBodyToObject:post];
	id response = [request sendSynchronous:&e];
 
 Factory methods also exist (used by NSRRemoteObject) if you'd like to make only an incremental change to an existing request:
 
	NSRRequest *request = [NSRRequest requestToFetchAllObjectsOfClass:[Post class]];
	request.queryParameters = @{@"q":@"search"};

	//GET to /posts?q=search
	id response = [request sendSynchronous:&e];
*/

@interface NSRRequest : NSObject <NSCoding>

/// =============================================================================================
/// @name Properties
/// =============================================================================================

/**
 Config used to make the request.
 
 This property is automatically set when a `routeTo` method is invoked (will set it to the config of the class/instance).
 
 Will use <NSRConfig>'s `defaultConfig` by default (ie, is not routed to an object or class).
 
 When this request is made, any [additionalHTTPHeaders](NSRConfig.html#//api/name/additionalHTTPHeaders) defined for this config are added to the request header (along with this instance's own <additionalHTTPHeaders>).
 */
@property (nonatomic, strong) NSRConfig *config;

/**
 The path to be appended to config's [appURL](NSRConfig.html#//api/name/appURL) (the base URL of your app).
 
 You cannot set this variable directly - use the `routeTo` methods below.
 */
@property (nonatomic, readonly) NSString *route;

/**
 The HTTP verb with which to make the request.
 
 This property is readonly. Use the <GET>, <DELETE>, <POST>, <PUT>, and <PATCH> factory methods.
 */
@property (nonatomic, readonly) NSString *httpMethod;

/**
 The query parameters with which to make the request.
 
	 NSRRequest *request = [[NSRRequest GET] routeTo:@"something"];
	 request.queryParameters = @{@"q":@"search"};
	 
	 //GET to /something?q=search
	 id response = [request sendSynchronous:&e];
 
 @warning Doesn't escape anything! Make sure your params are RFC 1808 compliant.
 */
@property (nonatomic, strong) NSDictionary *queryParameters;

/**
 A dictionary of additional HTTP headers to send with the request.
  */
@property (nonatomic, strong) NSDictionary *additionalHTTPHeaders;

/**
 Request body.
 
 Must be a JSON-parsable object (NSArray, NSDictionary, NSString) or will throw an exception.
 */
@property (nonatomic, strong) id body;


/// =============================================================================================
/// @name Creating an NSRRequest by HTTP method
/// =============================================================================================

/**
 Creates and returns an NSRRequest object initialized with `<httpMethod>` set to `@"GET"`.
 
 @return An NSRRequest object initialized with `<httpMethod>` set to `@"GET"`.
 */
+ (NSRRequest *) GET;

/**
 Creates and returns an NSRRequest object initialized with `<httpMethod>` set to `@"DELETE"`.
 
 @return An NSRRequest object initialized with `<httpMethod>` set to `@"DELETE"`.
 */
+ (NSRRequest *) DELETE;

/**
 Creates and returns an NSRRequest object initialized with `<httpMethod>` set to `@"POST"`.
 
 @return An NSRRequest object initialized with `<httpMethod>` set to `@"POST"`.
 */
+ (NSRRequest *) POST;

/**
 Creates and returns an NSRRequest object initialized with `<httpMethod>` set to `@"PUT"`.
 
 @return An NSRRequest object initialized with `<httpMethod>` set to `@"PUT"`.
 */
+ (NSRRequest *) PUT;

/**
 Creates and returns an NSRRequest object initialized with `<httpMethod>` set to `@"PATCH"`.
 
 @return An NSRRequest object initialized with `<httpMethod>` set to `@"PATCH"`.
 */
+ (NSRRequest *) PATCH;


/// =============================================================================================
/// @name Creating an NSRRequest by function
/// =============================================================================================

/**
 Creates and returns an NSRRequest object set to fetch an object with a specified ID.
 
 `GET` request routed to the given class, the custom method being the remoteID.
 
	GET /posts/1
 
 @param remoteID Remote ID of the object you wish to fetch. Will raise an exception if this is `nil`.
 @param class Class of the object you wish to fetch. Must be an NSRRemoteObject subclass.
 @return An NSRRequest object set to fetch an object with a specified ID.
 */
+ (NSRRequest *) requestToFetchObjectWithID:(NSNumber *)remoteID ofClass:(Class)class;

/**
 Creates and returns an NSRRequest object set to fetch all objects of a given class.
 
 `GET` request routed to the given class.
 
	GET /posts
 
 @param class Class of the object you wish to fetch. Must be an NSRRemoteObject subclass.
 @return An NSRRequest object set to fetch all objects of a given class.
 */
+ (NSRRequest *) requestToFetchAllObjectsOfClass:(Class)class;

/**
 Creates and returns an NSRRequest object set to fetch all objects of a given class given a parent object.
 
 `GET` request routed to the given parent object, the custom method being the class's index page.
 
	GET /users/3/posts
 
 @param class Class of the object you wish to fetch. Must be an NSRRemoteObject subclass.
 @param obj Parent object used to prefix the route.
 @return An NSRRequest object set to fetch all objects of a given class given a parent object.
 */
+ (NSRRequest *) requestToFetchAllObjectsOfClass:(Class)class viaObject:(NSRRemoteObject *)obj;

/**
 Creates and returns an NSRRequest object set to remotely create a given object.
 
 `POST` request routed to the given object (ID is ignored).
 
	POST /posts
 
 Or, if <NSRRemoteObject>'s `objectUsedToPrefixRequest:` is overriden and returns a non-nil object,
 
	POST /users/3/posts
 
 @param obj Object you wish to create.
 @return An NSRRequest object set to remotely create a given object.
 */
+ (NSRRequest *) requestToCreateObject:(NSRRemoteObject *)obj;

/**
 Creates and returns an NSRRequest object set to fetch a given object's remote correspondance.
 
 `GET` request routed to the given object.
 
	GET /posts/1
 
 Or, if <NSRRemoteObject>'s `objectUsedToPrefixRequest:` is overriden and returns a non-nil object,
 
	GET /users/3/posts/1
 
 @param obj Object you wish to fetch.
 @return An NSRRequest object set to fetch a given object's remote correspondance.
 */
+ (NSRRequest *) requestToFetchObject:(NSRRemoteObject *)obj;

/**
 Creates and returns an NSRRequest object set to remotely destroy a given object.
 
 `DELETE` request routed to the given object.
 
	DELETE /posts/1
 
 Or, if <NSRRemoteObject>'s `objectUsedToPrefixRequest:` is overriden and returns a non-nil object,
 
	DELETE /users/3/posts/1
 
 @param obj Object you wish to fetch.
 @return An NSRRequest object set to destroy a given object's remote correspondance.
 */
+ (NSRRequest *) requestToDestroyObject:(NSRRemoteObject *)obj;

/**
 Creates and returns an NSRRequest object set to remotely update a given object.
 
 Request routed to the given object. HTTP method depends on config's [`updateMethod`](NSRConfig.html#//api/name/updateMethod).
 
	(PUT, PATCH, etc) /posts/1
 
 Or, if <NSRRemoteObject>'s `objectUsedToPrefixRequest:` is overriden and returns a non-nil object,
 
	(PUT, PATCH, etc) /users/3/posts/1
 
 @param obj Object you wish to update.
 @return An NSRRequest object set to remotely update a given object.
 */
+ (NSRRequest *) requestToUpdateObject:(NSRRemoteObject *)obj;

/**
 Creates and returns an NSRRequest object set to remotely "put" (replace) a given object.
 
 `PUT` request routed to the given object.
 
	PUT /posts/1
 
 Or, if <NSRRemoteObject>'s `objectUsedToPrefixRequest:` is overriden and returns a non-nil object,
 
	PUT /users/3/posts/1
 
 @param obj Object you wish to update.
 @return An NSRRequest object set to remotely "put" (replace) a given object.
 */
+ (NSRRequest *) requestToReplaceObject:(NSRRemoteObject *)obj;

/// =============================================================================================
/// @name Routing a request
/// =============================================================================================

/**
 Routes the request to the given string.
 
 @param route The route.
 */
- (NSRRequest *) routeTo:(NSString *)route;

/**
 Routes the request to a given class's controller.
 
 @param class Class to which to route. Must be an NSRRemoteObject subclass.
 */
- (NSRRequest *) routeToClass:(Class)class;

/**
 Routes the request to a given object.
 
 @param object Object to route to. If this object's `remoteID` is `nil`, will only route to its class.
 */
- (NSRRequest *) routeToObject:(NSRRemoteObject *)object;

/**
 Routes the request to a given class's controller.
 
 @param class Class to route to. Must be an NSRRemoteObject subclass.
 @param customMethod Custom method to be appended to the *class*'s controller RESTfully (can be `nil`.)
 */
- (NSRRequest *) routeToClass:(Class)class withCustomMethod:(NSString *)customMethod;

/**
 Routes the request to a given object.
 
 @param object Object to route to. If this object's `remoteID` is `nil`, will only route to its class.
 @param customMethod Custom method to be appended RESTfully (can be `nil`.)
 
 @return The request itself. Done to allow concise constructions (see [above](#overview)).
 */
- (NSRRequest *) routeToObject:(NSRRemoteObject *)object withCustomMethod:(NSString *)customMethod;

/// =============================================================================================
/// @name Setting the request body
/// =============================================================================================

/**
 Sets the body to a given object.
 
 Will convert the object into a JSON-parsable object (an NSDictionary) by calling <NSRRemoteObject>'s `remoteDictionaryRepresentationWrapped:` on it.
 
 @param object Object to use as a body to send the request.
 */
- (void) setBodyToObject:(NSRRemoteObject *)object;

/// =============================================================================================
/// @name Sending the request
/// =============================================================================================

/**
 Sends the request synchronously.

 Handles Rails errors, as well as basic connection errors.

 @param error Out parameter used if an error occurs while processing the request. May be `NULL`.
 @return JSON response object (could be an `NSArray` or `NSDictionary`).
 */
- (id) sendSynchronous:(NSError **)error;

/**
 Sends the request asynchronously.

 Handles Rails errors, as well as basic connection errors.
 
 @param completionBlock Block to be executed when the request is complete.
 */
- (void) sendAsynchronous:(NSRHTTPCompletionBlock)completionBlock;

@end
