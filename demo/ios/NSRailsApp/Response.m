//
//  Response.m
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "Response.h"

@implementation Response
@synthesize body, author, post;
NSRailsSync(*, post -b)

@end