//
//  Person.h
//  RailsTest
//
//  Created by Dan Hassin on 1/26/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSRails.h"
#import "Brain.h"

@interface Person : RailsModel
{
	NSString *name;
	NSNumber *age;
	Brain *brain;
}

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *age;
@property (nonatomic, strong) Brain *brain;

@end
