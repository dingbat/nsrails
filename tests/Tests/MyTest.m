//
//  MyTest.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h> 
#import "NSRConfig.h"

#import "STChild.h"
#import "STGrandchild.h"

@interface MyTest : GHTestCase { }
@end

@implementation MyTest

- (void) testSubclassing
{
	//Looking at logs... I know this isn't the best way to do tests but until I can think of a better way manual it is...
	STGrandchild *child = [[STGrandchild alloc] init];
	
	GHAssertTrue(1+1==2, @"yep");
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