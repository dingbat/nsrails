//
//  User.m
//  RailsTest
//
//  Created by Dan Hassin on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "User.h"

@implementation User

@synthesize username, password, myFriend, stories;
MakeRails(@"username, password, myFriend=friend, stories:Story")

- (NSString *) decodePassword:(NSString *)_password
{
	return [_password lowercaseString];
}

- (NSString *) encodePassword:(NSString *)_password
{
	return [_password uppercaseString];
}

@end

