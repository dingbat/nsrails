//
//  Brain.h
//  NSRailsApp
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

@interface Brain : NSRailsModel

@property (nonatomic, strong) NSMutableArray *thoughts;
@property (nonatomic, strong) NSString *size;

@end
