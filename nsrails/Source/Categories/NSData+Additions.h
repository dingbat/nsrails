//
// NSData additions from colloquy project
//
// Created by khammond on Mon Oct 29 2001.
// Formatted by Timothy Hatcher on Sun Jul 4 2004.
// Copyright (c) 2001 Kyle Hammond. All rights reserved.
// Original development by Dave Winer.
//

#import <Foundation/Foundation.h>

@interface NSData (NSDataAdditions)
+ (NSData *) dataWithBase64EncodedString:(NSString *) string;
- (id) initWithBase64EncodedString:(NSString *) string;

- (NSString *) base64Encoding;
- (NSString *) base64EncodingWithLineLength:(unsigned int) lineLength;

- (BOOL) hasPrefix:(NSData *) prefix;
- (BOOL) hasPrefixBytes:(void *) prefix length:(unsigned int) length;
@end
