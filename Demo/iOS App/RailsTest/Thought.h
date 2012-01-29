//
//  Story.h
//  RailsTest
//
//  Created by Dan Hassin on 1/24/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

@interface Thought : RailsModel
{
	NSString *content;
}

@property (nonatomic, strong) NSString *content;

@end
