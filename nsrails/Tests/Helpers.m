//
//  Helpers.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface TheMansFather : NSRRemoteObject
@property (nonatomic, strong) NSString *parent;
@end

@implementation TheMansFather
@synthesize parent;
@end

@interface TheManInsideMe : TheMansFather
{
	NSString *private;
}

@property (nonatomic, strong, setter=setTheString:) NSString *string;
@property (nonatomic, strong, getter=getDate) NSDate *date;
@property (nonatomic, strong) NSArray *array;
@property (nonatomic, strong) id anything;
@property (nonatomic) int primitiveInt;
@property (nonatomic) BOOL primitiveBOOL;
@property (nonatomic) float primitiveFloat;
@property NSStringEncoding encoding;
@property CGRect rect;

@end

@implementation TheManInsideMe
@synthesize string, date, anything, primitiveInt, primitiveBOOL, primitiveFloat, encoding, rect;
@dynamic array; //dynamic just for kicks
@end


@interface ASuperclass : NSRRemoteObject
+ (NSString *) something;
- (NSString *) something;
@end

@implementation ASuperclass

+ (NSString *) something
{
	return @"super";
}

- (NSString *) something
{
	return @"super";
}

@end

@interface AClass : ASuperclass
@end

@implementation AClass
@end

@interface ASubclass : AClass
+ (NSString *) something;
- (NSString *) something;
@end
@implementation ASubclass

+ (NSString *) something
{
	return @"sub";
}

- (NSString *) something
{
	return @"sub";
}

@end

@interface NSRProperty (NSRInflection)

+ (NSString *) camelizedString:(NSString *)string;
+ (NSString *) underscoredString:(NSString *)string stripPrefix:(BOOL)stripPrefix;

@end

#define NSRAssertEqualsUnderscored(string, underscored, strip) STAssertEqualObjects([NSRProperty underscoredString:string stripPrefix:strip], underscored, nil)
#define NSRAssertEqualsCamelized(string, camelized) STAssertEqualObjects([NSRProperty camelizedString:string], camelized, nil)

@interface THelpers : SenTestCase
@end

@implementation THelpers

- (void) test_inflection
{
	NSRAssertEqualsUnderscored(@"p", @"p", NO);
	NSRAssertEqualsUnderscored(@"post", @"post", NO);
	NSRAssertEqualsUnderscored(@"Post", @"post", NO);
	NSRAssertEqualsUnderscored(@"POST", @"post", NO);
	NSRAssertEqualsUnderscored(@"DHPost", @"dh_post", NO);
	NSRAssertEqualsUnderscored(@"postObject", @"post_object", NO);
	NSRAssertEqualsUnderscored(@"postObjectA", @"post_object_a", NO);
	NSRAssertEqualsUnderscored(@"postObjectAB", @"post_object_ab", NO);
	NSRAssertEqualsUnderscored(@"postObjectABCSomething", @"post_object_abc_something", NO);
	NSRAssertEqualsUnderscored(@"post_object", @"post_object", NO);
	NSRAssertEqualsUnderscored(@"post_Object", @"post_object", NO);

	NSRAssertEqualsUnderscored(@"post", @"post", YES);
	NSRAssertEqualsUnderscored(@"Post", @"post", YES);
	NSRAssertEqualsUnderscored(@"DPost", @"post", YES);
	NSRAssertEqualsUnderscored(@"DHPost", @"post", YES);
	NSRAssertEqualsUnderscored(@"DHpost", @"hpost", YES);
	NSRAssertEqualsUnderscored(@"PostDH", @"post_dh", YES);
	NSRAssertEqualsUnderscored(@"DHPostDH", @"post_dh", YES);

	NSRAssertEqualsCamelized(@"p", @"p");
	NSRAssertEqualsCamelized(@"post", @"post");
	NSRAssertEqualsCamelized(@"Post", @"Post");
	NSRAssertEqualsCamelized(@"post_object", @"postObject");
	NSRAssertEqualsCamelized(@"post_object_id", @"postObjectID");
	NSRAssertEqualsCamelized(@"post_object_ids", @"postObjectIDs");
	NSRAssertEqualsCamelized(@"post_object_idx", @"postObjectIdx");
	NSRAssertEqualsCamelized(@"post_object_abc", @"postObjectAbc");
	NSRAssertEqualsCamelized(@"post_object_ABC", @"postObjectABC");
	NSRAssertEqualsCamelized(@"post_object_ABC_something", @"postObjectABCSomething");
	NSRAssertEqualsCamelized(@"post__object", @"postObject");
	NSRAssertEqualsCamelized(@"postOBject", @"postOBject");
	NSRAssertEqualsCamelized(@"postObject", @"postObject");
}

- (void) test_introspection
{
	NSRAssertEqualArraysNoOrder([TheManInsideMe allProperties], NSRArray(@"string", @"date", @"array", @"anything", @"primitiveInt", @"primitiveBOOL", @"primitiveFloat", @"encoding", @"rect"));

	STAssertNil([TheManInsideMe typeForProperty:@"unknown"], @"Introspection should not pick up non-existent properties");
	STAssertNil([TheManInsideMe typeForProperty:@"private"], @"Introspection should not pick up non-property ivars");
	STAssertEqualObjects([TheManInsideMe typeForProperty:@"parent"], @"NSString", @"Introspection should pick up superclasses' props");
	STAssertEqualObjects([TheManInsideMe typeForProperty:@"string"], @"NSString", @"");
	STAssertEqualObjects([TheManInsideMe typeForProperty:@"date"], @"NSDate", @"");
	STAssertEqualObjects([TheManInsideMe typeForProperty:@"array"], @"NSArray", @"");
	STAssertEqualObjects([TheManInsideMe typeForProperty:@"anything"], @"", @"");
	
	//non-object returns are undefined, but something will be returned
	STAssertNotNil([TheManInsideMe typeForProperty:@"primitiveInt"],@"");
	STAssertNotNil([TheManInsideMe typeForProperty:@"primitiveBOOL"],@"");
	STAssertNotNil([TheManInsideMe typeForProperty:@"primitiveFloat"],@"");
	STAssertNotNil([TheManInsideMe typeForProperty:@"encoding"],@"");
	STAssertNotNil([TheManInsideMe typeForProperty:@"rect"],@"");
}

- (void) test_noclimb
{
	SEL sel = @selector(something);
	
	STAssertEqualObjects([ASuperclass performSelectorWithoutClimbingHierarchy:sel], @"super",@"");
	STAssertTrue([ASuperclass respondsToSelectorWithoutClimbingHierarchy:sel], @"");

	STAssertNil([AClass performSelectorWithoutClimbingHierarchy:sel],@"");
	STAssertFalse([AClass respondsToSelectorWithoutClimbingHierarchy:sel], @"");

	STAssertEqualObjects([ASubclass performSelectorWithoutClimbingHierarchy:sel], @"sub",@"");
	STAssertTrue([ASubclass respondsToSelectorWithoutClimbingHierarchy:sel], @"");
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