//
//  NSRAsserts.h
//  NSRails
//
//  Created by Dan Hassin on 2/18/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "NSRails.h"
#import "NSRPropertyCollection.h"
#import "NSRConfig.h"
#import "NSString+Inflection.h"
#import "NSObject+Properties.h"

#import "MockServer.h"

//Make some private methods accessible
@interface NSRailsModel (internal)

+ (NSRConfig *) getRelevantConfig;

+ (NSString *) masterNSRailsSync;
+ (NSString *) masterNSRailsSyncWithOverrideString:(NSString *)override;

+ (NSString *) masterModelName;
+ (NSString *) masterPluralName;

+ (NSDictionary *) NSRailsProperties;

+ (NSRPropertyCollection *) propertyCollection;
- (NSRPropertyCollection *) propertyCollection;

- (NSString *) routeForInstanceMethod:(NSString *)route;
+ (NSString *) routeForControllerMethod:(NSString *)route;

+ (NSString *) typeForProperty:(NSString *)prop;

@end

@interface NSRConfig (internal)

+ (void) resetConfigs;

@end


#define NSRAssertClassModelName(mname, class)	STAssertEqualObjects([class masterModelName], mname, @"%@ model name failed.", NSStringFromClass(class))

#define NSRAssertClassPluralName(mname, class)	STAssertEqualObjects([class masterPluralName], mname, @"%@ model name failed.", NSStringFromClass(class))

#define NSRArray(...) [NSArray arrayWithObjects:__VA_ARGS__, nil]
#define NSRDictionary(...) [NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__, nil]

#define NSRAssertEqualArraysNoOrder(arr, arr2) \
if ([arr2 count] != arr.count) STFail(@"%@ should be equal (order doesn't matter) to %@",arr,arr2); \
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


#define NSRAssertEqualConfigs(config,string,desc, ...) STAssertEqualObjects(config.appURL, string, desc, __VA_ARGS__)


