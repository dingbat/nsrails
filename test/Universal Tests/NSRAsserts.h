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
#import "NSString+InflectionSupport.h"

//Make some private methods accessible
@interface NSRailsModel (internal)

+ (NSRConfig *) getRelevantConfig;

+ (NSString *) railsProperties;
+ (NSString *) getModelName;
+ (NSString *) getPluralModelName;

+ (NSRPropertyCollection *) propertyCollection;
- (NSRPropertyCollection *) propertyCollection;

- (NSString *) routeForInstanceRoute:(NSString *)route error:(NSError **)error;
+ (NSString *) routeForControllerRoute:(NSString *)route;

@end

@interface NSRConfig (internal)

+ (void) resetConfigs;

@end


#define NSRAssertClassModelName(mname, class)	GHAssertEqualStrings([class getModelName], mname, @"%@ model name failed.", NSStringFromClass(class))

#define NSRAssertClassPluralName(mname, class)	GHAssertEqualStrings([class getPluralModelName], mname, @"%@ model name failed.", NSStringFromClass(class))

//if statement, for limited scope
#define NSRAssertEqualArrays(arr, ...) \
if (YES) { \
NSArray *test = [NSArray arrayWithObjects:__VA_ARGS__, nil];\
GHAssertEqualObjects(arr, test, nil); \
}

#define NSRAssertClassProperties(class, ...) NSRAssertEqualArrays([[class propertyCollection] sendableProperties], __VA_ARGS__)

#define NSRAssertEqualConfigs(config,teststring,desc, ...) GHAssertEqualStrings(config.appURL, [@"http://" stringByAppendingString:teststring], desc, __VA_ARGS__)

#define NSRAssertClassConfig(class, teststring) NSRAssertEqualConfigs([class getRelevantConfig], teststring, @"%@ config failed", NSStringFromClass(class))

#define NSRAssertRelevantConfigURL(teststring,desc) NSRAssertEqualConfigs([NSRailsModel getRelevantConfig], teststring, desc, nil)

#define NSRAssertEqualsUnderscored(string, underscored) GHAssertEqualStrings([string underscore], underscored, nil)
#define NSRAssertEqualsCamelized(string, camelized) GHAssertEqualStrings([string camelize], camelized, nil)

