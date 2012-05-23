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
@property (nonatomic, strong) NSArray *nestedArrayExplicit, *nestedArrayExplicitM, *nestedArrayM, *nestedArrayNothing, *dateArray;
@property (nonatomic, strong) TestClass *nestedExplicit, *nestedNothing, *parent;
@end

@implementation FlagTestClass
@synthesize sendretrieve, nothing, retrieve, send, local, decode, encode, sendOnly, parent, encodedecode, objc, date, fakeDate;
@synthesize nestedNothing, nestedExplicit, nestedArrayNothing, nestedArrayExplicit, dateArray, nestedArrayExplicitM, nestedArrayM;
@end

@interface TNSRPropertyCollection : SenTestCase
@end
@implementation TNSRPropertyCollection

#define NSRInitTestClass(customProperties)\
[[NSRPropertyCollection alloc] initWithClass:[TestClass class] syncString:customProperties customConfig:nil]

#define NSRThrowsSyncException(exp, desc) \
STAssertThrowsSpecificNamed(exp, NSException, NSRailsSyncException, desc)


- (void) test_invalid_sync_params
{
	STAssertNoThrow(NSRInitTestClass(@"attr1,\nattr2"), @"Shouldn't crash if newline in the middle");
	
	// Syntax (needs more)
	
	NSRThrowsSyncException(NSRInitTestClass(@"primitiveAttr -r:NSDate"), @"Syntax");
	NSRThrowsSyncException(NSRInitTestClass(@"primitiveAttr -r =hi :-"), @"Syntax");
	
	// Attributes, equivalents, send/retrieve
	
	NSRThrowsSyncException(NSRInitTestClass(@"primitiveAttr"), @"Should crash if a primitive attribute was defined in NSRailsSync");
	STAssertNoThrow(NSRInitTestClass(@"nonexistent"), @"Shouldn't crash if trying to set a nonexistent property in NSRS");
	STAssertNoThrow(NSRInitTestClass(@"attr1="), @"Shouldn't crash for setting a property to exact name (just =)");
		
	NSRThrowsSyncException(NSRInitTestClass(@"remoteID=id, myID=id"), @"Should crash if trying to set a property to ID equiv in NSRS");
	STAssertNoThrow(NSRInitTestClass(@"remoteID=id, myID=id -r"), @"Shouldn't crash for setting a property to ID -r only");
	
	NSRThrowsSyncException(NSRInitTestClass(@"attr1=hello, attr2=hello"), @"Should crash if trying to set two properties to the same rails equiv in NSRS");
	NSRThrowsSyncException(NSRInitTestClass(@"attr1=hello -r, attr2=hello, myID=hello"), @"Should crash if trying to set two sendable properties to the same rails equiv in NSRS");
	STAssertNoThrow(NSRInitTestClass(@"attr1=hello -r, attr2=hello"), @"Shouldn't crash if two properties are set to the same rails equiv in NSRS, but only one is sendable");

	// Nesting
	
	STAssertNoThrow(NSRInitTestClass(@"array"), @"Should be fine without class to fill array (dicts), just deliver warning");
	STAssertNoThrow(NSRInitTestClass(@"array -m"), @"Should be fine without class to fill array (dicts)");
	NSRThrowsSyncException(NSRInitTestClass(@"attr1:"), @"Should crash if no nesting class declared");
	NSRThrowsSyncException(NSRInitTestClass(@"attr1: -m"), @"Should crash if no nesting class declared");
	
	NSRThrowsSyncException(NSRInitTestClass(@"array:FakeClass"), @"Should crash without real class to fill array");
	NSRThrowsSyncException(NSRInitTestClass(@"array:BadResponse"), @"Should crash because class exists but doesn't inherit from NSRM");
}

- (void) test_property_detection
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"nothing, local -x, nonexistent" 
																customConfig:nil];
	
	NSRAssertEqualArraysNoOrder(pc.properties.allKeys, NSRArray(@"nothing", @"nonexistent"));
	
	STAssertTrue([pc objcPropertiesForRemoteEquivalent:@"notdeclared" autoinflect:NO].count == 0, @"Shouldn't pick up any remotes called notdeclared");
}

- (void) test_encode_decode
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"decode -d, encode -e, encodedecode -ed" 
																customConfig:nil];
	
	NSRProperty *decode = [pc.properties objectForKey:@"decode"];
	STAssertTrue(decode.decodable, @"decode should be marked decodable");
	
	NSRProperty *encode = [pc.properties objectForKey:@"encode"];
	STAssertTrue(encode.encodable, @"encode should be marked encodable");
	
	NSRProperty *encodedecode = [pc.properties objectForKey:@"encodedecode"];
	STAssertTrue(encodedecode.encodable, @"encodedecode should be marked encodable");
	STAssertTrue(encodedecode.decodable, @"encodedecode should be marked encodable");
}

