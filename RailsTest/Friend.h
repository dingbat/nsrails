//
//  Friend.h
//  RailsTest
//
//  Created by Dan Hassin on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRails.h"

@interface Friend : RailsModel
{
	NSString *name;
}

@property (nonatomic, strong) NSString *name;

@end
