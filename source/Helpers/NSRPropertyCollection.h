//
//  NSRPropertyCollection.h
//  NSRails
//
//  Created by Dan Hassin on 2/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//


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
