/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSMutableArray+NSRails.h
 
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

@class NSRRemoteObject;

@interface NSMutableArray (NSRFetch)

/**
 Updates elements in this array using index of remote objects.
 
 Makes a GET request to `/objects` (where `objects` is the pluralization of *class*'s model name.)
 If viaObject is specified, will nest resource request (ex. GET to `/parents/3/objects`)
 
 Request done synchronously. See remoteFetchAll:async: for asynchronous operation.
 
 @param class Class with which to build instances to insert into this array. Raises an exception if this class does not subclass NSRRemoteObject.
 @param viaObject Remote object by which to request the collection from, establishes pattern for resources depending on nesting
 @param errorPtr Out parameter used if an error occurs while processing the request. May be `NULL`.
 @param changesPtr Reference to a BOOL. Will indicate whether or not there were local changes to the array after this operation. Returns `YES` if no elements were added or deleted, and if no element changed when updating its respective properties.
 
 Works in a very similar way to remoteFetch: in NSRRemoteObject.
 @return `YES` if fetch was successful. Returns `NO` if an error occurred.
 */
- (BOOL) remoteFetchAll:(Class)class error:(NSError **)errorPtr changes:(BOOL *)changesPtr;
- (BOOL) remoteFetchAll:(Class)class viaObject:(NSRRemoteObject *)obj error:(NSError **)errorPtr changes:(BOOL *)changesPtr;


/**
 Updates elements in this array using index of remote objects.
 
 Makes a GET request to `/objects` (where `objects` is the pluralization of *class*'s model name.)
 If viaObject is specified, will nest resource request (ex. GET to `/parents/3/objects`)
  
 @param class Class with which to build instances to insert into this array. Raises an exception if this class does not subclass NSRRemoteObject.
 @param viaObject Remote object by which to request the collection from, establishes pattern for resources depending on nesting
 @param completionBlock Block to be executed on completion..
 */
- (void) remoteFetchAll:(Class)class async:(NSRFetchCompletionBlock)completionBlock;
- (void) remoteFetchAll:(Class)class viaObject:(NSRRemoteObject *)obj async:(NSRFetchCompletionBlock)completionBlock;


/**
 Replaces each dictionary in this array with an instance of the given class, setting respective properties to those defined in that dictionary (using the class's NSRMap).
 
 This method can be useful when interpreting a retrieved array (representation of your server's JSON out) from a remoteGET method or similar.
 
 @param class Class with which to build instances to replace this array's dictionaries. Raises an exception if this class does not subclass NSRRemoteObject.
 */
- (void) translateRemoteDictionariesIntoInstancesOfClass:(Class)class;

@end
