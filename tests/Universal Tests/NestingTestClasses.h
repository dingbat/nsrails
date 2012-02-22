//
//  NestingTestClasses.h
//  NSRails
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

@interface Post : NSRailsModel

@property (nonatomic, strong) NSString *author, *body;
@property (nonatomic, strong) NSMutableArray *responses;

@end


@interface Response : NSRailsModel

@property (nonatomic, strong) NSString *body, *author;
@property (nonatomic, strong) Post *post;

@end


//bad because doesn't inherit from NSRailsModel
@interface BadResponse : NSObject

@property (nonatomic, strong) NSString *body, *author;
@property (nonatomic, strong) Post *post;

@end
