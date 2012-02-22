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
#import "TestPostClass.h"

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
	TestPostClass *post = [TestPostClass remoteObjectWithID:1 error:&e];
	
	GHAssertNotNil(e, @"Should fail on no app URL set in config, where's the error?");
	GHAssertNil(post, @"Post should be nil because no connection could be made");
	
	e = nil;
	
	/////////////////
	//TEST READ ALL
	
	//point app to localhost as it should be, but no authentication to test
	[[NSRConfig defaultConfig] setAppURL:@"localhost:3000"];
	
	NSArray *allPeople = [TestPostClass remoteAll:&e];

	GHAssertNotNil(e, @"Should fail on not authenticated, where's the error?");
	GHAssertNil(allPeople, @"Array should be nil because there was an authentication error");
	
	e = nil;
	
	//add authentication
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	allPeople = [TestPostClass remoteAll:&e];

	//if error, and it's NSURL domain, must be that the server isn't running
	if ([[e domain] isEqualToString:@"NSURLErrorDomain"])
	{
		GHFail(@"It doesn't look like you're running the demo Rails app. This makes the CRUD tests useless. To set up the test DB: 'cd demo/server; rake db:create db:migrate'. To run the app: 'rails s'");
	}
	
	GHAssertNil(e, @"remoteAll on Post should have worked.'");
	GHAssertNotNil(allPeople, @"No errors, allPeople should not be nil.");

	e = nil;
	
	/////////////////
	//TEST READ BY ID
	
	//try to retrieve ID = -1, obviously error
	post = [TestPostClass remoteObjectWithID:-1 error:&e];
	
	GHAssertNotNil(e, @"Obviously no one with ID -1, where's the error?");
	GHAssertNil(post, @"There was an error on remoteObjectWithID, post should be nil.");
	
	e = nil;
	
	/////////////////
	//TEST CREATE
		
	//this should fail on validation b/c no author
	TestPostClass *failedPost = [[TestPostClass alloc] init];
	failedPost.author = @"Fail";
	[failedPost remoteCreate:&e];
	
	GHAssertNotNil(e, @"Post should have failed validation b/c no body... where is error?");
	GHAssertNotNil(failedPost, @"Post did fail but object should not be nil.");
	GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"There was an error by validation, so validation error dictionary should be present.");
	
	e = nil;

	//this should go through
	TestPostClass *newPost = [[TestPostClass alloc] init];
	newPost.author = @"Dan";
	newPost.body = @"Test";
	[newPost remoteCreate:&e];
	
	GHAssertNil(e, @"New post should've been created fine, there should be no error.");
	GHAssertNotNil(newPost.modelID, @"New post was just created, modelID shouldn't be nil.");
	GHAssertNotNil(newPost.railsAttributes, @"New post was just created, railsAttributes shouldn't be nil.");
	
	e = nil;
	
	/////////////////
	//TEST READ BY ID (again)
	
	TestPostClass *retrievedPost = [TestPostClass remoteObjectWithID:[newPost.modelID integerValue] error:&e];
	
	GHAssertNil(e, @"Retrieving post we just made, should be no errors.");
	GHAssertNotNil(retrievedPost, @"No errors retrieving post we just made, he should not be nil.");
	GHAssertEqualObjects(retrievedPost.modelID, newPost.modelID, @"Retrieved post should have same modelID as created post");
	
	e = nil;

	/////////////////
	//TEST UPDATE
	
	//update should go through
	newPost.author = @"Dan 2";
	[newPost remoteUpdate:&e];
	
	GHAssertNil(e, @"Update should've gone through, there should be no error");
	
	e = nil;

	NSNumber *postID = newPost.modelID;
	newPost.modelID = nil;
	[newPost remoteUpdate:&e];
	
	//test to see that it'll fail on trying to update instance with nil ID
	GHAssertNotNil(e, @"Tried to update an instance with a nil ID, where's the error?");
	newPost.modelID = postID;
	
	e = nil;
	
	//update should fail validation b/c no author
	newPost.author = nil;
	[newPost remoteUpdate:&e];

	GHAssertNotNil(e, @"New post should've failed, there should be an error.");
	GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"There was an error by validation, so validation error dictionary should be present.");
	GHAssertNil(newPost.author, @"New author failed validation (unchanged) but it should still be nil locally.");
	
	e = nil;
	
	///////////////////////
	//TEST READ (RETRIVE)
	
	[newPost remoteGetLatest:&e];
	
	GHAssertNil(e, @"Should be no error retrieving a value.");
	//see if it correctly set the info on the server (still there after failed validation) to overwrite the local author (set to nil)
	GHAssertNotNil(newPost.author, @"New post should have gotten back his old author after validation failed (on the retrieve).");

	e = nil;
	
	//see if there's an error if trying to retrieve with a nil ID
	newPost.modelID = nil;
	[newPost remoteGetLatest:&e];

	GHAssertNotNil(e, @"Tried to retrieve an instance with a nil ID, where's the error?");
	
	e = nil;
	
	///////////////////////
	//TEST DESTROY
	
	//test trying to destroy instance with nil ID
	[newPost remoteDestroy:&e];
	GHAssertNotNil(e, @"Tried to delete an instance with a nil ID, where's the error?");
	newPost.modelID = postID;

	e = nil;
	
	//should work
	[newPost remoteDestroy:&e];
	GHAssertNil(e, @"Deleting new post should have worked, but got back an error.");
	
	e = nil;
	
	//should get back an error cause there shouldn't be a post with its ID anymore
	[newPost remoteDestroy:&e];
	GHAssertNotNil(e, @"Deleting new post for a second time shouldn't have worked, where's the error?");
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