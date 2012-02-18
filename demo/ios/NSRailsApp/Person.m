//
//  Person.m
//  NSRailsApp
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "Person.h"

@implementation Person
@synthesize name, age, brain;
NSRailsSync(name, age, brain)

@end