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

@class NSRRemoteObject;
@class NSRConfig;

@interface NSRRequest : NSObject

@property (nonatomic, strong) NSRConfig *config;
@property (nonatomic, strong) NSString *route;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) id body;

+ (NSRRequest *) requestWithRoute:(NSString *)str;
+ (NSRRequest *) requestWithHTTPMethod:(NSString *)method;

+ (NSRRequest *) requestToFetchObjectWithID:(NSNumber *)rID ofClass:(Class)c;
+ (NSRRequest *) requestToFetchAllObjectsOfClass:(Class)c;

+ (NSRRequest *) requestToCreateObject:(NSRRemoteObject *)obj;
+ (NSRRequest *) requestToFetchObject:(NSRRemoteObject *)obj;
+ (NSRRequest *) requestToDestroyObject:(NSRRemoteObject *)obj;
+ (NSRRequest *) requestToUpdateObject:(NSRRemoteObject *)obj;
+ (NSRRequest *) requestToReplaceObject:(NSRRemoteObject *)obj;

//These return self so that they can be used chained in one line:
//[[[NSRRequest requestWithHTTPMethod:@"GET"] routeToClass:[Post class]] sendSynchronous:&e];

- (NSRRequest *) routeToClass:(Class)c;
- (NSRRequest *) routeToObject:(NSRRemoteObject *)o;

- (NSRRequest *) routeToClass:(Class)c withCustomMethod:(NSString *)optionalRESTMethod;
- (NSRRequest *) routeToObject:(NSRRemoteObject *)o withCustomMethod:(NSString *)optionalRESTMethod;

- (void) setBodyToObject:(NSRRemoteObject *)obj;

- (id) sendSynchronous:(NSError **)e;
- (void) sendAsynchronous:(NSRHTTPCompletionBlock)block;

@end
