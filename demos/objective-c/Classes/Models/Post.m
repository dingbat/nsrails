//
//  Post.m
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "Post.h"

@implementation Post
@synthesize content, author, createdAt, responses;
NSRMap(content, author, createdAt, responses:Response)

// The NSRMap above will tell NSRails to sync up content, author, and responses w/Rails
// Could also be done like:
//	 NSRMap(*, responses:Response)

// For responses, since it's an array, the ":" is required to define an association with another class.
// In this case, the class of objects we want to fill our responses array with is Response (must be an NSRRemoteObject subclass)

@end