//
//  UniversalTests.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//
 
#import "NSRAsserts.h"

#import "InheritanceTestClasses.h"
#import "NestingTestClasses.h"
#import "TestClass.h"

@interface GeneralTests : GHTestCase
@end

@implementation GeneralTests

- (void) test_invalid_sync_params
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
	
	NSError *e = nil;
	Post *post = [Post remoteObjectWithID:1 error:&e];
	
	GHAssertNotNil(e, @"Should fail on no app URL set in config, where's the error?");
	GHAssertNil(post, @"Post should be nil because no connection could be made");
	
	e = nil;
	
	/////////////////
	//TEST READ ALL
	
	//point app to localhost as it should be, but no authentication to test
	[[NSRConfig defaultConfig] setAppURL:@"localhost:3000"];
	[[NSRConfig defaultConfig] setAppUsername:nil];
	[[NSRConfig defaultConfig] setAppPassword:nil];
	
	NSArray *allPeople = [Post remoteAll:&e];

	GHAssertNotNil(e, @"Should fail on not authenticated, where's the error?");
	GHAssertNil(allPeople, @"Array should be nil because there was an authentication error");
	
	e = nil;
	
	//add authentication
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	allPeople = [Post remoteAll:&e];

	//if error, and it's NSURL domain, must be that the server isn't running
	if ([[e domain] isEqualToString:@"NSURLErrorDomain"])
	{
		NSString *title = @"Server not running";
		NSString *text = @"It doesn't look the test Rails app is running locally. The CRUD and nesting tests can't run without it.\n\nTo run the app:\n\"$ cd demo/nsrails.com; rails s\".\nIf your DB isn't set up:\n\"$ rake db:migrate\".";
		
#if TARGET_OS_IPHONE
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
#else
		NSAlert *alert = [NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:text];
		[alert runModal];
#endif
		
		GHFail(@"Test app not running. Run 'rails s'.");
	}
	
	GHAssertNil(e, @"remoteAll on Post should have worked.'");
	GHAssertNotNil(allPeople, @"No errors, allPeople should not be nil.");

	e = nil;
	
	/////////////////
	//TEST READ BY ID
	
	//try to retrieve ID = -1, obviously error
	post = [Post remoteObjectWithID:-1 error:&e];
	
	GHAssertNotNil(e, @"Obviously no one with ID -1, where's the error?");
	GHAssertNil(post, @"There was an error on remoteObjectWithID, post should be nil.");
	
	e = nil;
	
	/////////////////
	//TEST CREATE
		
	//this should fail on validation b/c no author
	Post *failedPost = [[Post alloc] init];
	failedPost.author = @"Fail";
	[failedPost remoteCreate:&e];
	
	GHAssertNotNil(e, @"Post should have failed validation b/c no body... where is error?");
	GHAssertNotNil(failedPost, @"Post did fail but object should not be nil.");
	GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"There was an error by validation, so validation error dictionary should be present.");
	
	e = nil;

	//this should go through
	Post *newPost = [[Post alloc] init];
	newPost.author = @"Dan";
	newPost.body = @"Test";
	[newPost remoteCreate:&e];
	
	GHAssertNil(e, @"New post should've been created fine, there should be no error.");
	GHAssertNotNil(newPost.modelID, @"New post was just created, modelID shouldn't be nil.");
	GHAssertNotNil(newPost.remoteAttributes, @"New post was just created, remoteAttributes shouldn't be nil.");
	
	e = nil;
	
	/////////////////
	//TEST READ BY ID (again)
	
	Post *retrievedPost = [Post remoteObjectWithID:[newPost.modelID integerValue] error:&e];
	
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

