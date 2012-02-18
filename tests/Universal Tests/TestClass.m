//
//  TestClass.m
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "TestClass.h"

@implementation TestClass
@synthesize primitiveAttr, myID, attr1, attr2;
NSRailsSync(primitiveAttr, modelID -x, myID=id, nonexistent, attr1=hello, attr2=hello)

@end