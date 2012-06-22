//
//  Post.m
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "Post.h"
#import "Response.h"

@implementation Post
@synthesize content, author, createdAt, responses;

- (Class) nestedClassForProperty:(NSString *)property
{
	if ([property isEqualToString:@"responses"])
		return [Response class];
	
	return [super nestedClassForProperty:property];    
}

@end