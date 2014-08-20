//
//  NSRAsserts.h
//  NSRails
//
//  Created by Dan Hassin on 2/18/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <NSRails/NSRails.h>
#import "MockServer.h"
#import "MockClasses.h"


@interface NSRConfig (internal)

+ (void) resetConfigs;

@end

#define NSRAssertNoServer(x)    if (x) { XCTFail(@"Test Rails server not running -- run rails s on the demo app."); return; }

#define NSRAssertEqualArraysNoOrder(arr, arr2) \
if ([arr2 count] != [arr count]) XCTFail(@"%@ should be equal (order doesn't matter) to %@",arr,arr2); \
for (id obj in arr2) { \
if (![arr containsObject:obj]) XCTFail(@"%@ should be equal (order doesn't matter) to %@",arr,arr2); \
}