- (void) test_send_receive
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"sendretrieve -rs, nothing, retrieve -r, send -s" 
																customConfig:nil];

	NSRProperty *sendretrieve = [pc.properties objectForKey:@"sendretrieve"];
	STAssertTrue(sendretrieve.retrievable, @"sendretrieve should be marked retrievable");
	STAssertTrue(sendretrieve.sendable, @"sendretrieve should be marked sendable");

	NSRProperty *nothing = [pc.properties objectForKey:@"nothing"];
	STAssertTrue(nothing.retrievable, @"nothing should be marked retrievable");
	STAssertTrue(nothing.sendable, @"nothing should be marked sendable");

	NSRProperty *retrieve = [pc.properties objectForKey:@"retrieve"];
	STAssertTrue(retrieve.retrievable, @"retrieve should be marked retrievable");

	NSRProperty *send = [pc.properties objectForKey:@"send"];
	STAssertTrue(send.sendable, @"send should be marked sendable");

	NSMutableArray *sendableAsStrings = [NSMutableArray array];
	for (NSRProperty *p in pc.properties.allValues)
		if (p.sendable)
			[sendableAsStrings addObject:p.name];
	
	NSRAssertEqualArraysNoOrder(sendableAsStrings, NSRArray(@"sendretrieve", @"nothing", @"send"));
}

- (void) test_equivalents
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"objc=rails_prop -r, objcTWO=rails_prop, pleaseInflect" 
																customConfig:nil];

	STAssertEqualObjects([[pc.properties objectForKey:@"objc"] remoteEquivalent], @"rails_prop", @"Prop should pick up =");
	STAssertEqualObjects([[pc.properties objectForKey:@"objcTWO"] remoteEquivalent], @"rails_prop", @"Prop should pick up =");
	STAssertNil([[pc.properties objectForKey:@"pleaseInflect"] remoteEquivalent], @"Prop should pick up no =");
	
	STAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"rails_prop" autoinflect:NO] containsObject:[pc.properties objectForKey:@"objc"]], @"Should pick up that remote rails_prop is defined as objc");
	STAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"rails_prop" autoinflect:NO] containsObject:[pc.properties objectForKey:@"objcTWO"]], @"Should pick up that remote rails_prop is also defined as objcTWO");

	STAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"rails_prop" autoinflect:YES] containsObject:[pc.properties objectForKey:@"objc"]], @"Should pick up that remote rails_prop is defined as objc, even if ai");
	STAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"rails_prop" autoinflect:YES] containsObject:[pc.properties objectForKey:@"objcTWO"]], @"Should pick up that remote rails_prop is also defined as objcTWO, even if ai");

	STAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"pleaseInflect" autoinflect:NO] containsObject:[pc.properties objectForKey:@"pleaseInflect"]], @"Should pick up pleaseInflect if no ai");
	STAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"pleaseInflect" autoinflect:YES] containsObject:[pc.properties objectForKey:@"pleaseInflect"]], @"Should pick up pleaseInflect even if ai");
	
	STAssertFalse([[pc objcPropertiesForRemoteEquivalent:@"please_inflect" autoinflect:NO] containsObject:[pc.properties objectForKey:@"pleaseInflect"]], @"Should not pick up please_inflect if no ai");
	STAssertTrue([[pc objcPropertiesForRemoteEquivalent:@"please_inflect" autoinflect:YES] containsObject:[pc.properties objectForKey:@"pleaseInflect"]], @"Should pick up please_inflect as pleaseInflect if ai");
}

