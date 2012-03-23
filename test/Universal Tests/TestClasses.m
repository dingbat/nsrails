//
//  TestClasses.m
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "TestClasses.h"

@implementation TestClassParent

@end


@implementation TestClass
@synthesize primitiveAttr, myID, attr1, attr2, array;
@synthesize retrieve, send, local, decode, encode, parent, badRetrieve;

- (NSString *) encodeEncode
{
	return [encode uppercaseString];
}

- (NSString *) decodeDecode:(NSString *)_decode
{
	return [_decode lowercaseString];
}

@end