//
//  NestingTestClasses.m
//  NSRails
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NestingTestClasses.h"

@implementation Post
@synthesize author, body, responses;
NSRailsSync(*, responses:Response)

@end

@implementation Response
@synthesize post, body, author;
NSRailsSync(*)

@end

@implementation BadResponse
@synthesize post, body, author;
NSRailsSync(*)

@end
