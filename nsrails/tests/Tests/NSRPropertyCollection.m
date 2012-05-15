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
@implementation TestClassParent
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

@implementation TestClass
@synthesize primitiveAttr, myID, attr1, attr2, array;
@synthesize retrieve, send, local, decode, encode, parent, badRetrieve;
@end

@interface FlagTestClass : NSRailsModel
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *sendretrieve, *nothing, *retrieve, *send, *local, *decode, *encode, *sendOnly, *encodedecode, *objc, *fakeDate;
@property (nonatomic, strong) NSArray *nestedArrayExplicit, *nestedArrayNothing, *dateArray;
@property (nonatomic, strong) TestClass *nestedExplicit, *nestedNothing, *parent;
@end

@implementation FlagTestClass
@synthesize sendretrieve, nothing, retrieve, send, local, decode, encode, sendOnly, parent, encodedecode, objc, date, fakeDate;
@synthesize nestedNothing, nestedExplicit, nestedArrayNothing, nestedArrayExplicit, dateArray;
@end

@interface TNSRPropertyCollection : GHTestCase
@end
@implementation TNSRPropertyCollection

#define NSRInitTestClass(customProperties) [[NSRPropertyCollection alloc] initWithClass:[TestClass class] syncString:customProperties customConfig:nil]

- (void) test_invalid_sync_params
{
	GHAssertNoThrow(NSRInitTestClass(@"attr1,\nattr2"), @"Shouldn't crash if newline in the middle");

	// Attributes, equivalents, send/retrieve
	
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"primitiveAttr"), NSException, NSRailsSyncException, @"Should crash if a primitive attribute was defined in NSRailsSync");
	GHAssertNoThrow(NSRInitTestClass(@"nonexistent"), @"Shouldn't crash if trying to set a nonexistent property in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"attr1="), @"Shouldn't crash for setting a property to exact name (just =)");
		
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"remoteID=id, myID=id"), NSException, NSRailsSyncException, @"Should crash if trying to set a property to ID equiv in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"remoteID=id, myID=id -r"), @"Shouldn't crash for setting a property to ID -r only");
	
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"attr1=hello, attr2=hello"), NSException, NSRailsSyncException, @"Should crash if trying to set two properties to the same rails equiv in NSRS");
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"attr1=hello -r, attr2=hello, myID=hello"), NSException, NSRailsSyncException, @"Should crash if trying to set two sendable properties to the same rails equiv in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"attr1=hello -r, attr2=hello"), @"Shouldn't crash if two properties are set to the same rails equiv in NSRS, but only one is sendable");

	// Nesting
	
	GHAssertNoThrow(NSRInitTestClass(@"array"), @"Should be fine without class to fill array (dicts), just deliver warning");
	GHAssertNoThrow(NSRInitTestClass(@"array -m"), @"Should be fine without class to fill array (dicts)");
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"attr1:"), NSException, NSRailsSyncException, @"Should crash if no nesting class declared");
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"attr1: -m"), NSException, NSRailsSyncException, @"Should crash if no nesting class declared");
	
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"array:FakeClass"), NSException, NSRailsSyncException, @"Should crash without real class to fill array");
	GHAssertThrowsSpecificNamed(NSRInitTestClass(@"array:BadResponse"), NSException, NSRailsSyncException, @"Should crash because class exists but doesn't inherit from NSRM");
}

