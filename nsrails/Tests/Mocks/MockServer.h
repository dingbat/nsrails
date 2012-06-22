//
//  MockServer.h
//  NSRails
//
//  Created by Dan Hassin on 5/7/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MockServer : NSObject

+ (NSString *) datetime;

+ (NSString *) full404Error;
+ (NSString *) short404Error;

+ (NSString *) validation422Error;

+ (NSString *) ok200;
+ (NSString *) creation201;

+ (NSArray *) fullErrors;
+ (NSArray *) shortErrors;
+ (NSArray *) statusCodes;

/****/

+ (NSDictionary *) newCustomCoder;
+ (NSDictionary *) newCustomSender;
+ (NSDictionary *) newDictionaryNester;

@end
