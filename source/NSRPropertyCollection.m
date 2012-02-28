//
//  NSRPropertyCollection.m
//  NSRails
//
//  Created by Dan Hassin on 2/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRPropertyCollection.h"

@implementation NSRPropertyCollection
@synthesize sendableProperties, retrievableProperties, encodeProperties, decodeProperties;
@synthesize nestedModelProperties, propertyEquivalents, class=_class;

+ (NSRPropertyCollection *) collectionForClass:(Class)c
{
	NSRPropertyCollection *collection = [[NSRPropertyCollection alloc] init];
}


@end
