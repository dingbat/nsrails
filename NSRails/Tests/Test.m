//
//  MyTest.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h> 
#import "NSRConfig.h"
#import "NSRails.h"
#import "STChild.h"
#import "STGrandchild.h"

@interface NSRailsModel (internal)

+ (NSRConfig *) getRelevantConfig;

- (void) setAttributesAsPerDictionary:(NSDictionary *)dict;
- (NSDictionary *) dictionaryOfRelevantProperties;

+ (NSString *) railsProperties;
+ (NSString *) getModelName;
+ (NSString *) getPluralModelName;

@end

@interface Test : GHTestCase
@end

@implementation Test

- (void) testInheritance
{
	GHAssertEqualStrings(@"s_t_grandchild", [STGrandchild getModelName], @"modelname with inheritance");
	
	NSRConfig *c = [[NSRConfig alloc] init];
	c.automaticallyUnderscoreAndCamelize = NO;
	[c useIn:
	 ^{
		 GHAssertEqualStrings(@"STGrandchild", [STGrandchild getModelName], @"no automatic inflection");
	}];
}

- (void)setUpClass {
	// Run at start of all tests in the class
}

- (void)tearDownClass {
	// Run at end of all tests in the class
}

- (void)setUp {
	// Run before each test method
}

- (void)tearDown {
	// Run after each test method
} 

@end