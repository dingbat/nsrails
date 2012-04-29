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
	NSRAssertClassAndInstanceConfig([Parent class], @"parent");
	
	//complacent child
	//is complacent (doesn't explicitly set NSRailsUseConfig or NSRailsUseDefaultConfig), so will inherit the "parent" from Parent
	NSRAssertClassAndInstanceConfig([Child class], @"parent");
	
	//is complacent (doesn't explicitly set NSRailsUseConfig or NSRailsUseDefaultConfig), so will inherit the "parent" from Child
	NSRAssertClassAndInstanceConfig([Grandchild class], @"parent");
	
	//is not complacent (defines NSRailsUseConfig), as set to "r_grandchild"
	NSRAssertClassAndInstanceConfig([RebelliousGrandchild class], @"r_gchild");
	

	//rebellious child
	//is rebellious (explicitly defines NSRailsUseDefaultConfig for itself, so should be defaultConfig returned)
	NSRAssertClassAndInstanceConfig([RebelliousChild class], @"Default");
	
	//is complacent (doesn't explicitly set), BUT will inherit default behavior from R.Child, so default behavior
	NSRAssertClassAndInstanceConfig([GrandchildOfRebellious class], @"Default");
	
	//is rebellious (defines NSRailsUseConfig as "r_gchild_r"), so it'll use that name
	NSRAssertClassAndInstanceConfig([RebelliousGrandchildOfRebellious class], @"r_gchild_r");
}

- (void) test_property_inheritance
{
	//this is just normal
	NSRAssertClassAndInstanceProperties([Parent class], @"remoteID", @"parentAttr");
	
	//complacent child
	//is complacent (doesn't explicitly define NSRNoCarryFromSuper), so will inherit parent's attributes too
	//this is simultaneously a test that the "*" from Parent isn't carried over - child has 2 properties and only one is defined
	//this will also test to see if syncing "parentAttr2" is allowed (attribute in parent class not synced by parent class)
	NSRAssertClassAndInstanceProperties([Child class], @"remoteID", @"childAttr1", @"parentAttr2", @"parentAttr");
	
	//is complacent, so should inherit everything! (parent+child), as well as its own
	//however, excludes parentAttr2 as a test
	NSRAssertClassAndInstanceProperties([Grandchild class], @"remoteID", @"childAttr1", @"gchildAttr", @"parentAttr");
	
	//is rebellious, so should inherit nothing! (only its own)
	NSRAssertClassAndInstanceProperties([RebelliousGrandchild class], @"remoteID", @"r_gchildAttr");
	
	
	//rebellious child
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	NSRAssertClassAndInstanceProperties([RebelliousChild class], @"remoteID", @"r_childAttr");
	
	//is complacent, so should inherit everything until it sees the _NSR_NO_SUPER_ (which it omits), meaning won't inherit Parent
	NSRAssertClassAndInstanceProperties([GrandchildOfRebellious class], @"remoteID", @"gchild_rAttr", @"r_childAttr");
	
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	NSRAssertClassAndInstanceProperties([RebelliousGrandchildOfRebellious class], @"remoteID", @"r_gchild_rAttr");
}

- (void)setUpClass {
	// Run at start of all tests in the class
}

- (void)tearDownClass 
{
	// Run at end of all tests in the class
}

- (void)setUp {
	// Run before each test method
}

- (void)tearDown {
	// Run after each test method
} 

@end