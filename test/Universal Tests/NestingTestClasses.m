//
//  NestingTestClasses.m
//  NSRails
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NestingTestClasses.h"

@implementation Post
@synthesize author, content, responses;
NSRailsSync(*, responses:NSRResponse)

@end

@implementation NSRResponse
@synthesize post, content, author;
NSRailsSync(*)

@end

@implementation BadResponse
@synthesize post, content, author;
NSRailsSync(*)

@end
