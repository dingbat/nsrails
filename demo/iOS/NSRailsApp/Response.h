//
//  Response.h
//  NSRailsApp
//
//  Created by Dan Hassin on 2/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "Post.h"
#import "NSRails.h"

@interface Response : NSRailsModel

@property (nonatomic, strong) Post *post;
@property (nonatomic, strong) NSString *author, *content;

@end
