//
//  NSRAsserts.h
//  NSRails
//
//  Created by Dan Hassin on 2/18/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"
#import "NSRPropertyCollection.h"
#import "NSRConfig.h"
#import "NSString+Inflection.h"
#import "NSObject+Properties.h"


#import "TestClasses.h"
#import "MockServer.h"

//Make some private methods accessible
@interface NSRailsModel (internal)

+ (NSRConfig *) getRelevantConfig;

+ (NSString *) masterNSRailsSync;
+ (NSString *) masterNSRailsSyncWithOverrideString:(NSString *)override;

+ (NSString *) masterModelName;
+ (NSString *) masterPluralName;

+ (NSRPropertyCollection *) propertyCollection;
- (NSRPropertyCollection *) propertyCollection;

- (NSString *) routeForInstanceMethod:(NSString *)route;
+ (NSString *) routeForControllerMethod:(NSString *)route;

@end

@interface NSRConfig (internal)

+ (void) resetConfigs;

@end


#define NSRAssertClassModelName(mname, class)	GHAssertEqualStrings([class masterModelName], mname, @"%@ model name failed.", NSStringFromClass(class))

#define NSRAssertClassPluralName(mname, class)	GHAssertEqualStrings([class masterPluralName], mname, @"%@ model name failed.", NSStringFromClass(class))

//if statement, for limited scope
#define NSRAssertEqualArrays(arr, ...) \
if (YES) { \
NSArray *test = [NSArray arrayWithObjects:__VA_ARGS__, nil];\
GHAssertEqualObjects(arr, test, nil); \
}

#define NSRAssertEqualArraysNoOrder(arr, ...) \
if (YES) \
{ \
NSArray *test = [NSArray arrayWithObjects:__VA_ARGS__, nil];\
if (test.count != arr.count) GHFail(@"%@ should be equal (order doesn't matter) to %@",arr,test); \
for (id obj in test) { \
if (![arr containsObject:obj]) GHFail(@"%@ should be equal (order doesn't matter) to %@",arr,test); \
} \
}

#define NSRAssertEqualConfigs(config,teststring,desc, ...) GHAssertEqualStrings(config.appURL, [@"http://" stringByAppendingString:teststring], desc, __VA_ARGS__)

#define NSRAssertInstanceConfig(class, teststring) NSRAssertEqualConfigs([[[class alloc] init] getRelevantConfig], teststring, @"%@ config failed", NSStringFromClass(class))

#define NSRAssertClassConfig(class, teststring) NSRAssertEqualConfigs([class getRelevantConfig], teststring, @"%@ config failed", NSStringFromClass(class))

#define NSRAssertClassAndInstanceConfig(class, teststring) NSRAssertInstanceConfig(class, teststring); NSRAssertClassConfig(class, teststring)

#define NSRAssertRelevantConfigURL(teststring,desc) NSRAssertEqualConfigs([NSRailsModel getRelevantConfig], teststring, desc, nil)

#define NSRAssertEqualsUnderscored(string, underscored) GHAssertEqualStrings([string underscore], underscored, nil)
#define NSRAssertEqualsCamelized(string, camelized) GHAssertEqualStrings([string camelize], camelized, nil)

