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
#import "TestClasses.h"

@interface GeneralTests : GHTestCase
{
	BOOL noServer;
}
@end

@implementation GeneralTests

#define NSRInitTestClass(customProperties) [[TestClass alloc] initWithCustomSyncProperties:customProperties]

- (void) test_invalid_sync_params
{
	GHAssertThrows(NSRInitTestClass(@"f8a asufoj as;lfkas [pfl;aksm jofaskf oasa"), @"Should've failed random mash");

	GHAssertNoThrow(NSRInitTestClass(@"attr1,\nattr2"), @"Shouldn't crash if newline in the middle");

	GHAssertThrows(NSRInitTestClass(@"primitiveAttr"), @"Should crash if a primitive attribute was defined in NSRailsSync");
	
	GHAssertThrows(NSRInitTestClass(@"remoteID -x"), @"Should crash if trying to modify remoteID in NSRS");
	GHAssertThrows(NSRInitTestClass(@"myID=id"), @"Should crash if trying to set a property to ID equiv in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"myID=id -r"), @"Shouldn't crash for setting a property to ID -r only");
	
	GHAssertThrows(NSRInitTestClass(@"nonexistent"), @"Should crash if trying to set a nonexistent property in NSRS");
	
	GHAssertThrows(NSRInitTestClass(@"attr1=hello, attr2=hello"), @"Should crash if trying to set two properties to the same rails equiv in NSRS");
	GHAssertThrows(NSRInitTestClass(@"attr1=hello -r, attr2=hello, myID=hello"), @"Should crash if trying to set two sendable properties to the same rails equiv in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"attr1=hello -r, attr2=hello"), @"Shouldn't crash if two properties are set to the same rails equiv in NSRS, but only one is sendable");
	
	GHAssertThrows(NSRInitTestClass(@"badRetrieve"), @"Should crash if trying to set a retrievable property without a getter in NSRS");
	GHAssertNoThrow(NSRInitTestClass(@"badRetrieve -s"), @"Shouldn't crash if trying to set a sendable property without a getter in NSRS");

	GHAssertThrows(NSRInitTestClass(@"array"), @"Should crash without class to fill array");
	GHAssertThrows(NSRInitTestClass(@"array:FakeClass"), @"Should crash without real class to fill array");
	GHAssertThrows(NSRInitTestClass(@"array:BadResponse"), @"Should crash because class exists but doesn't inherit from NSRM");
	GHAssertNoThrow(NSRInitTestClass(@"array:"), @"Shouldn't crash when defaulting to NSDictionaries");
}

- (void) test_no_rails_sync
{
	NSRAssertClassProperties([ClassWithNoRailsSync class], @"remoteID", @"attribute");
}

- (void) test_property_flags
{
	TestClass *c = [[TestClass alloc] initWithCustomSyncProperties:@"retrieve -r, send -s, local -x, decode -d, encode -e, parent -b"];
	NSRPropertyCollection *pc = [c propertyCollection];
	
	NSRAssertEqualArrays(pc.retrievableProperties, @"remoteID", @"retrieve", @"decode", @"encode", @"parent");
	NSRAssertEqualArrays(pc.sendableProperties, @"remoteID", @"send", @"decode", @"encode", @"parent");
	NSRAssertEqualArrays(pc.decodeProperties, @"decode");
	NSRAssertEqualArrays(pc.encodeProperties, @"encode");
	
	c.encode = @"encode"; //should capitalize it

	NSDictionary *sendDict = [c dictionaryOfRemoteProperties];
	GHAssertNil([sendDict objectForKey:@"retrieve"], @"Retrieve was defined as -r only, should not be in send dict");
	GHAssertNil([sendDict objectForKey:@"local"], @"Local was defined as -x, should not be in send dict");
	GHAssertEqualStrings([sendDict objectForKey:@"encode"], [c.encode uppercaseString], @"Encode method failed");
	GHAssertTrue([sendDict objectForKey:@"parent"] == [NSNull null], @"Even if belongs_to, should've sent nil if prop is nil");
	
	c.parent = [[TestClassParent alloc] init];
	GHAssertNotNil([[c dictionaryOfRemoteProperties] objectForKey:@"parent_attributes"], @"'parent_attributes' should've been set, not _id");
	GHAssertNil([[c dictionaryOfRemoteProperties] objectForKey:@"parent"], @"'parent' shouldn't been set, since it's not nil (should be _attributes)");

	c.parent.remoteID = [NSNumber numberWithInt:5];
	GHAssertTrue([[[c dictionaryOfRemoteProperties] objectForKey:@"parent_id"] intValue] == 5, @"parent_id should've been set, to 5");
	GHAssertNil([[c dictionaryOfRemoteProperties] objectForKey:@"parent_attributes"], @"'parent_attributes' shouldn't have been set, since it has an id");
	GHAssertNil([[c dictionaryOfRemoteProperties] objectForKey:@"parent"], @"'parent' shouldn't been set, since it's not nil (should be _attributes)");

	NSMutableDictionary *remoteReturn = [[NSMutableDictionary alloc] init];
	[remoteReturn setObject:@"DECODE" forKey:@"decode"];
	[remoteReturn setObject:@"xxxxx" forKey:@"send"];
	[remoteReturn setObject:@"xxxxx" forKey:@"local"];
	[remoteReturn setObject:@"retrieve" forKey:@"retrieve"];
	[remoteReturn setObject:@"ENCODE" forKey:@"encode"];
	
	[c setPropertiesUsingRemoteDictionary:remoteReturn];
	GHAssertNil(c.send, @"Sendable-only property shouldn't have been set");
	GHAssertNil(c.local, @"Local-only property shouldn't have been set");
	GHAssertEqualStrings(c.decode, @"decode", @"Decodable property should've been downcased");
	GHAssertEqualStrings(c.retrieve, @"retrieve", @"Retrievable property should've been set");
	GHAssertEqualStrings(c.encode, @"ENCODE", @"Encodable-only property should've been untouched");
}

- (void) test_config_environments
{
	[NSRConfig resetConfigs];
	
	NSRConfig *defaultDev = [NSRConfig defaultConfig];
	GHAssertNotNil(defaultDev, @"Calling defaultConfig should generate config if nil");
	
	[[NSRConfig defaultConfig] setAppURL:@"Default"];
	NSRAssertRelevantConfigURL(@"Default", nil);
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentDevelopment, @"Should've set default to dev environment");
	
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentProduction];
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Should've set environment to Prod");
	GHAssertNil([NSRConfig defaultConfig].appURL, @"App URL for Prod environment never set, should be nil.");
	
	[[NSRConfig defaultConfig] setAppURL:@"Prod"];
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Environment should still be Prod from before");
	NSRAssertRelevantConfigURL(@"Prod", @"Default URL set while in Prod, should have stuck");
	
	NSRConfig *testConfig = [NSRConfig configForEnvironment:@"test"];
	testConfig.appURL = @"TestURL";
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentProduction, @"Environment still be Prod");
	NSRAssertRelevantConfigURL(@"Prod", @"Default URL set while in Prod, should have stuck");
	GHAssertNotNil(testConfig, @"Calling configForEnvironment: should generate a new config if non-existent");
	
	[NSRConfig setCurrentEnvironment:@"test"];
	GHAssertEqualStrings([NSRConfig currentEnvironment], @"test", @"Environment should be test");
	NSRAssertRelevantConfigURL(@"TestURL", @"Default URL should be one set for test");
	
	NSRConfig *newProd = [[NSRConfig alloc] initWithAppURL:@"NewProdURL"];
	[NSRConfig setConfig:newProd asDefaultForEnvironment:NSRConfigEnvironmentProduction];
	GHAssertEqualStrings([NSRConfig currentEnvironment], @"test", @"Environment should still be test");
	NSRAssertRelevantConfigURL(@"TestURL", @"Default URL should be one set for test");
	NSRAssertEqualConfigs([NSRConfig configForEnvironment:NSRConfigEnvironmentProduction], @"NewProdURL", @"Production environment config should change after overwriting its default", nil);
	
	//set it default for current env too (test)
	[NSRConfig setConfigAsDefault:newProd];
	NSRAssertRelevantConfigURL(@"NewProdURL", @"Default URL should be the new one set for prod");
	
	[NSRConfig setCurrentEnvironment:NSRConfigEnvironmentDevelopment];
	GHAssertEqualStrings([NSRConfig currentEnvironment], NSRConfigEnvironmentDevelopment, @"Environment should have been set to Dev");
	NSRAssertRelevantConfigURL(@"Default", @"Default URL should be one set for Dev");
}

