//
//  NSRails+SBJson.h
//  NSRails
//
//  Created by Dan Hassin on 2/24/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBJson.h"

//just adds an error handlers for these two methods


@interface NSObject (NSObject_SBJsonWriting_NSR)

- (NSString *)JSONRepresentation:(NSError **)error;

@end


@interface NSString (NSString_SBJsonParsing_NSR)

- (id)JSONValue:(NSError **)error;

@end