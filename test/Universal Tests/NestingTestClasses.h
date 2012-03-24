//
//  NestingTestClasses.h
//  NSRails
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

@interface Post : NSRailsModel

@property (nonatomic, strong) NSString *author, *content;
@property (nonatomic, strong) NSMutableArray *responses;
@property (nonatomic, strong) NSDate *updatedAt, *createdAt;

@end


@interface NSRResponse : NSRailsModel   //prefix to test ignore-prefix feature

@property (nonatomic, strong) NSString *content, *author;
@property (nonatomic, strong) Post *post;

@end


//bad because doesn't inherit from NSRailsModel
@interface BadResponse : NSObject

@property (nonatomic, strong) NSString *content, *author;
@property (nonatomic, strong) Post *post;

@end
