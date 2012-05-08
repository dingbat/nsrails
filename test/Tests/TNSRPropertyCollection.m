//
//  UniversalTests.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface TNSRPropertyCollection : GHTestCase
@end

@interface FlagTestClass : NSRailsModel
@property (nonatomic, strong) NSString *sendretrieve, *nothing, *retrieve, *send, *local, *decode, *encode, *sendOnly, *parent, *encodedecode, *objc;
@property (nonatomic, strong) NSArray *nestedArrayExplicit, *nestedArrayNothing;
@property (nonatomic, strong) TestClass *nestedExplicit, *nestedNothing;
@end

@implementation FlagTestClass
@synthesize sendretrieve, nothing, retrieve, send, local, decode, encode, sendOnly, parent, encodedecode, objc;
@synthesize nestedNothing, nestedExplicit, nestedArrayNothing, nestedArrayExplicit;
@end

@implementation TNSRPropertyCollection

#define NSRInitTestClass(customProperties) [[NSRPropertyCollection alloc] initWithClass:[TestClass class] syncString:customProperties customConfig:nil]

#define NSRAssertClassProperties(class, ...) NSRAssertEqualArraysNoOrder([[class propertyCollection] sendableProperties], __VA_ARGS__)
#define NSRAssertInstanceProperties(class, ...) NSRAssertEqualArraysNoOrder([[[[class alloc] init] propertyCollection] sendableProperties], __VA_ARGS__)

#define NSRAssertClassAndInstanceProperties(class, ...) NSRAssertClassProperties(class, __VA_ARGS__); NSRAssertInstanceProperties(class, __VA_ARGS__)

