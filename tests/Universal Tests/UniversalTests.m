//
//  UniversalTests.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
 
#import "NSRConfig.h"
#import "NSRails.h"
#import "InheritanceTestClasses.h"
#import "TestClass.h"

@interface NSRailsModel (internal)

+ (NSRConfig *) getRelevantConfig;

- (void) setAttributesAsPerDictionary:(NSDictionary *)dict;
- (NSDictionary *) dictionaryOfRelevantProperties;

+ (NSString *) railsProperties;
+ (NSString *) getModelName;
+ (NSString *) getPluralModelName;

+ (NSRConfig *) getRelevantConfig;

- (NSString *) listOfSendableProperties;

@end

@interface UniversalTests : GHTestCase
@end

@implementation UniversalTests

- (void) test_model_and_config_inheritance
{
	//was explicitly set to "parent"
	GHAssertEqualStrings(@"parent", [Parent getModelName], nil);
	
	
	//complacent child
	//is complacent (doesn't explicitly set NSRailsUseModelName or NSRailsUseDefaultModelName), so will inherit the "parent" from Parent
	GHAssertEqualStrings(@"parent", [Child getModelName], nil);
	
	//is complacent (doesn't explicitly set NSRailsUseModelName or NSRailsUseDefaultModelName), so will inherit the "parent" from Child
	GHAssertEqualStrings(@"parent", [Grandchild getModelName], nil);
	
	//is not complacent (defines NSRailsUseModelName), as set to "r_grandchild"
	GHAssertEqualStrings(@"r_gchild", [RebelliousGrandchild getModelName], nil);
	
	
	//rebellious child
	//is rebellious (explicitly defines NSRailsUseDefaultModelName for itself, so should be default behavior)
	GHAssertEqualStrings(@"rebellious_child", [RebelliousChild getModelName], nil);
	
	//is complacent (doesn't explicitly set), BUT will inherit default behavior from R.Child, so default behavior
	GHAssertEqualStrings(@"grandchild_of_rebellious", [GrandchildOfRebellious getModelName], nil);
	
	//is rebellious (defines NSRailsUseModelName as"r_r_grandchild"), so it'll use that name
	GHAssertEqualStrings(@"r_gchild_r", [RebelliousGrandchildOfRebellious getModelName], nil);
}

#define NSRailsAssertProperties(props, class)	GHAssertEqualStrings(props,[[class new] listOfSendableProperties], @"%@ inheritance failed.", NSStringFromClass(class))

- (void) test_property_inheritance
{
	//this is just normal
	NSRailsAssertProperties(@"modelID, parentAttr", [Parent class]);
	
	//complacent child
	//is complacent (doesn't explicitly define NSRNoCarryFromSuper), so will inherit parent's attributes too
	//this is simultaneously a test that the "*" from Parent isn't carried over - child has 2 properties and only one is defined
	//this will also test to see if Railsifying "parentAttr2" is allowed (attribute in parent class not Railsified by parent class)
	NSRailsAssertProperties(@"modelID, childAttr1, parentAttr2, parentAttr", [Child class]);
	
	//is complacent, so should inherit everything! (parent+child), as well as its own
	//however, excludes parentAttr2 as a test
	NSRailsAssertProperties(@"modelID, childAttr1, gchildAttr, parentAttr", [Grandchild class]);
	
	//is rebellious, so should inherit nothing! (only its own)
	NSRailsAssertProperties(@"modelID, r_gchildAttr", [RebelliousGrandchild class]);
	
	
	//rebellious child
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	NSRailsAssertProperties(@"modelID, r_childAttr", [RebelliousChild class]);
	
	//is complacent, so should inherit everything until it sees the _NSR_NO_SUPER_ (which it omits), meaning won't inherit Parent
	NSRailsAssertProperties(@"modelID, gchild_rAttr, r_childAttr", [GrandchildOfRebellious class]);
	
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	NSRailsAssertProperties(@"modelID, r_gchild_rAttr", [RebelliousGrandchildOfRebellious class]);
}

- (void) test_invalid_railsify
{
	NSRailsAssertProperties(@"modelID, attr1", [TestClass class]);
}

#define NSRTestRelevantConfigURL(x,y) GHAssertEqualStrings([NSRailsModel getRelevantConfig].appURL, x, y)

- (void) test_nested_config_contexts
{
	[[NSRConfig defaultConfig] setAppURL:@"http://Default"];
	
	[[NSRConfig defaultConfig] useIn:^
	 {
		 NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"http://Nested"];
		 [c use];
		 
		 NSRTestRelevantConfigURL(@"http://Nested", nil);

		 [[NSRConfig defaultConfig] useIn:^
		  {
			  NSRTestRelevantConfigURL(@"http://Default", nil);

			  [c useIn:^
			  {
				  NSRTestRelevantConfigURL(@"http://Nested", nil);
			  }];
		  }];
		 
		 [c end];
		 
		 NSRTestRelevantConfigURL(@"http://Default", nil);
	 }];
	
	GHAssertEqualStrings(@"test_class", [TestClass getModelName], @"auto-underscoring");

	NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"http://NoAuto"];
	c.automaticallyUnderscoreAndCamelize = NO;
	[c useIn:
	 ^{
		 NSRTestRelevantConfigURL(@"http://NoAuto", nil);

		 GHAssertEqualStrings(@"TestClass", [TestClass getModelName], @"No auto-underscoring");
	 }];
	
	NSRTestRelevantConfigURL(@"http://Default", nil);
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