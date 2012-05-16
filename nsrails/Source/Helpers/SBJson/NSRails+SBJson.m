//
//  NSRails+SBJson.m
//  NSRails
//
//  Created by Dan Hassin on 2/24/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails+SBJson.h"

@implementation NSObject (NSObject_SBJsonWriting_NSR)

- (NSString *)JSONRepresentation:(NSError **)error {
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];    
    NSString *json = [writer stringWithObject:self error:error];
    return json;
}

- (BOOL) isJSONParsable
{
	return ([self isKindOfClass:[NSArray class]] ||
			[self isKindOfClass:[NSDictionary class]] ||
			[self isKindOfClass:[NSString class]] ||
			[self isKindOfClass:[NSNumber class]] ||
			[self isKindOfClass:[NSNull class]]);
}

@end


@implementation NSString (NSString_SBJsonParsing_NSR)

- (id)JSONValue:(NSError **)error {
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    id repr = [parser objectWithString:self error:error];
    return repr;
}

@end