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

// Sync up body, author, and responses
//                             ---For responses, since it's an array, the ":" is required to define an association with another class.
//									In this case, the class of objects we want to fill our "responses" array with is Response
//									(The class here must be an NSRailsModel subclass)

@end