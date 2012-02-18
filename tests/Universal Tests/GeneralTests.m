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

@interface GeneralTests : GHTestCase
@end

@implementation GeneralTests

- (void) test_invalid_railsify
{
	NSRAssertClassProperties(@"modelID, attr1", [TestClass class]);
}

- (void) test_nested_config_contexts
{
	[[NSRConfig defaultConfig] setAppURL:@"http://Default"];
	
	NSRAssertRelevantConfigURL(@"http://Default",nil);
	
	[[NSRConfig defaultConfig] useIn:^
	 {
		 NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"http://Nested"];
		 [c use];
		 
		 NSRAssertRelevantConfigURL(@"http://Nested", nil);

		 [[NSRConfig defaultConfig] useIn:^
		  {
			  NSRAssertRelevantConfigURL(@"http://Default", nil);

			  [c useIn:^
			  {
				  NSRAssertRelevantConfigURL(@"http://Nested", nil);
			  }];
		  }];
		 
		 [c end];
		 
		 NSRAssertRelevantConfigURL(@"http://Default", nil);
	 }];
	
	GHAssertEqualStrings(@"test_class", [TestClass getModelName], @"auto-underscoring");

	NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"http://NoAuto"];
	c.automaticallyUnderscoreAndCamelize = NO;
	[c useIn:
	 ^{
		 NSRAssertRelevantConfigURL(@"http://NoAuto", nil);

		 GHAssertEqualStrings(@"TestClass", [TestClass getModelName], @"No auto-underscoring");
	 }];
	
	NSRAssertRelevantConfigURL(@"http://Default", nil);
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