- (void) test_config_nested_contexts
{
	[[NSRConfig defaultConfig] setAppURL:@"http://Default/"]; //also tests to see that it'll get rid of the /
	
	NSRAssertRelevantConfigURL(@"Default", @"default, exterior before nesting");
	
	[[NSRConfig defaultConfig] useIn:^
	 {
		 NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"Nested"]; //also tests to see that it'll add http://
		 [c use];
		 
		 NSRAssertRelevantConfigURL(@"Nested", @"[use] nested inside of default block");
		 
		 [[NSRConfig defaultConfig] useIn:^
		  {
			  NSRAssertRelevantConfigURL(@"Default", @"default block nested inside [use] inside default block");
			  
			  [c useIn:^
			   {
				   NSRAssertRelevantConfigURL(@"Nested", @"triple nested");
			   }];
		  }];
		 
		 [c end];
		 
		 NSRAssertRelevantConfigURL(@"Default", @"default at the end of default block after nestings");
	 }];
	
	GHAssertEqualStrings(@"class_with_no_rails_sync", [ClassWithNoRailsSync getModelName], @"auto-underscoring");
	
	NSRConfig *c = [[NSRConfig alloc] initWithAppURL:@"NoAuto/"]; //also tests to see that it'll add http:// and remove the /
	c.autoInflectsNamesAndProperties = NO;
	[c useIn:
	 ^{
		 NSRAssertRelevantConfigURL(@"NoAuto", @"custom block ^{} block");
		 
		 GHAssertEqualStrings(@"ClassWithNoRailsSync", [ClassWithNoRailsSync getModelName], @"No auto-underscoring");
	 }];
	
	NSRAssertRelevantConfigURL(@"Default", @"default exterior after all nesting");
}

