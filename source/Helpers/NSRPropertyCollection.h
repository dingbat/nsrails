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

@interface NSRPropertyCollection : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableArray *sendableProperties;
@property (nonatomic, strong) NSMutableArray *retrievableProperties;
@property (nonatomic, strong) NSMutableArray *encodeProperties;
@property (nonatomic, strong) NSMutableArray *decodeProperties;
@property (nonatomic, strong) NSMutableDictionary *nestedModelProperties;
@property (nonatomic, strong) NSMutableDictionary *propertyEquivalents;

- (NSString *) equivalenceForProperty:(NSString *)objcProperty;
- (BOOL) propertyIsMarkedBelongsTo:(NSString *)prop;

- (id) initWithClass:(Class)c;
- (id) initWithClass:(Class)c properties:(NSString *)str;

@end
