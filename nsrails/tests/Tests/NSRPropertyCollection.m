//
//  NSRPropertyCollection.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface TestClassParent : NSRailsModel
@end

@interface TestClass : NSRailsModel

@property (nonatomic) int primitiveAttr;
@property (nonatomic, strong) NSString *myID;
@property (nonatomic, strong) NSString *attr1;
@property (nonatomic, strong) NSString *attr2;
@property (nonatomic, strong, readonly) NSString *badRetrieve;

@property (nonatomic, strong) NSString *send, *retrieve, *encode, *decode, *local;
@property (nonatomic, strong) TestClassParent *parent;

@property (nonatomic, strong) NSArray *array;

@end

@implementation TestClassParent
@end

@implementation TestClass
@synthesize primitiveAttr, myID, attr1, attr2, array;
@synthesize retrieve, send, local, decode, encode, parent, badRetrieve;
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

@interface TNSRPropertyCollection : GHTestCase
@end
@implementation TNSRPropertyCollection

#define NSRInitTestClass(customProperties) [[NSRPropertyCollection alloc] initWithClass:[TestClass class] syncString:customProperties customConfig:nil]

- (void) test_invalid_sync_params
{
	GHAssertNoThrow(NSRInitTestClass(@"attr1,\nattr2"), @"Shouldn't crash if newline in the middle");

	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"primitiveAttr"), NSException, NSRailsSyncException, @"Should crash if a primitive attribute was defined in NSRailsSync");
	
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"remoteID=id, myID=id"), NSException, NSRailsSyncException, @"Should crash if trying to set a property to ID equiv in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"remoteID=id, myID=id -r"), @"Shouldn't crash for setting a property to ID -r only");
	
	GHAssertNoThrow(NSRInitTestClass(@"nonexistent"), @"Shouldn't crash if trying to set a nonexistent property in NSRS");
	
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"attr1=hello, attr2=hello"), NSException, NSRailsSyncException, @"Should crash if trying to set two properties to the same rails equiv in NSRS");
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"attr1=hello -r, attr2=hello, myID=hello"), NSException, NSRailsSyncException, @"Should crash if trying to set two sendable properties to the same rails equiv in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"attr1=hello -r, attr2=hello"), @"Shouldn't crash if two properties are set to the same rails equiv in NSRS, but only one is sendable");
	
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"array"), NSException, NSRailsSyncException, @"Should crash without class to fill array");
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"array:FakeClass"), NSException, NSRailsSyncException, @"Should crash without real class to fill array");
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"array:BadResponse"), NSException, NSRailsSyncException, @"Should crash because class exists but doesn't inherit from NSRM");
	GHAssertNoThrow(NSRInitTestClass(@"array:"), @"Shouldn't crash when defaulting to NSDictionaries");
}

- (void) test_property_flags
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"sendretrieve -rs, nothing, retrieve=rails -r, send -s, local -x, decode -d, encode -e, parent -b, encodedecode -ed, nestedNothing, objc=rails, nestedExplicit:TestClass, nestedArrayNothing=nestedArrayNothing:, nestedArrayExplicit:TestClass" 
																customConfig:nil];
	
	NSRAssertEqualArraysNoOrder(pc.propertyEquivalents.allKeys, NSRArray(@"sendretrieve", @"nothing", @"retrieve", @"send", @"decode", @"encode", @"parent", @"nestedNothing", @"nestedExplicit", @"nestedArrayNothing", @"nestedArrayExplicit", @"encodedecode", @"objc"));
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
	
	NSRAssertEqualArraysNoOrder(pc.retrievableProperties, NSRArray(@"sendretrieve", @"nothing", @"retrieve", @"decode", @"encode", @"parent", @"nestedNothing", @"nestedExplicit", @"nestedArrayNothing", @"nestedArrayExplicit", @"encodedecode", @"objc"));
	NSRAssertEqualArraysNoOrder(pc.sendableProperties, NSRArray(@"sendretrieve", @"nothing", @"send", @"decode", @"encode", @"parent", @"nestedNothing", @"nestedExplicit", @"nestedArrayNothing", @"nestedArrayExplicit", @"encodedecode", @"objc"));
	GHAssertEqualObjects(pc.decodeProperties, NSRArray(@"decode", @"encodedecode"), @"");
	GHAssertEqualObjects(pc.encodeProperties, NSRArray(@"encode", @"encodedecode"), @"");
	
	GHAssertTrue([pc propertyIsMarkedBelongsTo:@"parent"], @"parent should be marked belongs-to (-b included)");
	GHAssertFalse([pc propertyIsMarkedBelongsTo:@"nestedNothing"], @"nestedNothing shouldn't be marked belongs-to (no -b)");
	
	GHAssertEqualStrings([pc.nestedModelProperties objectForKey:@"nestedNothing"], @"TestClass", @"Should automatically pick up class of nestedNothing");
	GHAssertEqualStrings([pc.nestedModelProperties objectForKey:@"nestedExplicit"], @"TestClass", @"Should pick up class of nestedNothing");

	GHAssertNil([pc.nestedModelProperties objectForKey:@"nestedArrayNothing"], @"Should automatically use dictionaries for array nestedArrayNothing");
	GHAssertEqualStrings([pc.nestedModelProperties objectForKey:@"nestedArrayExplicit"], @"TestClass", @"Should pick up explicit assc of nestedArrayNothing");
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