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

@end

@interface Test : GHTestCase
@end

@implementation Test

- (void) test_model_and_config_inheritance
{
	//was explicitly set to "parent"
	GHAssertEqualStrings(@"parent", [STParent getModelName], nil);
	
	
	//complacent child
	//is complacent (doesn't explicitly set NSRailsUseModelName or NSRailsUseDefaultModelName), so will inherit the "parent" from Parent
	GHAssertEqualStrings(@"parent", [STChild getModelName], nil);
	
	//is complacent (doesn't explicitly set NSRailsUseModelName or NSRailsUseDefaultModelName), so will inherit the "parent" from Child
	GHAssertEqualStrings(@"parent", [STGrandchild getModelName], nil);
	
	//is not complacent (defines NSRailsUseModelName), as set to "r_grandchild"
	GHAssertEqualStrings(@"r_gchild", [STRebelliousGrandchild getModelName], nil);
	
	
	//rebellious child
	//is rebellious (explicitly defines NSRailsUseDefaultModelName for itself, so should be default behavior)
	GHAssertEqualStrings(@"s_t_rebellious_child", [STRebelliousChild getModelName], nil);
	
	//is complacent (doesn't explicitly set), BUT will inherit default behavior from R.Child, so default behavior
	GHAssertEqualStrings(@"s_t_grandchild_of_rebellious", [STGrandchildOfRebellious getModelName], nil);
	
	//is rebellious (defines NSRailsUseModelName as"r_r_grandchild"), so it'll use that name
	GHAssertEqualStrings(@"r_gchild_r", [STRebelliousGrandchildOfRebellious getModelName], nil);
}

- (void) test_property_inheritance
{
	//this is just normal
	GHAssertEqualStrings(@"modelID=id, parent attributes", [STParent railsProperties], nil);
	
	
	//complacent child
	//is complacent (doesn't explicitly define NSRNoCarryFromSuper), so will inherit parent's attributes too
	GHAssertEqualStrings(@"modelID=id, child attributes, parent attributes", [STChild railsProperties], nil);
	
	//is complacent, so should inherit everything! (parent+child), as well as its own
	GHAssertEqualStrings(@"modelID=id, gchild attributes, child attributes, parent attributes", [STGrandchild railsProperties], nil);
	
	//is rebellious, so should inherit nothing! (only its own)
	GHAssertEqualStrings(@"modelID=id, _NSR_NO_SUPER_, r_gchild attributes", [STRebelliousGrandchild railsProperties], nil);
	
	
	//rebellious child
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	GHAssertEqualStrings(@"modelID=id, _NSR_NO_SUPER_, r_child attributes", [STRebelliousChild railsProperties], nil);
	
	//is complacent, so should inherit everything until it sees the _NSR_NO_SUPER_ (which it omits), meaning won't inherit Parent
	GHAssertEqualStrings(@"modelID=id, gchild_r attributes, , r_child attributes", [STGrandchildOfRebellious railsProperties], nil);
	
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	GHAssertEqualStrings(@"modelID=id, _NSR_NO_SUPER_, r_gchild_r attributes", [STRebelliousGrandchildOfRebellious railsProperties], nil);
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