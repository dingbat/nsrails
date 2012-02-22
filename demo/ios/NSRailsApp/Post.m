//
//  Post.m
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "Post.h"

@implementation Post
@synthesize body, author, responses;
NSRailsSync(body, author, responses:Response)

@end