//
//  NSString+Inflection.h
//  NSRails
//
//  Created by Dan Hassin on 3/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//


@interface NSString (NSR_Inflection)

- (NSString *) underscore;
- (NSString *) underscoreIgnorePrefix:(BOOL)b;

- (NSString *) camelize;

- (NSString *) pluralize;

- (NSString *) properCase; //first letter capitalized
- (NSString *) toClassName; //camelize+properCase

@end
