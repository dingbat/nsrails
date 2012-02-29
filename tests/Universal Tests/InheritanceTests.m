//
//  UniversalTests.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//
 
#import "NSRConfig.h"
#import "NSRails.h"
#import "InheritanceTestClasses.h"
#import "TestClass.h"
#import "NSRAsserts.h"

@interface InheritanceTests : GHTestCase
@end

@implementation InheritanceTests

- (void) test_model_name_inheritance
{
	//was explicitly set to "parent"
	NSRAssertClassModelName(@"parent", [Parent class]);
	NSRAssertClassPluralName(@"parentS", [Parent class]);
	
	//complacent child
	//is complacent (doesn't explicitly set NSRailsUseModelName or NSRailsUseDefaultModelName), so will inherit the "parent" from Parent
	NSRAssertClassModelName(@"parent", [Child class]);
	NSRAssertClassPluralName(@"parentS", [Child class]); //explicit plural set
	
	//is complacent (doesn't explicitly set NSRailsUseModelName or NSRailsUseDefaultModelName), so will inherit the "parent" from Child
	NSRAssertClassModelName(@"parent", [Grandchild class]);
	NSRAssertClassPluralName(@"parentS", [Grandchild class]);
	
	//is not complacent (defines NSRailsUseModelName), as set to "r_grandchild"
	NSRAssertClassModelName(@"r_gchild", [RebelliousGrandchild class]);
	NSRAssertClassPluralName(@"r_gchilds", [RebelliousGrandchild class]); //no explicit plural set
	
	
	//rebellious child
	//is rebellious (explicitly defines NSRailsUseDefaultModelName for itself, so should be default behavior)
	NSRAssertClassModelName(@"rebellious_child", [RebelliousChild class]);
	NSRAssertClassPluralName(@"rebellious_childs", [RebelliousChild class]); //default plural set

	//is complacent (doesn't explicitly set), BUT will inherit default behavior from R.Child, so default behavior
	NSRAssertClassModelName(@"grandchild_of_rebellious", [GrandchildOfRebellious class]);
	NSRAssertClassPluralName(@"grandchild_of_rebelliouses", [GrandchildOfRebellious class]); //inherits default

	//is rebellious (defines NSRailsUseModelName as "r_gchild_r"), so it'll use that name
	NSRAssertClassModelName(@"r_gchild_r", [RebelliousGrandchildOfRebellious class]);
	NSRAssertClassPluralName(@"r_gchild_rS", [RebelliousGrandchildOfRebellious class]); //explicitly set
}


- (void) test_config_inheritance
{
	[[NSRConfig defaultConfig] setAppURL:@"Default"];
						  
	//was explicitly set to "parent"
	NSRAssertClassConfig([Parent class], @"parent");
	
	//complacent child
	//is complacent (doesn't explicitly set NSRailsUseConfig or NSRailsUseDefaultConfig), so will inherit the "parent" from Parent
	NSRAssertClassConfig([Child class], @"parent");
	
	//is complacent (doesn't explicitly set NSRailsUseConfig or NSRailsUseDefaultConfig), so will inherit the "parent" from Child
	NSRAssertClassConfig([Grandchild class], @"parent");
	
	//is not complacent (defines NSRailsUseConfig), as set to "r_grandchild"
	NSRAssertClassConfig([RebelliousGrandchild class], @"r_gchild");
	

	//rebellious child
	//is rebellious (explicitly defines NSRailsUseDefaultConfig for itself, so should be defaultConfig returned)
	NSRAssertClassConfig([RebelliousChild class], @"Default");
	
	//is complacent (doesn't explicitly set), BUT will inherit default behavior from R.Child, so default behavior
	NSRAssertClassConfig([GrandchildOfRebellious class], @"Default");
	
	//is rebellious (defines NSRailsUseConfig as "r_gchild_r"), so it'll use that name
	NSRAssertClassConfig([RebelliousGrandchildOfRebellious class], @"r_gchild_r");
}

- (void) test_property_inheritance
{
	//this is just normal
	NSRAssertClassProperties(@"remoteID, parentAttr", [Parent class]);
	
	//complacent child
	//is complacent (doesn't explicitly define NSRNoCarryFromSuper), so will inherit parent's attributes too
	//this is simultaneously a test that the "*" from Parent isn't carried over - child has 2 properties and only one is defined
	//this will also test to see if syncing "parentAttr2" is allowed (attribute in parent class not synced by parent class)
	NSRAssertClassProperties(@"remoteID, childAttr1, parentAttr2, parentAttr", [Child class]);
	
	//is complacent, so should inherit everything! (parent+child), as well as its own
	//however, excludes parentAttr2 as a test
	NSRAssertClassProperties(@"remoteID, childAttr1, gchildAttr, parentAttr", [Grandchild class]);
	
	//is rebellious, so should inherit nothing! (only its own)
	NSRAssertClassProperties(@"remoteID, r_gchildAttr", [RebelliousGrandchild class]);
	
	
	//rebellious child
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	NSRAssertClassProperties(@"remoteID, r_childAttr", [RebelliousChild class]);
	
	//is complacent, so should inherit everything until it sees the _NSR_NO_SUPER_ (which it omits), meaning won't inherit Parent
	NSRAssertClassProperties(@"remoteID, gchild_rAttr, r_childAttr", [GrandchildOfRebellious class]);
	
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	NSRAssertClassProperties(@"remoteID, r_gchild_rAttr", [RebelliousGrandchildOfRebellious class]);
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