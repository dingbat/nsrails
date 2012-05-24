/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRPropertyCollection.h
 
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

//Note:
//This class doesn't really have use outside of NSRails's internals.
//There's not much to do here.

#import <Foundation/Foundation.h>
#import "NSRConfig.h"

@interface NSRProperty : NSObject <NSCoding>

@property (nonatomic, getter = isSendable) BOOL sendable;
@property (nonatomic, getter = isRetrievable) BOOL retrievable;
@property (nonatomic, getter = isEncodable) BOOL encodable;
@property (nonatomic, getter = isDecodable) BOOL decodable;
@property (nonatomic, getter = isArray) BOOL array;
@property (nonatomic, getter = isBelongsTo) BOOL belongsTo;
@property (nonatomic, getter = isDate) BOOL date;
@property (nonatomic) BOOL includedOnNesting;
@property (nonatomic, strong) NSString *nestedClass, *remoteEquivalent;
@property (nonatomic, strong) NSString *name;

- (BOOL) isHasMany;

@end


@interface NSRPropertyCollection : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableDictionary *properties;
@property (nonatomic, strong) NSRConfig *customConfig;

- (NSArray *) objcPropertiesForRemoteEquivalent:(NSString *)remoteProperty autoinflect:(BOOL)autoinflect;

- (id) initWithClass:(Class)c syncString:(NSString *)str customConfig:(NSRConfig *)config;

@end

