//
//  User.h
//  RailsTest
//
//  Created by Dan Hassin on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSRails.h"
#import "Friend.h"

@interface User : RailsModel
{
	NSString *username, *password;
	Friend *myFriend;
	NSMutableArray *stories;
}

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) Friend *myFriend;
@property (nonatomic, strong) NSMutableArray *stories;

@end