- (void) test_crud_async
{
	GHAssertFalse(noServer, @"Test app not running. Run 'rails s'.");
	
	/////////////////
	//TEST READ ALL
	
	[[NSRConfig defaultConfig] setAppURL:@"localhost:3000"];
	
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	[Post remoteAllAsync:^(NSArray *allPeople, NSError *error) 
	{
		GHAssertNil(error, @"ASYNC remoteAll on Post should have worked.'");
		GHAssertNotNil(allPeople, @"ASYNC No errors, allPeople should not be nil.");
	}];
	
	
	/////////////////
	//TEST READ BY ID
	
	//try to retrieve ID = -1, obviously error
	[Post remoteObjectWithID:-1 async:^(id post, NSError *error) {
		GHAssertNotNil(error, @"ASYNC Obviously no one with ID -1, where's the error?");
		GHAssertNil(post, @"ASYNC There was an error on remoteObjectWithID, post should be nil.");
	}];
	
	
	/////////////////
	//TEST CREATE
	
	//this should fail on validation b/c no author
	Post *failedPost = [[Post alloc] init];
	failedPost.author = @"Fail";
	[failedPost remoteCreateAsync:^(NSError *e) {
		GHAssertNotNil(e, @"ASYNC Post should have failed validation b/c no content... where is error?");
		GHAssertNotNil(failedPost, @"ASYNC Post did fail but object should not be nil.");
		GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"ASYNC There was an error by validation, so validation error dictionary should be present.");
	}];
	
	//this should go through
	Post *newPost = [[Post alloc] init];
	newPost.author = @"Dan";
	newPost.content = @"Async Test";
	[newPost remoteCreateAsync:^(NSError *e) {
		GHAssertNil(e, @"ASYNC New post should've been created fine, there should be no error.");
		GHAssertNotNil(newPost.remoteID, @"ASYNC New post was just created, remoteID shouldn't be nil.");
		GHAssertNotNil(newPost.remoteAttributes, @"ASYNC New post was just created, remoteAttributes shouldn't be nil.");
		
		/////////////////
		//TEST READ BY ID (again)
		
		[Post remoteObjectWithID:[newPost.remoteID integerValue] async:^(id retrievedPost, NSError *e2) {
			GHAssertNil(e2, @"ASYNC Retrieving post we just made, should be no errors.");
			GHAssertNotNil(retrievedPost, @"ASYNC No errors retrieving post we just made, he should not be nil.");
			GHAssertEqualObjects([retrievedPost remoteID], newPost.remoteID, @"ASYNC Retrieved post should have same remoteID as created post");
		
			newPost.author = @"Dan 2";
			
			/////////////////
			//TEST UPDATE
			//update should go through
			[newPost remoteUpdateAsync:^(NSError *e3) {
				GHAssertNil(e3, @"ASYNC Update should've gone through, there should be no error");

				NSNumber *postID = newPost.remoteID;
				newPost.remoteID = nil;
				
				//test to see that it'll fail on trying to update instance with nil ID
				GHAssertThrows([newPost remoteUpdateAsync:^(NSError *error) {}], @"ASYNC Tried to update an instance with a nil ID, where's the exception?");
				
				newPost.remoteID = postID;
				
				//update should fail validation b/c no author
				newPost.author = nil;
				[newPost remoteUpdateAsync:^(NSError *e4) {
					GHAssertNotNil(e4, @"ASYNC New post should've failed, there should be an error.");
					GHAssertNotNil([[e4 userInfo] objectForKey:NSRValidationErrorsKey], @"ASYNC There was an error by validation, so validation error dictionary should be present.");
					GHAssertNil(newPost.author, @"ASYNC New author failed validation (unchanged) but it should still be nil locally.");
					
					///////////////////////
					//TEST READ (RETRIVE)
					
					[newPost remoteFetchAsync:^(BOOL changed, NSError *e5) {
						GHAssertNil(e5, @"ASYNC Should be no error retrieving a value.");
						//see if it correctly set the info on the server (still there after failed validation) to overwrite the local author (set to nil)
						GHAssertNotNil(newPost.author, @"ASYNC New post should have gotten back his old author after validation failed (on the retrieve).");
						
						newPost.remoteID = nil;
						
						//see if there's an exception if trying to retrieve with a nil ID
						GHAssertThrows([newPost remoteFetchAsync:^(BOOL changed, NSError *error) {}], @"ASYNC Tried to retrieve an instance with a nil ID, where's the exception?");

						///////////////////////
						//TEST DESTROY
						
						//test trying to destroy instance with nil ID
						GHAssertThrows([newPost remoteDestroyAsync:^(NSError *error) {}], @"ASYNC Tried to delete an instance with a nil ID, where's the exception?");
						newPost.remoteID = postID;
						
						[newPost remoteDestroyAsync:^(NSError *e6) {
							GHAssertNil(e6, @"ASYNC Deleting new post should have worked, but got back an error.");
							
							//should get back an error cause there shouldn't be a post with its ID anymore
							[newPost remoteDestroyAsync:^(NSError *e7) {
								GHAssertNotNil(e7, @"ASYNC Deleting new post for a second time shouldn't have worked, where's the error?");
							}];
						}];
					}];
				}];
			}];
		}];
	}];	
}

