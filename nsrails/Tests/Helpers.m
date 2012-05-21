//
//  Helpers.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface TheMansFather : NSObject
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

#define NSRAssertEqualsUnderscored(string, underscored) STAssertEqualObjects([string underscore], underscored, nil)
#define NSRAssertEqualsCamelized(string, camelized) STAssertEqualObjects([string camelize], camelized, nil)

@interface THelpers : SenTestCase
@end

@implementation THelpers

- (void) test_inflection
{
	NSRAssertEqualsUnderscored(@"post", @"post");
	NSRAssertEqualsUnderscored(@"Post", @"post");
	NSRAssertEqualsUnderscored(@"POST", @"post");
	NSRAssertEqualsUnderscored(@"DHPost", @"dh_post");
	NSRAssertEqualsUnderscored(@"postObject", @"post_object");
	NSRAssertEqualsUnderscored(@"postObjectA", @"post_object_a");
	NSRAssertEqualsUnderscored(@"postObjectAB", @"post_object_ab");
	NSRAssertEqualsUnderscored(@"postObjectABCSomething", @"post_object_abc_something");
	NSRAssertEqualsUnderscored(@"post_object", @"post_object");
	NSRAssertEqualsUnderscored(@"post_Object", @"post_object");
	
	STAssertEqualObjects([@"post" underscoreIgnorePrefix:YES], @"post", nil);
	STAssertEqualObjects([@"Post" underscoreIgnorePrefix:YES], @"post", nil);
	STAssertEqualObjects([@"DPost" underscoreIgnorePrefix:YES], @"post", nil);
	STAssertEqualObjects([@"DHPost" underscoreIgnorePrefix:YES], @"post", nil);
	STAssertEqualObjects([@"PostDH" underscoreIgnorePrefix:YES], @"post_dh", nil);
	STAssertEqualObjects([@"DHPostDH" underscoreIgnorePrefix:YES], @"post_dh", nil);
	
	NSRAssertEqualsCamelized(@"post", @"post");
	NSRAssertEqualsCamelized(@"Post", @"Post");
	NSRAssertEqualsCamelized(@"post_object", @"postObject");
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
	STAssertEqualObjects([TheManInsideMe typeForProperty:@"anything"], @"id", @"");
	
	//non-object returns are undefined, but something will be returned
	STAssertNotNil([TheManInsideMe typeForProperty:@"primitiveInt"],@"");
	STAssertNotNil([TheManInsideMe typeForProperty:@"primitiveBOOL"],@"");
	STAssertNotNil([TheManInsideMe typeForProperty:@"primitiveFloat"],@"");
	STAssertNotNil([TheManInsideMe typeForProperty:@"encoding"],@"");
	STAssertNotNil([TheManInsideMe typeForProperty:@"rect"],@"");

	BOOL primitive = YES;
	[TheManInsideMe typeForProperty:@"string" isPrimitive:&primitive];
	STAssertFalse(primitive, @"NSString is not primitive");

	[TheManInsideMe typeForProperty:@"anything" isPrimitive:&primitive];
	STAssertFalse(primitive, @"id is not primitive");

	[TheManInsideMe typeForProperty:@"primitiveInt" isPrimitive:&primitive];
	STAssertTrue(primitive, @"int is primitive");

	[TheManInsideMe typeForProperty:@"encoding" isPrimitive:&primitive];
	STAssertTrue(primitive, @"encoding is primitive");

	[TheManInsideMe typeForProperty:@"rect" isPrimitive:&primitive];
	STAssertTrue(primitive, @"rect is primitive");

	STAssertEqualObjects(NSStringFromSelector([TheManInsideMe setterForProperty:@"string"]), @"setTheString:", @"");	
	STAssertEqualObjects(NSStringFromSelector([TheManInsideMe setterForProperty:@"date"]), @"setDate:", @"");	
	STAssertEqualObjects(NSStringFromSelector([TheManInsideMe setterForProperty:@"array"]), @"setArray:", @"");	

	STAssertEqualObjects(NSStringFromSelector([TheManInsideMe getterForProperty:@"string"]), @"string", @"");	
	STAssertEqualObjects(NSStringFromSelector([TheManInsideMe getterForProperty:@"date"]), @"getDate", @"");	
	STAssertEqualObjects(NSStringFromSelector([TheManInsideMe getterForProperty:@"array"]), @"array", @"");	
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