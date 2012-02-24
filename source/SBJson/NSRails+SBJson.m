//
//  NSRails+SBJson.m
//  NSRails
//
//  Created by Dan Hassin on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRails+SBJson.h"

@implementation NSObject (NSObject_SBJsonWriting_NSR)

- (NSString *)JSONRepresentation:(NSError **)error {
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];    
    NSString *json = [writer stringWithObject:self error:error];
    return json;
}

@end


@implementation NSString (NSString_SBJsonParsing_NSR)

- (id)JSONValue:(NSError **)error {
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    id repr = [parser objectWithString:self error:error];
    return repr;
}

@end