//
//  NSRPropertyCollection.h
//  NSRails
//
//  Created by Dan Hassin on 2/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSRPropertyCollection : NSObject

@property (nonatomic, strong) NSMutableArray *sendableProperties;
@property (nonatomic, strong) NSMutableArray *retrievableProperties;
@property (nonatomic, strong) NSMutableArray *encodeProperties;
@property (nonatomic, strong) NSMutableArray *decodeProperties;
@property (nonatomic, strong) NSMutableDictionary *nestedModelProperties;
@property (nonatomic, strong) NSMutableDictionary *propertyEquivalents;
@property (nonatomic, assign) Class class;

+ (NSRPropertyCollection *) collectionForClass:(Class)c;

@end
