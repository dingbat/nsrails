//
//  Response.m
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "Response.h"

@implementation Response
@synthesize content, author, post;
NSRMap(*, post -b)

// The NSRMap above will sync all properties w/Rails, and specially flag "post" to behave as a belongs_to association


/*
 ==================
 Not really essential for NSRails, but if you're curious about the "-b" flag:
 ==================
 
 The "-b" flag for the "post" property indicates that a Response belongs_to a post!
 
 This flag is not necessary (even if it's a belongs_to relation), but it allows us to create new Responses already attached to a specific Post, without having to update the Post object.
 
 Here's an example:

	 Response *newResp = [[Response alloc] init];
	 newResp.author = author;
	 newResp.content = content;
	 newResp.post = preExistingPost;      //<------ this line
	 
	 [newResp remoteCreate];

 In the marked line, we're setting the "post" property to a living, breathing, Post object, but NSRails knows to only send "post_id" instead of hashing out the entire Post object and sticking it into "post_attributes", which Rails would reject.
 
 Of course, this is only relevant for belongs_to since you'd typically *want* the "_attributes" key in most cases.

 See the wiki for more, specifically under NSRMap: https://github.com/dingbat/nsrails/wiki/NSRMap
 
 */

@end