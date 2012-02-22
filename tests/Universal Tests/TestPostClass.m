//
//  TestPostClass.m
//  NSRails
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "TestPostClass.h"

@implementation TestPostClass
@synthesize author, body;
NSRailsSync(*)
NSRailsUseModelName(@"post")

@end