- (void) test_invalid_sync_params
{
	GHAssertThrows(NSRInitTestClass(@"f8a asufoj as;lfkas [pfl;aksm jofaskf oasa"), @"Should've failed random mash");

	GHAssertNoThrow(NSRInitTestClass(@"attr1,\nattr2"), @"Shouldn't crash if newline in the middle");

	GHAssertThrows(NSRInitTestClass(@"primitiveAttr"), @"Should crash if a primitive attribute was defined in NSRailsSync");
	
	GHAssertThrows(NSRInitTestClass(@"remoteID=id, myID=id"), @"Should crash if trying to set a property to ID equiv in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"remoteID=id, myID=id -r"), @"Shouldn't crash for setting a property to ID -r only");
	
	GHAssertThrows(NSRInitTestClass(@"nonexistent"), @"Should crash if trying to set a nonexistent property in NSRS");
	
	GHAssertThrows(NSRInitTestClass(@"attr1=hello, attr2=hello"), @"Should crash if trying to set two properties to the same rails equiv in NSRS");
	GHAssertThrows(NSRInitTestClass(@"attr1=hello -r, attr2=hello, myID=hello"), @"Should crash if trying to set two sendable properties to the same rails equiv in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"attr1=hello -r, attr2=hello"), @"Shouldn't crash if two properties are set to the same rails equiv in NSRS, but only one is sendable");
	
	GHAssertThrows(NSRInitTestClass(@"array"), @"Should crash without class to fill array");
	GHAssertThrows(NSRInitTestClass(@"array:FakeClass"), @"Should crash without real class to fill array");
	GHAssertThrows(NSRInitTestClass(@"array:BadResponse"), @"Should crash because class exists but doesn't inherit from NSRM");
	GHAssertNoThrow(NSRInitTestClass(@"array:"), @"Shouldn't crash when defaulting to NSDictionaries");
}

- (void) test_property_flags
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"sendretrieve -rs, nothing, retrieve=rails -r, send -s, local -x, decode -d, encode -e, parent -b, encodedecode -ed, nestedNothing, objc=rails, nestedExplicit:TestClass, nestedArrayNothing=nestedArrayNothing:, nestedArrayExplicit:TestClass" 
																customConfig:nil];
	
	NSRAssertEqualArraysNoOrder(pc.propertyEquivalents.allKeys, @"sendretrieve", @"nothing", @"retrieve", @"send", @"decode", @"encode", @"parent", @"nestedNothing", @"nestedExplicit", @"nestedArrayNothing", @"nestedArrayExplicit", @"encodedecode", @"objc");
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"rails" autoinflect:NO] containsObject:@"retrieve"], @"Should pick up that remote rails is defined as retrieve");
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"rails" autoinflect:NO] containsObject:@"objc"], @"Should pick up that remote rails is also defined as objc");

	GHAssertNil([pc objcPropertiesForRemoteEquivalent:@"nested_explicit" autoinflect:NO], @"Should fail trying to find nested_explicit property in objc (nothing explicit and not autoinflecting)");
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"nested_explicit" autoinflect:YES] containsObject:@"nestedExplicit"], @"Should find default autoinflected nestedExplicit from nested_explicit");

	GHAssertEqualStrings([pc remoteEquivalentForObjcProperty:@"nestedExplicit" autoinflect:NO], @"nestedExplicit", @"Should return non-autoinflected default string (identical)");
	GHAssertEqualStrings([pc remoteEquivalentForObjcProperty:@"nestedExplicit" autoinflect:YES], @"nested_explicit", @"Should return autoinflected default string (default)");

	GHAssertEqualStrings([pc remoteEquivalentForObjcProperty:@"nestedArrayNothing" autoinflect:NO], @"nestedArrayNothing", @"Should return the explicit equivalency (even if no-autoinflect)");
	GHAssertEqualStrings([pc remoteEquivalentForObjcProperty:@"nestedArrayNothing" autoinflect:YES], @"nestedArrayNothing", @"Should return the explicit equivalency (even if autoinflect)");
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"nestedArrayNothing" autoinflect:NO] containsObject:@"nestedArrayNothing"], @"Should return the explicit equivalency (even if no autoinflect)");
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"nestedArrayNothing" autoinflect:YES] containsObject:@"nestedArrayNothing"], @"Should return the explicit equivalency (even if autoinflect)");

	
	GHAssertEqualStrings([pc remoteEquivalentForObjcProperty:@"objc" autoinflect:NO], @"rails", @"Should pick up that objc is defined as remote rails");
	
	NSRAssertEqualArraysNoOrder(pc.retrievableProperties, @"sendretrieve", @"nothing", @"retrieve", @"decode", @"encode", @"parent", @"nestedNothing", @"nestedExplicit", @"nestedArrayNothing", @"nestedArrayExplicit", @"encodedecode", @"objc");
	NSRAssertEqualArraysNoOrder(pc.sendableProperties, @"sendretrieve", @"nothing", @"send", @"decode", @"encode", @"parent", @"nestedNothing", @"nestedExplicit", @"nestedArrayNothing", @"nestedArrayExplicit", @"encodedecode", @"objc");
	NSRAssertEqualArrays(pc.decodeProperties, @"decode", @"encodedecode");
	NSRAssertEqualArrays(pc.encodeProperties, @"encode", @"encodedecode");
	
	GHAssertTrue([pc propertyIsMarkedBelongsTo:@"parent"], @"parent should be marked belongs-to (-b included)");
	GHAssertFalse([pc propertyIsMarkedBelongsTo:@"nestedNothing"], @"nestedNothing shouldn't be marked belongs-to (no -b)");
	
	GHAssertEqualStrings([pc.nestedModelProperties objectForKey:@"nestedNothing"], @"TestClass", @"Should automatically pick up class of nestedNothing");
	GHAssertEqualStrings([pc.nestedModelProperties objectForKey:@"nestedExplicit"], @"TestClass", @"Should pick up class of nestedNothing");

	GHAssertNil([pc.nestedModelProperties objectForKey:@"nestedArrayNothing"], @"Should automatically use dictionaries for array nestedArrayNothing");
	GHAssertEqualStrings([pc.nestedModelProperties objectForKey:@"nestedArrayExplicit"], @"TestClass", @"Should pick up explicit assc of nestedArrayNothing");
}

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

- (void)setUpClass
{
	// Run at start of all tests in the class
}

- (void)tearDownClass {
	// Run at end of all tests in the class
}

- (void)setUp
{
	// Run before each test method
}

- (void)tearDown {
	// Run after each test method
} 

@end