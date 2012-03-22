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
@synthesize primitiveAttr, myID, attr1, attr2;
@synthesize retrieve, send, local, decode, encode, parent, badRetrieve;
NSRailsSync(primitiveAttr, remoteID -x, myID=id, nonexistent, //test linebreak
			attr1=hello, attr2=hello, badRetrieve)

- (NSString *) encodeEncode
{
	return [encode uppercaseString];
}

- (NSString *) decodeDecode:(NSString *)_decode
{
	return [_decode lowercaseString];
}

@end