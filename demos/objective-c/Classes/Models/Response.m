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

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
	if ([property isEqualToString:@"post"])
		return [NSRRelationship belongsTo:[Post class]];
	
	return [super relationshipForProperty:property];
}

/*
 ==================
 Note:
 ==================
 
 Overriding relationshipForProperty: above is not necessary. By default, (if it's not overridden), NSRails will detect that 'post' is of type Post (which is an NSRRemoteObject subclass), and will treat it as a hasOne: relationship.
 
 * The hasOne relationship means that when sending a Response, 'post' will be sent as a dictionary with remote key 'post_attributes'.
 
 * The belongsTo relationship means that when sending a Response, only the remoteID from 'post' will be sent, with the remote key 'post_id'
 
   This means that you don't need to define a postID attribute in your Response class, assign it a real Post object, and still have Rails be chill when receiving it! (Rails gets angry if you send it _attributes for a belongs-to relation.)
 
   Of course, this is only relevant for belongs-to since you'd typically *want* the "_attributes" key in most cases. 
 */

@end