- (void) test_crud
{
	GHAssertFalse(noServer, @"Test app not running. Run 'rails s'.");
	
	///////////////////
	//TEST NIL APP URL
	
	//point app to nil at first to test
	[[NSRConfig defaultConfig] setAppURL:nil];
	
	NSError *e = nil;
	
	GHAssertThrows([Post remoteObjectWithID:1 error:&e], @"Should fail on no app URL set in config, where's the error?");
	
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
	
	GHAssertNil(e, @"remoteAll on Post should have worked.'");
	GHAssertNotNil(allPeople, @"No errors, allPeople should not be nil.");
	
	e = nil;
	
	/////////////////
	//TEST READ BY ID
	
	//try to retrieve ID = -1, obviously error
	Post *post = [Post remoteObjectWithID:-1 error:&e];
	
	GHAssertNotNil(e, @"Obviously no one with ID -1, where's the error?");
	GHAssertNil(post, @"There was an error on remoteObjectWithID, post should be nil.");
	
	e = nil;
	
	/////////////////
	//TEST CREATE
	
	//this should fail on validation b/c no author
	Post *failedPost = [[Post alloc] init];
	failedPost.author = @"Fail";
	[failedPost remoteCreate:&e];
	
	GHAssertNotNil(e, @"Post should have failed validation b/c no content... where is error?");
	GHAssertNotNil(failedPost, @"Post did fail but object should not be nil.");
	GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"There was an error by validation, so validation error dictionary should be present.");
	
	e = nil;
	
	//this should go through
	Post *newPost = [[Post alloc] init];
	newPost.author = @"Dan";
	newPost.content = @"Test";
	[newPost remoteCreate:&e];
	
	GHAssertNil(e, @"New post should've been created fine, there should be no error.");
	GHAssertNotNil(newPost.remoteID, @"New post was just created, remoteID shouldn't be nil.");
	GHAssertNotNil(newPost.remoteAttributes, @"New post was just created, remoteAttributes shouldn't be nil.");
	
	e = nil;
	
	/////////////////
	//TEST READ BY ID (again)
	
	Post *retrievedPost = [Post remoteObjectWithID:[newPost.remoteID integerValue] error:&e];
	
	GHAssertNil(e, @"Retrieving post we just made, should be no errors.");
	GHAssertNotNil(retrievedPost, @"No errors retrieving post we just made, he should not be nil.");
	GHAssertEqualObjects(retrievedPost.remoteID, newPost.remoteID, @"Retrieved post should have same remoteID as created post");
	
	e = nil;
	
	/////////////////
	//TEST UPDATE
	
	//update should go through
	newPost.author = @"Dan 2";
	[newPost remoteUpdate:&e];
	
	GHAssertNil(e, @"Update should've gone through, there should be no error");
	
	e = nil;
	
	NSNumber *postID = newPost.remoteID;
	newPost.remoteID = nil;
	
	//test to see that it'll fail on trying to update instance with nil ID
	GHAssertThrows([newPost remoteUpdate:&e], @"Tried to update an instance with a nil ID, where's the exception?");
	newPost.remoteID = postID;
	
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
	
	[newPost remoteFetch:&e];
	
	GHAssertNil(e, @"Should be no error retrieving a value.");
	//see if it correctly set the info on the server (still there after failed validation) to overwrite the local author (set to nil)
	GHAssertNotNil(newPost.author, @"New post should have gotten back his old author after validation failed (on the retrieve).");
	
	e = nil;
	
	//see if there's an error if trying to retrieve with a nil ID
	newPost.remoteID = nil;
	
	GHAssertThrows([newPost remoteFetch:&e], @"Tried to retrieve an instance with a nil ID, where's the exception?");
	
	e = nil;
	
	///////////////////////
	//TEST DESTROY
	
	//test trying to destroy instance with nil ID
	GHAssertThrows([newPost remoteDestroy:&e], @"Tried to delete an instance with a nil ID, where's the exception?");
	newPost.remoteID = postID;
	
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
	GHAssertFalse(noServer, @"Test app not running. Run 'rails s'.");
	
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000/"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	NSError *e = nil;

	NSArray *resps = [NSRResponse remoteAll:&e];
	GHAssertNotNil(e, @"Without 'prefix ignore' set it should fail trying to access nsr_response...");

	[[NSRConfig defaultConfig] setIgnoresClassPrefixes:YES];
	
	e = nil;
	
	Post *post = [[Post alloc] init];
	post.author = @"Dan";
	post.content = @"Test";
	post.responses = nil;
	
	e = nil;
	
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
	
	NSRResponse *response = [[NSRResponse alloc] init];
	[post.responses addObject:response];
	
	[post remoteUpdate:&e];
	
	GHAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"Should've been a validation error in sending reponse without content/author.");
	GHAssertTrue(post.responses.count == 1, @"Local array should still have response even though wasn't created properly.");
	GHAssertNotNil(response, @"Validation failed on nested create but local object should still be there (external)");
	
	e = nil;
	
	response.content = @"Response content";
	response.author = @"Response author";
	
	[post remoteUpdate:&e];
	
	GHAssertNil(e, @"There should be no error nesting Response creation");
	GHAssertTrue(post.responses.count == 1, @"Local responses array should still have response (created properly).");
	GHAssertNotNil(response, @"Local Response object should still be here (created properly)");
	
	e = nil;
	
	//now try retrieving post and see if remoteID exists
	Post *retrievedPost = [Post remoteObjectWithID:post.remoteID.integerValue error:&e];
	GHAssertNil(e, @"There should be no errors in post retrieval");
	GHAssertTrue(retrievedPost.responses.count == 1, @"The retrieved post should have one response (we just made it)");
	GHAssertNotNil([[retrievedPost.responses objectAtIndex:0] remoteID], @"The response inside post's response should have a present remoteID (we just made it)");
	
	NSNumber *responseID = response.remoteID;
	response.remoteDestroyOnNesting = YES;
	[post remoteUpdate:&e];
	
	GHAssertNil(e, @"There should be no error nesting Response deletion");
	GHAssertTrue(post.responses.count == 1, @"Local responses array should still have response (deleted properly).");
	GHAssertNotNil(response, @"Local Response object should still be here (deleted properly)");
	
	e = nil;
	
	NSRResponse *retrieveResponse = [NSRResponse remoteObjectWithID:[responseID integerValue] error:&e];
	GHAssertNotNil(e, @"Response object should've been nest-deleted, where's the error in retrieving it?");
	
	e = nil;
	
	//test nest-creation via RESPONSE-side, meaning we set its post variable (this should fail without the -b flag)
	NSRResponse *newResponse = [[NSRResponse alloc] init];
	newResponse.content = @"Test";
	newResponse.author = @"Test";
	newResponse.post = post;
	
	[newResponse remoteCreate:&e];
	GHAssertNotNil(e, @"Tried to send Rails a 'post_attributes' key in belongs_to association, where's the error?");
	GHAssertNil(newResponse.remoteID, @"newResponse's ID should be nil - there was an error in create.");
	
	e = nil;
	
	//now try with -b flag
	NSRResponse *belongsTo = [[NSRResponse alloc] initWithCustomSyncProperties:@"*, post -b"];
	belongsTo.content = @"Test";
	belongsTo.author = @"Test";
	belongsTo.post = post;
	
	[belongsTo remoteCreate:&e];
	
	GHAssertNil(e, @"There should be no error with sending response marked with 'belongs_to' - 'post_id' should've been used instead of _attributes");
	GHAssertNotNil(belongsTo.remoteID, @"belongsTo response's ID should exist - there was no error in create.");
	
	e = nil;
	
	[belongsTo remoteFetch:&e];
	
	GHAssertNil(e, @"There should be no error in retrieving response.");
	GHAssertEqualObjects(belongsTo.post.remoteID, post.remoteID, @"The Post remoteID coming from the newly created Response should be the same as the post object under which we made it.");
	
	e = nil;
	
	[belongsTo remoteDestroy:&e];	
	GHAssertNil(e, @"Response object should've been destroyed fine (nothing to do with nesting, just cleaning up)");
	
	e = nil;
	
	[post remoteDestroy:&e];	
	GHAssertNil(e, @"Post object should've been destroyed fine (nothing to do with nesting, just cleaning up)");
	
	e = nil;
	
	Post *dictionariesPost = [[Post alloc] initWithCustomSyncProperties:@"*, responses:"];
	dictionariesPost.author = @"author";
	dictionariesPost.content = @"content";
	dictionariesPost.responses = [NSMutableArray array];
	
	NSRResponse *testResponse = [[NSRResponse alloc] init];
	testResponse.author = @"Test";
	testResponse.content = @"Test";
	
	[dictionariesPost.responses addObject:testResponse];
	
	[dictionariesPost remoteCreate:&e];
	GHAssertNil(e, @"Should be no error, even though responses is set to dicts");
	GHAssertNotNil(dictionariesPost.remoteID, @"Model ID should be present if there was no error on create...");
	
	e = nil;
	
	GHAssertTrue(dictionariesPost.responses.count == 1, @"Should have one response returned from Post create");
	
	//now, as the retrieve part of the create, it won't know what to stick in the array and put NSDictionaries in instead
	GHAssertTrue([[dictionariesPost.responses objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Should've filled it with NSDictionaries. Got %@ instead",NSStringFromClass([[dictionariesPost.responses objectAtIndex:0] class]));
	
	//same applies for retrieve
	BOOL changes = [dictionariesPost remoteFetch:&e];
	GHAssertNil(e, @"There should've been no errors on the retrieve, even if no nested model defined.");
	GHAssertTrue(dictionariesPost.responses.count == 1, @"Should still come back with one response");
	GHAssertTrue([[dictionariesPost.responses objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Should've filled it with NSDictionaries. Got %@ instead",NSStringFromClass([[dictionariesPost.responses objectAtIndex:0] class]));
	GHAssertFalse(changes,@"There should be no changes, even when using dicts");
	
	e = nil;
	
	//testResponse will fail destroy
	GHAssertThrows([testResponse remoteDestroy:&e], @"testResponse object was never set an ID (since the retrieve only returned dictionaries), so it should throw an exception on destroy.");
	
	e = nil;
	
	//now, let's manually add it from the dictionary and destroy
	testResponse.remoteID = [[dictionariesPost.responses objectAtIndex:0] objectForKey:@"id"];
	[testResponse remoteDestroy:&e];	
	GHAssertNil(e, @"testResponse object should've been destroyed fine after manually setting ID from dictionary (nothing to do with nesting, just cleaning up)");
	
	e = nil;
	
	[dictionariesPost remoteDestroy:&e];	
	GHAssertNil(e, @"Post object should've been destroyed fine (nothing to do with nesting, just cleaning up)");

	e = nil;
}

- (void) test_diff_detection
{
	GHAssertFalse(noServer, @"Test app not running. Run 'rails s'.");
	
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000/"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	NSError *e = nil;
	
	//remove the two dates, which could modify our object (not relevant currently in this test, but i'll forget later)
	Post *post = [[Post alloc] initWithCustomSyncProperties:@"*, responses:NSRResponse, updatedAt -x, createdAt -x"];
	post.author = @"Dan";
	post.content = @"Text";
	
	[post remoteCreate:&e];
	
	GHAssertNil(e, @"There should be no error on a normal remoteCreate for Post");
	GHAssertNotNil(post.remoteID, @"There should be a remoteID present for newly created object");
	
	e = nil;
	
	BOOL changes = [post remoteFetch:&e];
	GHAssertNil(e, @"There should be no error on a normal remoteFetch for existing Post obj");
	GHAssertFalse(changes, @"remoteFetch should've returned false - there were no changes to Post");
	
	e = nil;
	
	post.content = @"Local change";
	
	changes = [post remoteFetch:&e];
	GHAssertNil(e, @"There should be no error on a normal remoteFetch for existing Post obj");
	GHAssertTrue(changes, @"remoteFetch should've returned true - there was a local change to Post");
	
	e = nil;
	
	//default NSRResponse class doesn't have -b, used for some other test
	NSRResponse *response = [[NSRResponse alloc] initWithCustomSyncProperties:@"*, post -b"];
	response.author = @"John";
	response.content = @"Response";
	
	[post.responses addObject:response];
	
	changes = [post remoteFetch:&e];
	GHAssertNil(e, @"There should be no error on a normal remoteFetch for existing Post obj");
	GHAssertTrue(post.responses.count == 0, @"remoteFetch should've overwritten post.responses");
	GHAssertTrue(changes, @"remoteFetch should've returned true - there was a local change to Post (added a nested Response)");

	e = nil;
	
	response.post = post;
	[response remoteCreate:&e];
	
	//this should actually fail since it'll think it's nsr_response
	GHAssertNotNil(e, @"There should be an error from not reaching 'nsr_response'...");
	
	e = nil;
	
	//simultaneously test -[NSRConfig setIgnoresClassPrefixes:]
	[[NSRConfig defaultConfig] setIgnoresClassPrefixes:YES];
	[response remoteCreate:&e];

	GHAssertNil(e, @"There should be no error on a normal remoteCreate for Response obj");
	GHAssertNotNil(response.remoteID, @"There should be a remoteID present for newly created object");
	
	e = nil;
	
	response.post = nil;
	changes = [response remoteFetch:&e];
	GHAssertNil(e, @"There should be no error on a normal remoteFetch for existing Response obj");
	GHAssertNotNil(response.post, @"remoteFetch should've added the tied Post object");
	GHAssertTrue(changes, @"remoteFetch should've returned true - locally the post attr was set to nil.");
	
	e = nil;
	
	changes = [post remoteFetch:&e];
	GHAssertNil(e, @"There should be no error on a normal remoteFetch for existing Post obj");
	GHAssertTrue(post.responses.count == 1, @"remoteFetch should've added the newly created response");
	GHAssertTrue(changes, @"remoteFetch should've returned true - there was a remote change to Post (Response was created)");

	e = nil;
	
	changes = [post remoteFetch:&e];
	GHAssertNil(e, @"There should be no error on a normal remoteFetch for existing Post obj");
	GHAssertFalse(changes, @"remoteFetch should've returned false - there were no changes to Post");
	
	e = nil;

	//clean up
	
	[response remoteDestroy:&e];
	GHAssertNil(e, @"There should be no error on a normal remoteDestroy for existing Response obj");
	e = nil;
	
	[post remoteDestroy:&e];
	GHAssertNil(e, @"There should be no error on a normal remoteDestroy for existing Post obj");
}

- (void) test_date_conversion
{	
	GHAssertFalse(noServer, @"Test app not running. Run 'rails s'.");
	
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000/"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	Post *post = [[Post alloc] init];
	post.author = @"Author";
	post.content = @"test_date_conversion";
	
	NSError *e = nil;
	
	[post remoteCreate:&e];
	
	GHAssertNil(e, @"There should be no error in remoteCreate");
	GHAssertNotNil(post.updatedAt,@"updatedAt should've been set from remoteCreate");
	
	e = nil;
	
	//sleep to make a substantial difference in updated_at
	sleep(1);
	
	post.content = @"change";
	[post remoteUpdate:&e];
	
	GHAssertNil(e,@"There should be no error in updating post");
	
	e = nil;
	
	BOOL changes = [post remoteFetch:&e];
	
	GHAssertNil(e, @"There should be no error in remoteFetch");
	GHAssertNotNil(post.updatedAt,@"updatedAt should be present");
	GHAssertTrue(changes,@"UpdatedAt should've changed");
	
	e = nil;
	
	//invalid date format
	[[NSRConfig defaultConfig] setDateFormat:@"!@#@$"];
	GHAssertThrows([post remoteFetch:&e], @"There should be an exception in setting to a bad format");
	
	NSDictionary *dict = [post dictionaryOfRemoteProperties];
	GHAssertNotNil(dict, @"There should be no problem making a dict, even if format is bad");
	GHAssertEqualStrings([dict objectForKey:@"created_at"], @"!@#@$", @"New format should've been applied");	
	
	e = nil;
	
	[post remoteDestroy:&e];
	
	GHAssertNil(e,@"There should be no problem remotely destroying post - just cleaning up.");
}

- (void) test_custom_requests
{
	////////
	//root
	NSString *root = [NSRailsModel routeForControllerMethod:nil];
	GHAssertEqualStrings(root, @"", @"Root route failed");	

	NSString *rootAction = [NSRailsModel routeForControllerMethod:@"action"];
	GHAssertEqualStrings(rootAction, @"action", @"Root route failed");	
	
	
	/////////////////////
	//controller (class)
	NSString *getAll = [Post routeForControllerMethod:nil];
	GHAssertEqualStrings(getAll, @"posts", @"Nil controller route failed");
	
	NSString *controllerAction = [Post routeForControllerMethod:@"action"];
	GHAssertEqualStrings(controllerAction, @"posts/action", @"Controller route failed");
	
	
	////////////
	//instance
	Post *post = [[Post alloc] init];
	
	//should fail, since post has nil ID
	GHAssertThrows([post routeForInstanceMethod:nil], @"Should have been an exception when trying to get an instance route on instance with nil remoteID");
	
	post.remoteID = [NSNumber numberWithInt:1];
	
	NSString *get = [post routeForInstanceMethod:nil];
	GHAssertEqualStrings(get, @"posts/1", @"Nil instance route failed");
		
	NSString *instanceAction = [post routeForInstanceMethod:@"action"];
	GHAssertEqualStrings(instanceAction, @"posts/1/action", @"Instance route failed");
}

- (void) test_inflection
{
	NSRAssertEqualsUnderscored(@"post", @"post");
	NSRAssertEqualsUnderscored(@"Post", @"post");
	NSRAssertEqualsUnderscored(@"DHPost", @"dh_post");
	NSRAssertEqualsUnderscored(@"postObject", @"post_object");
	NSRAssertEqualsUnderscored(@"postObjectA", @"post_object_a");
	NSRAssertEqualsUnderscored(@"postObjectAB", @"post_object_ab");
	NSRAssertEqualsUnderscored(@"postObjectABCSomething", @"post_object_abc_something");
	NSRAssertEqualsUnderscored(@"post_object", @"post_object");
	NSRAssertEqualsUnderscored(@"post_Object", @"post_object");

	GHAssertEqualStrings([@"post" underscoreIgnorePrefix:YES], @"post", nil);
	GHAssertEqualStrings([@"Post" underscoreIgnorePrefix:YES], @"post", nil);
	GHAssertEqualStrings([@"DPost" underscoreIgnorePrefix:YES], @"post", nil);
	GHAssertEqualStrings([@"DHPost" underscoreIgnorePrefix:YES], @"post", nil);
	GHAssertEqualStrings([@"PostDH" underscoreIgnorePrefix:YES], @"post_dh", nil);
	GHAssertEqualStrings([@"DHPostDH" underscoreIgnorePrefix:YES], @"post_dh", nil);
	
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

- (void)setUpClass
{
	// Run at start of all tests in the class

	NSError *e = nil;
	
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000/"];
	
	[NSRailsModel remoteGET:@"404.html" error:&e];
	
	//if error, and it's NSURL domain, must be that the server isn't running
	if (e && [[e domain] isEqualToString:NSURLErrorDomain])
	{
		noServer = YES;
		
		NSString *title = @"Server not running";
		NSString *text = @"It doesn't look the test Rails app is running locally. Some tests can't run without it.\n\nTo run the app:\n\"$ cd demo/server; rails s\".\nIf your DB isn't set up:\n\"$ rake db:migrate\".";
		
#if TARGET_OS_IPHONE
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
#else
		NSAlert *alert = [NSAlert alertWithMessageText:title defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:text];
		[alert runModal];
#endif
	}
}

- (void)tearDownClass {
	// Run at end of all tests in the class
}

- (void)setUp
{
	// Run before each test method
	[NSRConfig resetConfigs];
}

- (void)tearDown {
	// Run after each test method
} 

@end