- (void) test_dates
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"date, fakeDate:NSDate, dateArray:NSDate, dateArrayExplicit:NSDate -m" 
																customConfig:nil];
	NSRProperty *date = [pc.properties objectForKey:@"date"];
	STAssertFalse(date.isHasMany, @"date shouldn't be seen as array");
	STAssertFalse(date.isBelongsTo, @"date shouldn't be seen as belongs-to");
	STAssertTrue(date.isDate, @"date should be seen as date");
	STAssertNil(date.nestedClass, @"date should not be marked as nested class");
	
	NSRProperty *fakeDate = [pc.properties objectForKey:@"fakeDate"];
	STAssertFalse(date.isHasMany, @"fakeDate shouldn't be seen as array");
	STAssertFalse(date.isBelongsTo, @"fakeDate shouldn't be seen as belongs-to");
	STAssertTrue(date.isDate, @"fakedate should be seen as date, even if string");
	STAssertNil(date.nestedClass, @"fakeDate should not be marked as nested class");
	
	NSRProperty *dateArray = [pc.properties objectForKey:@"dateArray"];
	STAssertTrue(dateArray.isHasMany, @"dateArray should be seen as array");
	STAssertFalse(dateArray.isBelongsTo, @"dateArray shouldn't be seen as belongs-to");
	STAssertFalse(dateArray.isDate, @"dateArray shouldn't be seen as date");
	STAssertEqualObjects(dateArray.nestedClass, @"NSDate", @"dateArray should have NSDate as nested class");

	NSRProperty *dateArrayExplicit = [pc.properties objectForKey:@"dateArrayExplicit"];
	STAssertTrue(dateArrayExplicit.isHasMany, @"dateArrayExplicit should be seen as array");
	STAssertFalse(dateArrayExplicit.isBelongsTo, @"dateArrayExplicit shouldn't be seen as belongs-to");
	STAssertFalse(dateArrayExplicit.isDate, @"dateArrayExplicit shouldn't be seen as date");
	STAssertEqualObjects(dateArrayExplicit.nestedClass, @"NSDate", @"dateArrayExplicit should have NSDate as nested class");
}

- (void) test_nesting_flags
{
	NSRPropertyCollection *pc = [[NSRPropertyCollection alloc] initWithClass:[FlagTestClass class]
																  syncString:@"nestedNothing, nestedExplicit:TestClass, nestedArrayNothing, nestedArrayM -m, nestedArrayExplicit:TestClass, nestedArrayExplicitM:TestClass -m"
																customConfig:nil];
	
	

	NSRProperty *nestedNothing = [pc.properties objectForKey:@"nestedNothing"];
	STAssertFalse(nestedNothing.isBelongsTo, @"nestedNothing shouldn't be marked belongs-to (no -b)");
	STAssertFalse(nestedNothing.isHasMany, @"nestedNothing shouldn't be marked has-many");
	STAssertEqualObjects(nestedNothing.nestedClass, @"TestClass", @"nestedNothing's nested class should be TestClass");

	NSRProperty *nestedExplicit = [pc.properties objectForKey:@"nestedExplicit"];
	STAssertFalse(nestedExplicit.isBelongsTo, @"nestedExplicit shouldn't be marked belongs-to (no -b)");
	STAssertFalse(nestedExplicit.isHasMany, @"nestedExplicit shouldn't be marked as has-many");
	STAssertEqualObjects(nestedExplicit.nestedClass, @"TestClass", @"nestedNothing's nested class should be TestClass");

	NSRProperty *nestedArrayM = [pc.properties objectForKey:@"nestedArrayM"];
	STAssertFalse(nestedArrayM.isBelongsTo, @"nestedArrayM shouldn't be marked belongs-to");
	STAssertTrue(nestedArrayM.isHasMany, @"nestedArrayM was explicitly marked -m, should be h-m");
	STAssertNil(nestedArrayM.nestedClass, @"nestedArrayM's nested class should be nil (dicts)");

	NSRProperty *nestedArrayNothing = [pc.properties objectForKey:@"nestedArrayNothing"];
	STAssertFalse(nestedArrayNothing.isBelongsTo, @"nestedArrayNothing shouldn't be marked belongs-to");
	STAssertFalse(nestedArrayNothing.isHasMany, @"nestedArrayNothing is an array but shouldn't be seen as has-many");
	STAssertNil(nestedArrayNothing.nestedClass, @"nestedArrayNothing's nested class should be nil (it's just an array left alone)");

	NSRProperty *nestedArrayExplicit = [pc.properties objectForKey:@"nestedArrayExplicit"];
	STAssertFalse(nestedArrayExplicit.isBelongsTo, @"nestedArrayExplicit shouldn't be marked belongs-to");
	STAssertTrue(nestedArrayExplicit.isHasMany, @"nestedArrayExplicit should be seen as implicit has-many");
	STAssertEqualObjects(nestedArrayExplicit.nestedClass, @"TestClass", @"nestedArrayExplicit's nested class should be TestClass");

	NSRProperty *nestedArrayExplicitM = [pc.properties objectForKey:@"nestedArrayExplicitM"];
	STAssertFalse(nestedArrayExplicitM.isBelongsTo, @"nestedArrayExplicit shouldn't be marked belongs-to");
	STAssertTrue(nestedArrayExplicitM.isHasMany, @"nestedArrayExplicit should be seen as explicit has-many");
	STAssertEqualObjects(nestedArrayExplicitM.nestedClass, @"TestClass", @"nestedArrayExplicit's nested class should be TestClass");
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