- (void) test_nesting
{
	Post *post = [[Post alloc] init];
	post.author = @"Dan";
	post.body = @"Test";
	post.responses = nil;
	
	NSError *e = nil;
	
	[post remoteCreate:&e];
	
	GHAssertNil(e, @"Creating post (with nil responses) shouldn't have resulted in an error.");
	GHAssertNotNil(post.responses, @"Created a post with nil responses array, should have an empty array on return.");
	
	e = nil;
	
	post.responses = [NSMutableArray array];
	[post remoteUpdate:&e];
	
	GHAssertNil(e, @"Creating post (with empty responses) shouldn't have resulted in an error.");
	GHAssertNotNil(post.responses, @"Made an empty responses array, array should exist on return.");
	GHAssertTrue(post.responses.count == 0, @"Made an empty responses array, array should be empty on return.");
	
	e = nil;
	
	Response *response = [[Response alloc] init];
	[post.responses addObject:response];
	
	[post remoteUpdate:&e];
	
	GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"Should've been a validation error in sending reponse without body/author.");
	GHAssertTrue(post.responses.count == 1, @"Local array should still have response even though wasn't created properly.");
	GHAssertNotNil(response, @"Validation failed on nested create but local object should still be there (external)");
	
	e = nil;
	
	response.body = @"Response body";
	response.author = @"Response author";
	
	[post remoteUpdate:&e];
	
	GHAssertNil(e, @"There should be no error nesting Response creation");
	GHAssertTrue(post.responses.count == 1, @"Local responses array should still have response (created properly).");
	GHAssertNotNil(response, @"Local Response object should still be here (created properly)");

	e = nil;
	
	//now try retrieving post and see if modelID exists
	Post *retrievedPost = [Post remoteObjectWithID:post.modelID.integerValue error:&e];
	GHAssertNil(e, @"There should be no errors in post retrieval");
	GHAssertTrue(retrievedPost.responses.count == 1, @"The retrieved post should have one response (we just made it)");
	GHAssertNotNil([[retrievedPost.responses objectAtIndex:0] modelID], @"The response inside post's response should have a present modelID (we just made it)");
	
	NSNumber *responseID = response.modelID;
	response.destroyOnNesting = YES;
	[post remoteUpdate:&e];

	GHAssertNil(e, @"There should be no error nesting Response deletion");
	GHAssertTrue(post.responses.count == 1, @"Local responses array should still have response (deleted properly).");
	GHAssertNotNil(response, @"Local Response object should still be here (deleted properly)");
	
	e = nil;
	
	Response *retrieveResponse = [Response remoteObjectWithID:[responseID integerValue] error:&e];
	GHAssertNotNil(e, @"Response object should've been nest-deleted, where's the error in retrieving it?");

	e = nil;
	
	//test nest-creation via RESPONSE-side, meaning we set its post variable (this should fail without the -b flag)
	Response *newResponse = [[Response alloc] init];
	newResponse.body = @"Test";
	newResponse.author = @"Test";
	newResponse.post = post;
	
	[newResponse remoteCreate:&e];
	GHAssertNotNil(e, @"Tried to send Rails a 'post_attributes' key in belongs_to association, where's the error?");
	GHAssertNil(newResponse.modelID, @"newResponse's ID should be nil - there was an error in create.");

	e = nil;
	
	//now try with -b flag
	Response *belongsTo = [[Response alloc] initWithRailsSyncProperties:@"*, post -b"];
	belongsTo.body = @"Test";
	belongsTo.author = @"Test";
	belongsTo.post = post;
	
	[belongsTo remoteCreate:&e];
	
	GHAssertNil(e, @"There should be no error with sending response marked with 'belongs_to' - 'post_id' should've been used instead of _attributes");
	GHAssertNotNil(belongsTo.modelID, @"belongsTo response's ID should exist - there was no error in create.");
	
	e = nil;
	
	[belongsTo remoteGetLatest:&e];
	
	GHAssertNil(e, @"There should be no error in retrieving response.");
	GHAssertEqualObjects(belongsTo.post.modelID, post.modelID, @"The Post modelID coming from the newly created Response should be the same as the post object under which we made it.");
	
	e = nil;
	
	[belongsTo remoteDestroy:&e];	
	GHAssertNil(e, @"Response object should've been destroyed fine (nothing to do with nesting, just cleaning up)");
	
	e = nil;
	
	[post remoteDestroy:&e];	
	GHAssertNil(e, @"Post object should've been destroyed fine (nothing to do with nesting, just cleaning up)");
	
	e = nil;
	
	for (int i = 0; i < 4; i++)
	{
		/////////////
		//test with unreliable NSRailsSync strings
		
		
		//in all of these cases (besides the last), sending will work fine (cause the Response object is in the array), but retrieving should return NSDictionaries.
		
		NSString *sync = @"*, responses:TheResponseClass"; //won't be able to find class 'TheResponseClass' (will log warning)
		if (i == 1)
			sync = @"*, responses:"; //explicitly defined to use NSDictionaries (all OK)
		if (i == 2)
			sync = @"*, responses"; //no nested model definition - will use NSDictionaries (will log warning)
		if (i == 3)
			sync = @"*, responses:BadResponse"; //won't work at all, since BadResponse doesnt inherit from NSRM
		
		Post *missingClassPost = [[Post alloc] initWithRailsSyncProperties:sync];
		missingClassPost.author = @"author";
		missingClassPost.body = @"body";
		missingClassPost.responses = [NSMutableArray array];
		
		Response *testResponse;
		if (i == 3)
			testResponse = (Response *)[[BadResponse alloc] init];
		else
			testResponse = [[Response alloc] init];
		testResponse.author = @"Test";
		testResponse.body = @"Test";
		
		[missingClassPost.responses addObject:testResponse];
		
		[missingClassPost remoteCreate:&e];
		GHAssertNil(e, @"Should be no error, even though can't find class Response");
		GHAssertNotNil(missingClassPost.modelID, @"Model ID should be present if there was no error on create...");
		
		e = nil;
		
		//BadResponse run (doesn't inherit from NSRailsModel)
		if (i == 3)
		{
			GHAssertTrue(missingClassPost.responses.count == 0, @"BadResponse shouldn't have been sent since it's not an NSRailsModel subclass");
		}
		else
		{
			//All of these runs should make NSRails assume to use NSDictionaries
			
			GHAssertTrue(missingClassPost.responses.count == 1, @"Should have one response returned from Post create");
			
			//now, as the retrieve part of the create, it won't know what to stick in the array and put NSDictionaries in instead
			GHAssertTrue([[missingClassPost.responses objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Couldn't find what to put into the array, so should've filled it with NSDictionaries. Got %@ instead",NSStringFromClass([[missingClassPost.responses objectAtIndex:0] class]));
						
			//same applies for retrieve
			[missingClassPost remoteGetLatest:&e];
			GHAssertNil(e, @"There should've been no errors on the retrieve, even if no nested model defined.");
			GHAssertTrue(missingClassPost.responses.count == 1, @"Should still come back with one response");
			GHAssertTrue([[missingClassPost.responses objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Couldn't find what to put into the array, so should've filled it with NSDictionaries. Got %@ instead",NSStringFromClass([[missingClassPost.responses objectAtIndex:0] class]));
			
			e = nil;
			
			//testResponse will fail destroy
			[testResponse remoteDestroy:&e];	
			GHAssertNotNil(e, @"testResponse object was never set an ID (since the retrieve only returned dictionaries), so it should fail destroy.");
			
			e = nil;
			
			//now, let's manually add it from the dictionary and destroy
			testResponse.modelID = [[missingClassPost.responses objectAtIndex:0] objectForKey:@"id"];
			[testResponse remoteDestroy:&e];	
			GHAssertNil(e, @"testResponse object should've been destroyed fine after manually setting ID from dictionary (nothing to do with nesting, just cleaning up)");
			
			e = nil;
		}
		
		[missingClassPost remoteDestroy:&e];	
		GHAssertNil(e, @"Post object should've been destroyed fine (nothing to do with nesting, just cleaning up)");
		
		e = nil;
	}
}

- (void) test_custom_requests
{
	////////
	//root
	NSString *rootAction = [NSRailsModel routeForControllerRoute:@"action"];
	GHAssertEqualStrings(rootAction, @"action", @"Root route failed");	
	
	
	/////////////////////
	//controller (class)
	NSString *getAll = [Post routeForControllerRoute:nil];
	GHAssertEqualStrings(getAll, @"posts", @"Nil controller route failed");
	
	NSString *controllerAction = [Post routeForControllerRoute:@"action"];
	GHAssertEqualStrings(controllerAction, @"posts/action", @"Controller route failed");
	
	
	////////////
	//instance
	Post *post = [[Post alloc] init];
	
	NSError *e = nil;
	
	//should fail, since post has nil ID
	NSString *failure = [post routeForInstanceRoute:nil error:&e];
	GHAssertNotNil(e, @"Should have been an error when trying to get an instance route on instance with nil modelID");
	GHAssertNil(failure, @"Route should be nil when there was an error forming it (no modelID for instance)");
	
	post.modelID = [NSNumber numberWithInt:1];
	
	e = nil;
	
	NSString *get = [post routeForInstanceRoute:nil error:&e];
	GHAssertNil(e, @"Route should have been formed correctly - modelID is present");
	GHAssertEqualStrings(get, @"posts/1", @"Nil instance route failed");
	
	e = nil;
	
	NSString *instanceAction = [post routeForInstanceRoute:@"action" error:&e];
	GHAssertNil(e, @"Route should have been formed correctly - modelID is present");
	GHAssertEqualStrings(instanceAction, @"posts/1/action", @"Instance route failed");
}

- (void)setUpClass {
	// Run at start of all tests in the class
}

- (void)tearDownClass {
	// Run at end of all tests in the class
}

- (void)setUp
{
	// Run before each test method
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000/"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
}

- (void)tearDown {
	// Run after each test method
} 

@end