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

//Make some private methods accessible
@interface NSRailsModel (internal)

+ (NSRConfig *) getRelevantConfig;

- (void) setAttributesAsPerDictionary:(NSDictionary *)dict;
- (NSDictionary *) dictionaryOfRelevantProperties;

+ (NSString *) railsProperties;
+ (NSString *) getModelName;
+ (NSString *) getPluralModelName;

+ (NSRConfig *) getRelevantConfig;

+ (NSRPropertyCollection *) propertyCollection;

- (NSString *) routeForInstanceRoute:(NSString *)route error:(NSError **)error;
+ (NSString *) routeForControllerRoute:(NSString *)route;

@end

@interface NSRConfig (internal)

+ (void) resetConfigs;

@end


#define NSRAssertClassModelName(mname, class)	GHAssertEqualStrings([class getModelName], mname, @"%@ model name failed.", NSStringFromClass(class))

#define NSRAssertClassPluralName(mname, class)	GHAssertEqualStrings([class getPluralModelName], mname, @"%@ model name failed.", NSStringFromClass(class))

//do-while loop so that test has limited scope
#define NSRAssertClassProperties(class, property, ...) \
do { \
NSArray *test = [NSArray arrayWithObjects:property, __VA_ARGS__, nil];\
GHAssertEqualObjects([[class propertyCollection] sendableProperties], test, @"%@ properties failed.", NSStringFromClass(class)); \
} while (NO) 

#define NSRAssertEqualConfigs(config,teststring,desc, ...) GHAssertEqualStrings(config.appURL, [@"http://" stringByAppendingString:teststring], desc, __VA_ARGS__)

#define NSRAssertClassConfig(class, teststring) NSRAssertEqualConfigs([class getRelevantConfig], teststring, @"%@ config failed", NSStringFromClass(class))

#define NSRAssertRelevantConfigURL(teststring,desc) NSRAssertEqualConfigs([NSRailsModel getRelevantConfig], teststring, desc, nil)
