//
//  Person.m
//  RailsTest
//
//  Created by Dan Hassin on 1/26/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "Person.h"

@implementation Person

@synthesize name, brain, age;
RailsShare("name, brain, age")

- (NSString *) decodeName:(NSString *)_name
{
	return [_name lowercaseString];
}

- (NSString *) encodeName:(NSString *)_name
{
	return [_name uppercaseString];
}

@end

