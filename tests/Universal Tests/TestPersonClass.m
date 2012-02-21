//
//  TestPersonClass.m
//  NSRails
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "TestPersonClass.h"

@implementation TestPersonClass
@synthesize name, age;
NSRailsSync(*)
NSRailsUseModelName(@"person")

@end
