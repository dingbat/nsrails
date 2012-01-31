//
//  NSRConnection.h
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSRConnection : NSObject
{
}

+ (void) crashWithError:(NSError *)error;

+ (NSOperationQueue *) sharedQueue;

+ (NSString *) makeRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(void(^)(NSString *result, NSError *error))completionBlock;

@end
