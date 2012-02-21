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
#import "TestPersonClass.h"

@interface GeneralTests : GHTestCase
@end

@implementation GeneralTests

- (void) test_invalid_sync
{
	NSRAssertClassProperties(@"modelID, attr1", [TestClass class]);
}

- (void) test_nested_config_contexts
{
	[[NSRConfig defaultConfig] setAppURL:@"http://Default/"]; //also tests to see that it'll get rid of the /
	
	NSRAssertRelevantConfigURL(@"http://Default",nil);
	
	[[NSRConfig defaultConfig] useIn:^
	 {
		 NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"Nested"]; //also tests to see that it'll add http://
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

	NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"NoAuto/"]; //also tests to see that it'll add http:// and remove the /
	c.automaticallyUnderscoreAndCamelize = NO;
	[c useIn:
	 ^{
		 NSRAssertRelevantConfigURL(@"http://NoAuto", nil);

		 GHAssertEqualStrings(@"TestClass", [TestClass getModelName], @"No auto-underscoring");
	 }];
	
	NSRAssertRelevantConfigURL(@"http://Default", nil);
}

- (void) test_crud
{
	///////////////////
	//TEST NIL APP URL
	
	//point app to nil at first to test
	[[NSRConfig defaultConfig] setAppURL:nil];	
	
	NSError *e;
	TestPersonClass *person = [TestPersonClass getRemoteObjectWithID:1 error:&e];
	
	GHAssertNotNil(e, @"Should fail on no app URL set in config, where's the error?");
	GHAssertNil(person, @"Person should be nil because no connection could be made");
	
	e = nil;
	
	/////////////////
	//TEST READ ALL
	
	//point app to localhost as it should be
	[[NSRConfig defaultConfig] setAppURL:@"localhost:3000"];
	
	NSArray *allPeople = [TestPersonClass getAllRemote:&e];
	
	//must be that the server isn't running
	if ([[e domain] isEqualToString:@"NSURLErrorDomain"])
	{
		GHFail(@"It doesn't look like you're running the demo Rails app. This makes the CRUD tests useless. To set up the test DB: 'cd demo/server; rake db:create db:migrate'. To run the app: 'rails s'");
	}
	
	GHAssertNil(e, @"getAllRemote on Person should have worked.'");
	GHAssertNotNil(allPeople, @"No errors, allPeople should not be nil.");

	e = nil;
	
	/////////////////
	//TEST READ BY ID
	
	//try to retrieve ID = -1, obviously error
	person = [TestPersonClass getRemoteObjectWithID:-1 error:&e];
	
	GHAssertNotNil(e, @"Obviously no one with ID -1, where's the error?");
	GHAssertNil(person, @"There was an error on getRemoteObjectWithID, person should be nil.");
	
	e = nil;
	
	/////////////////
	//TEST CREATE
		
	//this should fail on validation b/c no name
	TestPersonClass *failedPerson = [[TestPersonClass alloc] init];
	failedPerson.age = [NSNumber numberWithInt:10];
	[failedPerson createRemote:&e];
	
	GHAssertNotNil(e, @"Person should have failed validation b/c no name... where is error?");
	GHAssertNotNil(failedPerson, @"Person did fail but object should not be nil.");
	GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"There was an error by validation, so validation error dictionary should be present.");
	
	e = nil;

	//this should go through
	TestPersonClass *newPerson = [[TestPersonClass alloc] init];
	newPerson.name = @"Name";
	newPerson.age = [NSNumber numberWithInt:10];
	[newPerson createRemote:&e];
	
	GHAssertNil(e, @"New person should've been created fine, there should be no error.");
	GHAssertNotNil(newPerson.modelID, @"New person was just created, modelID shouldn't be nil.");
	GHAssertNotNil(newPerson.railsAttributes, @"New person was just created, railsAttributes shouldn't be nil.");
	
	e = nil;
	
	/////////////////
	//TEST READ BY ID (again)
	
	TestPersonClass *retrievedPerson = [TestPersonClass getRemoteObjectWithID:[newPerson.modelID integerValue] error:&e];
	
	GHAssertNil(e, @"Retrieving person we just made, should be no errors.");
	GHAssertNotNil(retrievedPerson, @"No errors retrieving person we just made, he should not be nil.");
	GHAssertEqualObjects(retrievedPerson.modelID, newPerson.modelID, @"Retrieved person should have same modelID as created person");
	
	e = nil;

	/////////////////
	//TEST UPDATE
	
	//update should go through
	newPerson.name = @"Name 2";
	[newPerson updateRemote:&e];
	
	GHAssertNil(e, @"Update should've gone through, there should be no error");
	
	e = nil;

	NSNumber *personID = newPerson.modelID;
	newPerson.modelID = nil;
	[newPerson updateRemote:&e];
	
	//test to see that it'll fail on trying to update instance with nil ID
	GHAssertNotNil(e, @"Tried to update an instance with a nil ID, where's the error?");
	newPerson.modelID = personID;
	
	e = nil;
	
	//update should fail validation b/c no name
	newPerson.name = nil;
	[newPerson updateRemote:&e];

	GHAssertNotNil(e, @"New person should've failed, there should be an error.");
	GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"There was an error by validation, so validation error dictionary should be present.");
	GHAssertNil(newPerson.name, @"New name failed validation (unchanged) but it should still be nil locally.");
	
	e = nil;
	
	///////////////////////
	//TEST READ (RETRIVE)
	
	[newPerson getRemoteLatest:&e];
	
	GHAssertNil(e, @"Should be no error retrieving a value.");
	//see if it correctly set the info on the server (still there after failed validation) to overwrite the local name (set to nil)
	GHAssertNotNil(newPerson.name, @"New person should have gotten back his old name after validation failed (on the retrieve).");

	e = nil;
	
	//see if there's an error if trying to retrieve with a nil ID
	newPerson.modelID = nil;
	[newPerson getRemoteLatest:&e];

	GHAssertNotNil(e, @"Tried to retrieve an instance with a nil ID, where's the error?");
	
	e = nil;
	
	///////////////////////
	//TEST DESTROY
	
	//test trying to destroy instance with nil ID
	[newPerson destroyRemote:&e];
	GHAssertNotNil(e, @"Tried to delete an instance with a nil ID, where's the error?");
	newPerson.modelID = personID;

	e = nil;
	
	//should work
	[newPerson destroyRemote:&e];
	GHAssertNil(e, @"Deleting new person should have worked, but got back an error.");
	
	e = nil;
	
	//should get back an error cause there shouldn't be a person with its ID anymore
	[newPerson destroyRemote:&e];
	GHAssertNotNil(e, @"Deleting new person for a second time shouldn't have worked, where's the error?");
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