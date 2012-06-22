//
//  NSRAsserts.h
//  NSRails
//
//  Created by Dan Hassin on 2/18/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "NSRails.h"
#import "MockServer.h"
#import "MockClasses.h"
#import "NSString+Inflection.h"


@interface NSRConfig (internal)

+ (void) resetConfigs;

@end

#define NSRAssertNoServer(x)	if (x) { STFail(@"Test Rails server not running -- run rails s on the demo app."); return; }


#define NSRAssertClassModelName(mname, class)	STAssertEqualObjects([class remoteModelName], mname, @"%@ model name failed.", NSStringFromClass(class))

#define NSRAssertClassPluralName(mname, class)	STAssertEqualObjects([class remoteControllerName], mname, @"%@ model name failed.", NSStringFromClass(class))

#define NSRArray(...) [NSArray arrayWithObjects:__VA_ARGS__, nil]
#define NSRDictionary(...) [NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__, nil]
#define NSRNumber(x)	[NSNumber numberWithInteger:x]

#define NSRAssertEqualArraysNoOrder(arr, arr2) \
if ([arr2 count] != [arr count]) STFail(@"%@ should be equal (order doesn't matter) to %@",arr,arr2); \
for (id obj in arr2) { \
if (![arr containsObject:obj]) STFail(@"%@ should be equal (order doesn't matter) to %@",arr,arr2); \
}

#define STRIP_WHITESPACE(x) [x stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]

#define NSRAssertEqualArraysNoOrderNoBlanks(b,a) \
if (YES) { \
int length = [b count]; \
for (NSString *obj in b) { \
NSString *strip = STRIP_WHITESPACE(obj); \
if (strip.length == 0) { length--; continue; } \
if (![a containsObject:obj] && ![a containsObject:strip]) STFail(@"%@ should be equal (order/blanks don't matter) to %@",a,b); \
}\
if ([a count] != length) STFail(@"%@ should be equal (order/blanks don't matter) to %@",a,b); \
}


#define NSRAssertEqualConfigs(config,string, ...) STAssertEqualObjects(config.appURL, string, [NSString stringWithFormat:__VA_ARGS__])