- (void) test_property_flags
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"sendretrieve -rs, nothing, retrieve=rails -r, send -s, local -x, decode -d, encode -e, parent -b, encodedecode -ed, nestedNothing, objc=rails, nestedExplicit:TestClass, nestedArrayNothing=nestedArrayNothing, nestedArrayExplicit:TestClass -m, date, fakeDate:NSDate, dateArray:NSDate -m" 
																customConfig:nil];
	
	NSRAssertEqualArraysNoOrder(pc.properties.allKeys, NSRArray(@"sendretrieve", @"date", @"fakeDate", @"dateArray", @"nothing", @"retrieve", @"send", @"decode", @"encode", @"parent", @"nestedNothing", @"nestedExplicit", @"nestedArrayNothing", @"nestedArrayExplicit", @"encodedecode", @"objc"));
	
	GHAssertTrue([pc objcPropertiesForRemoteEquivalent:@"nonexistent" autoinflect:NO].count == 0, @"Shouldn't pick up any remotes called nonexistent");

	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"rails" autoinflect:NO] containsObject:[pc.properties objectForKey:@"retrieve"]], @"Should pick up that remote rails is defined as retrieve");
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"rails" autoinflect:NO] containsObject:[pc.properties objectForKey:@"objc"]], @"Should pick up that remote rails is also defined as objc");

	GHAssertTrue([pc objcPropertiesForRemoteEquivalent:@"nested_explicit" autoinflect:NO].count == 0, @"Should fail trying to find nested_explicit property in objc (nothing explicit and not autoinflecting)");
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"nested_explicit" autoinflect:YES] containsObject:[pc.properties objectForKey:@"nestedExplicit"]], @"Should find default autoinflected nestedExplicit from nested_explicit");
	
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"nestedArrayNothing" autoinflect:NO] containsObject:[pc.properties objectForKey:@"nestedArrayNothing"]], @"Should return the explicit equivalency (even if no autoinflect)");
	GHAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"nestedArrayNothing" autoinflect:YES] containsObject:[pc.properties objectForKey:@"nestedArrayNothing"]], @"Should return the explicit equivalency (even if autoinflect)");

	NSRProperty *objc = [pc.properties objectForKey:@"objc"];
	GHAssertEqualStrings([objc remoteEquivalentAutoinflection:NO], @"rails", @"Should return explicit equiv");
	GHAssertEqualStrings([objc remoteEquivalentAutoinflection:YES], @"rails", @"Should return explicit equiv (even if autoinflect)");
	
	NSRProperty *nestedExplicit = [pc.properties objectForKey:@"nestedExplicit"];
	GHAssertEqualStrings([nestedExplicit remoteEquivalentAutoinflection:NO], @"nestedExplicit", @"Should return non-autoinflected default string (identical)");
	GHAssertEqualStrings([nestedExplicit remoteEquivalentAutoinflection:YES], @"nested_explicit", @"Should return autoinflected default string (default)");

	NSRProperty *nestedArrayNothing = [pc.properties objectForKey:@"nestedArrayNothing"];
	GHAssertEqualStrings([nestedArrayNothing remoteEquivalentAutoinflection:NO], @"nestedArrayNothing", @"Should return the explicit equivalency (even if no-autoinflect)");
	GHAssertEqualStrings([nestedArrayNothing remoteEquivalentAutoinflection:YES], @"nestedArrayNothing", @"Should return the explicit equivalency (even if autoinflect)");
	
	NSMutableArray *sendableStrings = [NSMutableArray array];
	for (NSRProperty *p in pc.sendableProperties)
		[sendableStrings addObject:p.name];
	
	NSRAssertEqualArraysNoOrder(sendableStrings, NSRArray(@"sendretrieve", @"nothing", @"send", @"decode", @"encode", @"parent", @"nestedNothing", @"nestedExplicit", @"nestedArrayNothing", @"nestedArrayExplicit", @"encodedecode", @"objc", @"date", @"fakeDate", @"dateArray"));
	
	NSRProperty *decode = [pc.properties objectForKey:@"decode"];
	GHAssertTrue(decode.decodable, @"decode should be marked decodable");
	
	NSRProperty *encode = [pc.properties objectForKey:@"encode"];
	GHAssertTrue(encode.encodable, @"encode should be marked encodable");

	NSRProperty *encodedecode = [pc.properties objectForKey:@"encodedecode"];
	GHAssertTrue(encodedecode.encodable, @"encodedecode should be marked encodable");
	GHAssertTrue(encodedecode.decodable, @"encodedecode should be marked encodable");

	NSRProperty *parent = [pc.properties objectForKey:@"parent"];
	GHAssertTrue(parent.isBelongsTo, @"parent should be marked belongs-to (-b included)");
	GHAssertFalse(parent.isHasMany, @"parent shouldn't be marked has-many");
	GHAssertEqualStrings(parent.nestedClass, @"TestClass", @"parent's nested class should be TestClass");

	NSRProperty *nestedNothing = [pc.properties objectForKey:@"nestedNothing"];
	GHAssertFalse(nestedNothing.isBelongsTo, @"nestedNothing shouldn't be marked belongs-to (no -b)");
	GHAssertFalse(nestedNothing.isHasMany, @"nestedNothing shouldn't be marked has-many");
	GHAssertEqualStrings(nestedNothing.nestedClass, @"TestClass", @"nestedNothing's nested class should be TestClass");

	GHAssertFalse(nestedExplicit.isBelongsTo, @"nestedExplicit shouldn't be marked belongs-to (no -b)");
	GHAssertFalse(nestedExplicit.isHasMany, @"nestedExplicit shouldn't be marked as has-many");
	GHAssertEqualStrings(nestedExplicit.nestedClass, @"TestClass", @"nestedNothing's nested class should be TestClass");

	NSRProperty *nestedArrayExplicit = [pc.properties objectForKey:@"nestedArrayExplicit"];
	GHAssertFalse(nestedExplicit.isBelongsTo, @"nestedArrayExplicit shouldn't be marked belongs-to");
	GHAssertTrue(nestedArrayExplicit.isHasMany, @"nestedArrayExplicit should be seen as array");
	GHAssertEqualStrings(nestedArrayExplicit.nestedClass, @"TestClass", @"nestedArrayExplicit's nested class should be TestClass");
	
	GHAssertFalse(nestedArrayNothing.isBelongsTo, @"nestedArrayNothing shouldn't be marked belongs-to");
	GHAssertTrue(nestedArrayNothing.isHasMany, @"nestedArrayNothing should be seen as array");
	GHAssertNil(nestedArrayNothing.nestedClass, @"nestedArrayNothing's nested class should be nil (dicts)");

	
	NSRProperty *date = [pc.properties objectForKey:@"date"];
	GHAssertFalse(date.isHasMany, @"date shouldn't be seen as array");
	GHAssertFalse(date.isBelongsTo, @"date shouldn't be seen as belongs-to");
	GHAssertTrue(date.isDate, @"date should be seen as date");
	GHAssertNil(date.nestedClass, @"date should not be marked as nested class");

	NSRProperty *fakeDate = [pc.properties objectForKey:@"fakeDate"];
	GHAssertFalse(date.isHasMany, @"fakeDate shouldn't be seen as array");
	GHAssertFalse(date.isBelongsTo, @"fakeDate shouldn't be seen as belongs-to");
	GHAssertTrue(date.isDate, @"fakedate should be seen as date, even if string");
	GHAssertNil(date.nestedClass, @"fakeDate should not be marked as nested class");

	NSRProperty *dateArray = [pc.properties objectForKey:@"dateArray"];
	GHAssertTrue(dateArray.isHasMany, @"dateArray should be seen as array");
	GHAssertFalse(dateArray.isBelongsTo, @"dateArray shouldn't be seen as belongs-to");
	GHAssertFalse(dateArray.isDate, @"dateArray shouldn't be seen as date");
	GHAssertEqualStrings(dateArray.nestedClass, @"NSDate", @"dateArray should have NSDate as nested class");
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