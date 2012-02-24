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

// Sync up all properties, and specially define the property "post"



//////////////////////////////////////////////////////////////////
// Not really essential for NSRails, but for the advanced/curious:
///////////////////////////////////////////////////////////////////////

//    The "-b" flag for the "post" property indicates that a Response *belongs_to* a post!
//    This flag is not necessary (even if it's a belongs_to relation), but it's useful we want to be able to create new Responses already attached to a specific Post, without having to update the Post object

//    Here's an example:

/*
 Response *newResp = [[Response alloc] init];
 newResp.author = author;
 newResp.body = content;
 newResp.post = preExistingPost;      //<------ this line
 
 
 [newResp remoteCreate];
 */

// In the marked line, we're setting the "post" property to a living, breathing, Post object, but NSRails knows to only send "post_id" instead of hashing out the entire Post object and sticking it into "post_attributes", which Rails would reject.
// This is only relevant for belongs_to - you *want* the "_attributes" key in most cases


//See the Wiki ( https://github.com/dingbat/nsrails/wiki ) for more, specifically under NSRailsSync ( https://github.com/dingbat/nsrails/wiki/NSRailsSync )

@end