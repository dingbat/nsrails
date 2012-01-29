//
//  Friend.h
//  RailsTest
//
//  Created by Dan Hassin on 1/25/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

@interface Brain : RailsModel
{
	NSString *size;
	NSMutableArray *thoughts;
}

@property (nonatomic, strong) NSString *size;
@property (nonatomic, strong) NSMutableArray *thoughts;

@end
