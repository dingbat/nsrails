//
//  Integration.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"



//bad because doesn't inherit from NSRRemoteObject
@interface BadResponse : NSObject
@property (nonatomic, strong) NSString *content, *author;
@property (nonatomic, strong) Post *post;
@end

@implementation BadResponse
@synthesize post, content, author;
@end

@interface Faker : NSRRemoteObject
@end
@implementation Faker
@end

@interface Integration : SenTestCase
@end

@implementation Integration

static BOOL noServer = NO;


- (void) test_crud_async
{
	NSRAssertNoServer(noServer);
	
	/////////////////
	//TEST READ ALL
	
	[Post remoteAllAsync:^(NSArray *allPeople, NSError *error) 
	 {
		 STAssertNil(error, @"ASYNC remoteAll on Post should have worked.'");
		 STAssertNotNil(allPeople, @"ASYNC No errors, allPeople should not be nil.");
	 }];
	
	
	/////////////////
	//TEST READ BY ID
	
	//try to retrieve ID = -1, obviously error
	[Post remoteObjectWithID:NSRNumber(-1) async:^(id post, NSError *error) {
		STAssertNotNil(error, @"ASYNC Obviously no one with ID -1, where's the error?");
		STAssertNil(post, @"ASYNC There was an error on remoteObjectWithID, post should be nil.");
	}];
	
	
	/////////////////
	//TEST CREATE
	
	//this should fail on validation b/c no author
	Post *failedPost = [[Post alloc] init];
	failedPost.author = @"Fail";
	[failedPost remoteCreateAsync:^(NSError *e) {
		STAssertNotNil(e, @"ASYNC Post should have failed validation b/c no content... where is error?");
		STAssertNotNil(failedPost, @"ASYNC Post did fail but object should not be nil.");
		STAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"ASYNC There was an error by validation, so validation error dictionary should be present.");
	}];
	
	//this should go through
	Post *newPost = [[Post alloc] init];
	newPost.author = @"Dan";
	newPost.content = @"Async Test";
	[newPost remoteCreateAsync:^(NSError *e) {
		STAssertNil(e, @"ASYNC New post should've been created fine, there should be no error.");
		STAssertNotNil(newPost.remoteID, @"ASYNC New post was just created, remoteID shouldn't be nil.");
		STAssertNotNil(newPost.remoteAttributes, @"ASYNC New post was just created, remoteAttributes shouldn't be nil.");
		
		/////////////////
		//TEST READ BY ID (again)
		
		[Post remoteObjectWithID:newPost.remoteID async:^(id retrievedPost, NSError *e2) {
			STAssertNil(e2, @"ASYNC Retrieving post we just made, should be no errors.");
			STAssertNotNil(retrievedPost, @"ASYNC No errors retrieving post we just made, he should not be nil.");
			STAssertEqualObjects([retrievedPost remoteID], newPost.remoteID, @"ASYNC Retrieved post should have same remoteID as created post");
			
			newPost.author = @"Dan 2";
			
			/////////////////
			//TEST UPDATE
			//update should go through
			[newPost remoteUpdateAsync:^(NSError *e3) {
				STAssertNil(e3, @"ASYNC Update should've gone through, there should be no error");
				
				NSNumber *postID = newPost.remoteID;
				newPost.remoteID = nil;
				
				//test to see that it'll fail on trying to update instance with nil ID
				STAssertThrowsSpecificNamed([newPost remoteUpdateAsync:^(NSError *error) {}], NSException, NSRNullRemoteIDException, @"ASYNC Tried to update an instance with a nil ID, where's the exception?");
				
				newPost.remoteID = postID;
				
				//update should fail validation b/c no author
				newPost.author = nil;
				[newPost remoteUpdateAsync:^(NSError *e4) {
					STAssertNotNil(e4, @"ASYNC New post should've failed, there should be an error.");
					STAssertNotNil([[e4 userInfo] objectForKey:NSRValidationErrorsKey], @"ASYNC There was an error by validation, so validation error dictionary should be present.");
					STAssertNil(newPost.author, @"ASYNC New author failed validation (unchanged) but it should still be nil locally.");
					
					///////////////////////
					//TEST READ (RETRIVE)
					
					[newPost remoteFetchAsync:^(NSError *e5) {
						STAssertNil(e5, @"ASYNC Should be no error retrieving a value.");
						//see if it correctly set the info on the server (still there after failed validation) to overwrite the local author (set to nil)
						STAssertNotNil(newPost.author, @"ASYNC New post should have gotten back his old author after validation failed (on the retrieve).");
						
						newPost.remoteID = nil;
						
						//see if there's an exception if trying to retrieve with a nil ID
						STAssertThrowsSpecificNamed([newPost remoteFetchAsync:^(NSError *error) {}], NSException, NSRNullRemoteIDException, @"ASYNC Tried to retrieve an instance with a nil ID, where's the exception?");
						
						///////////////////////
						//TEST DESTROY
						
						//test trying to destroy instance with nil ID
						STAssertThrowsSpecificNamed([newPost remoteDestroyAsync:^(NSError *error) {}], NSException, NSRNullRemoteIDException, @"ASYNC Tried to delete an instance with a nil ID, where's the exception?");
						newPost.remoteID = postID;
						
						[newPost remoteDestroyAsync:^(NSError *e6) {
							STAssertNil(e6, @"ASYNC Deleting new post should have worked, but got back an error.");
							
							//should get back an error cause there shouldn't be a post with its ID anymore
							[newPost remoteDestroyAsync:^(NSError *e7) {
								STAssertNotNil(e7, @"ASYNC Deleting new post for a second time shouldn't have worked, where's the error?");
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
	NSRAssertNoServer(noServer);
	
	/////////////////
	//TEST READ ALL
	
	NSError *e = nil;
	NSArray *allPeople = [Post remoteAll:&e];
	
	STAssertNil(e, @"remoteAll on Post should have worked.'");
	STAssertNotNil(allPeople, @"No errors, allPeople should not be nil.");
	
	e = nil;
	
	/////////////////
	//TEST READ BY ID
	
	//try to retrieve ID = -1, obviously error
	Post *post = [Post remoteObjectWithID:NSRNumber(-1) error:&e];
	
	STAssertNotNil(e, @"Obviously no one with ID -1, where's the error?");
	STAssertNil(post, @"There was an error on remoteObjectWithID, post should be nil.");
	
	e = nil;
	
	/////////////////
	//TEST CREATE
	
	//this should fail on validation b/c no author
	Post *failedPost = [[Post alloc] init];
	failedPost.author = @"Fail";
	
	STAssertFalse([failedPost remoteCreate:&e], @"Should return NO");
	
	STAssertNotNil(e, @"Post should have failed validation b/c no content... where is error?");
	STAssertNotNil(failedPost, @"Post did fail but object should not be nil.");
	STAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"There was an error by validation, so validation error dictionary should be present.");
	
	e = nil;
	
	//this should go through
	Post *newPost = [[Post alloc] init];
	newPost.author = @"Dan";
	newPost.content = @"Test";
	STAssertTrue([newPost remoteCreate:&e], @"Should return YES");
	
	STAssertNil(e, @"New post should've been created fine, there should be no error.");
	STAssertNotNil(newPost.remoteID, @"New post was just created, remoteID shouldn't be nil.");
	STAssertNotNil(newPost.remoteAttributes, @"New post was just created, remoteAttributes shouldn't be nil.");
	STAssertNotNil([newPost.remoteAttributes objectForKey:@"updated_at"], @"Remote attributes should have updated_at, even though not declared in class.");
	
	NSNumber *oldID = newPost.remoteID;
	
	e = nil;
	
	STAssertTrue([newPost remoteCreate:&e],@"");
	STAssertNotNil(newPost.remoteID, @"New post was just created, remoteID shouldn't be nil.");
	STAssertFalse([newPost.remoteID isEqualToNumber:oldID], @"Should NOT be equal IDs - separate creates");
	
	e = nil;
	
	/////////////////
	//TEST READ BY ID (again)
	
	Post *retrievedPost = [Post remoteObjectWithID:newPost.remoteID error:&e];
	
	STAssertNil(e, @"Retrieving post we just made, should be no errors.");
	STAssertNotNil(retrievedPost, @"No errors retrieving post we just made, he should not be nil.");
	STAssertEqualObjects(retrievedPost.remoteID, newPost.remoteID, @"Retrieved post should have same remoteID as created post");
	
	e = nil;
	
	/////////////////
	//TEST UPDATE
	
	NSNumber *postID = newPost.remoteID;
	//do this twice - using remoteReplace should be the same in this instance since they both use PUT
	for (int i = 0; i < 2; i++)
	{
		//update should go through
		newPost.author = @"Dan 2";
		if (i == 0)
			STAssertTrue([newPost remoteUpdate:&e], @"Should return YES");
		else
			STAssertTrue([newPost remoteReplace:&e], @"Should return YES");
		STAssertNil(e, @"Update should've gone through, there should be no error");
		
		e = nil;
		
		newPost.remoteID = nil;
		
		//test to see that it'll fail on trying to update instance with nil ID
		if (i == 0)
			STAssertThrowsSpecificNamed([newPost remoteUpdate:&e], NSException, NSRNullRemoteIDException, @"Tried to update an instance with a nil ID, where's the exception?");
		else
			STAssertThrowsSpecificNamed([newPost remoteReplace:&e], NSException, NSRNullRemoteIDException, @"Tried to update an instance with a nil ID, where's the exception?");
		
		newPost.remoteID = postID;
		
		e = nil;
		
		//update should fail validation b/c no author
		newPost.author = nil;
		if (i == 0)
			STAssertFalse([newPost remoteUpdate:&e],@"");
		else
			STAssertFalse([newPost remoteUpdate:&e],@"");
		
		STAssertNotNil(e, @"New post should've failed, there should be an error.");
		STAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"There was an error by validation, so validation error dictionary should be present.");
		STAssertNil(newPost.author, @"New author failed validation (unchanged) but it should still be nil locally.");
		
		e = nil;
	}
	
	//not a great test for this
	[[NSRConfig defaultConfig] setUpdateMethod:@"PATCH"];
	
	newPost.author = @"test";
	
	STAssertFalse([newPost remoteUpdate:&e], @"Should fail because no PATCH method on server");
	STAssertTrue([[e description] rangeOfString:@"PATCH"].location != NSNotFound, @"Should be an error relating to PATCH");
	
	e = nil;
	
	///////////////////////
	//TEST READ (RETRIVE)
	
	STAssertTrue([newPost remoteFetch:&e],@"");
	
	STAssertNil(e, @"Should be no error retrieving a value.");
	//see if it correctly set the info on the server (still there after failed validation) to overwrite the local author (set to nil)
	STAssertNotNil(newPost.author, @"New post should have gotten back his old author after validation failed (on the retrieve).");
	
	e = nil;
	
	//see if there's an error if trying to retrieve with a nil ID
	newPost.remoteID = nil;
	
	STAssertThrowsSpecificNamed([newPost remoteFetch:&e], NSException, NSRNullRemoteIDException, @"Tried to retrieve an instance with a nil ID, where's the exception?");
	
	e = nil;
	
	///////////////////////
	//TEST DESTROY
	
	//test trying to destroy instance with nil ID
	STAssertThrowsSpecificNamed([newPost remoteDestroy:&e], NSException, NSRNullRemoteIDException, @"Tried to delete an instance with a nil ID, where's the exception?");
	newPost.remoteID = postID;
	
	e = nil;
	
	//should work
	STAssertTrue([newPost remoteDestroy:&e],@"");
	STAssertNil(e, @"Deleting new post should have worked, but got back an error.");
	
	e = nil;
	
	//should get back an error cause there shouldn't be a post with its ID anymore
	STAssertFalse([newPost remoteDestroy:&e],@"");
	STAssertNotNil(e, @"Deleting new post for a second time shouldn't have worked, where's the error?");
}

- (void) test_json_in_out
{
	NSRAssertNoServer(noServer);
	
	NSError *e = nil;
	
	NSRRequest *req = [NSRRequest GET];
	[req routeTo:@"posts"];
	
	id posts = [req sendSynchronous:&e];
	
	STAssertNil(e, @"Should be no error getting posts");
	STAssertTrue([posts isKindOfClass:[NSArray class]], @"Response should be an array");
	
	e = nil;
	
	Post *p = [[Post alloc] init];
	p.author = @"author";
	p.content = @"content";
	STAssertTrue([p remoteCreate:&e],@"");
	
	STAssertNil(e, @"Should be no error creating a post (e=%@)",e);
	STAssertNotNil(p.remoteID, @"Newly created post should have remoteID");
	
	e = nil;
	
	[req routeTo:[NSString stringWithFormat:@"posts/%@", p.remoteID]];
	id post = [req sendSynchronous:&e];
	
	STAssertNil(e, @"Should be no error getting a post (e=%@)",e);
	STAssertTrue([post isKindOfClass:[NSDictionary class]], @"Response should be a dictionary");
	STAssertNotNil([post objectForKey:@"created_at"], @"Should be have created_at, etc");
	
	e = nil;
	
	[req routeTo:@"404"];
	id root = [req sendSynchronous:&e];
	
	STAssertNil(e, @"Should be no error getting 404 string HTML (e=%@)",e);
	STAssertTrue([root isKindOfClass:[NSString class]], @"Response should be a string");
	STAssertTrue([[root lowercaseString] rangeOfString:@"html"].location != NSNotFound, @"Response should be HTML");
	
	e = nil;
	
	[req routeTo:@"8349834"];
	id bad = [req sendSynchronous:&e];
	
	STAssertNotNil(e, @"Should be an error getting /8349834");
	STAssertNil(bad, @"Response should be nil (error)");
	
	e = nil;
	
    req = [NSRRequest POST];
	[req routeTo:@"posts"];
	req.body = @"STRING";
	STAssertThrows([req sendSynchronous:&e], @"Should throw exception when sending invalid JSON");
	
    req = [NSRRequest DELETE];
	[req routeTo:[NSString stringWithFormat:@"posts/%@", p.remoteID]];
	
	id responseFromDestroy = [req sendSynchronous:&e];
	
	STAssertNil(e, @"Shouldn't be an error from DELETE (e=%@)",e);
	STAssertNotNil(responseFromDestroy, @"Response shouldn't be nil, even if blank");
	STAssertTrue([responseFromDestroy isKindOfClass:[NSString class]], @"Response should be a string");
	STAssertTrue([[responseFromDestroy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0, @"Response should be blank");
	
	e = nil;
	
	STAssertFalse([p remoteDestroy:&e], @"Should return NO if error");
	
	STAssertNotNil(e, @"Should be an error destroying a post that we already destroyed");
}

- (void) test_authentication_and_url
{
	NSRAssertNoServer(noServer);
	
	[NSRConfig resetConfigs];
	
	NSRRequest *req = [NSRRequest GET];
	
	NSError *e = nil;
	
	STAssertThrowsSpecificNamed([req sendSynchronous:&e], NSException, NSRMissingURLException, @"Should fail on no app URL set in config, where's the error?");
	
	e = nil;
	
	//point app to localhost as it should be, but no authentication
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
	[[NSRConfig defaultConfig] setAppUsername:nil];
	[[NSRConfig defaultConfig] setAppPassword:nil];
	
	[req routeTo:@"404"];
	NSString *root = [req sendSynchronous:&e];
	
	STAssertNil(e, @"Should require no authentication for /404 (e=%@)",e);
	STAssertNotNil(root, @"Should require no authentication for /404");
	
	e = nil;
	
	[req routeTo:@"posts"];
	NSArray *index = [req sendSynchronous:&e];
	
	STAssertNotNil(e, @"Should fail on not authenticated, where's the error?");
	STAssertNil(index, @"Response should be nil because there was an authentication error");
	
	e = nil;
	
	//add authentication
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	index = [req sendSynchronous:&e];
	STAssertNil(e, @"Authenticated, should be no error");
	STAssertNotNil(index, @"Authenticated, reponse should be present");
	
	e = nil;
	
	//test error domain
	[req routeTo:@"///missing"];
	STAssertNil([req sendSynchronous:&e],@"Should be nil");
	STAssertTrue(e.domain == NSRRemoteErrorDomain, @"Server error should have NSRRemoteErrorDomain");
}


- (void) test_get_all
{
	NSRAssertNoServer(noServer);
	
	NSError *e = nil;
	
	NSArray *a = [Faker remoteAll:&e];
	STAssertNotNil(e, @"Should be an error since route doesn't exist");
	STAssertEqualObjects([e domain], NSRRemoteErrorDomain, @"Domain should be NSRRemoteErrorDomain");
	STAssertNil(a, @"Array should be nil since there was an error");
	
	e = nil;
	
	NSArray *array = [Post remoteAll:&e];
	
	STAssertNil(e, @"Should be no error in retrieving all remote posts");	
	STAssertTrue([array isKindOfClass:[NSArray class]], @"Should be an array");
	
	for (Post *p in array)
	{
		e = nil;
		
		STAssertTrue([p remoteDestroy:&e],@"");
		STAssertNil(e, @"Should be no error in deleting post");	
	}
	
	Post *p = [[Post alloc] init];
	p.content = @"hello";
	p.author = @"dan";
	STAssertTrue([p remoteCreate:&e], @"");
	STAssertNil(e, @"Should be no error in creating a remote post");	
	
	e = nil;
	
	array = [Post remoteAll:&e];
	
	STAssertNil(e, @"Should be no error in retrieving all remote posts again");	
	STAssertTrue([array isKindOfClass:[NSArray class]], @"Should be an array");
	
	
	STAssertTrue(array.count > 0, @"Should be have at least one post (just made one)");
	STAssertTrue([[array objectAtIndex:0] isKindOfClass:[Post class]], @"Object should be Post instance");
	STAssertEqualObjects(p.remoteID, [[array objectAtIndex:0] remoteID], @"Object should have same ID");
	
	e = nil;
	
	STAssertTrue([p remoteDestroy:&e], @"");
	STAssertNil(e, @"Should be no error in deleting post");	
}

- (void) test_nesting
{
	NSRAssertNoServer(noServer);
	
	NSError *e = nil;
		
	Post *post = [[Post alloc] init];
	post.author = @"Dan";
	post.content = @"Test";
	post.responses = nil;
	
	e = nil;
	
	STAssertTrue([post remoteCreate:&e],@"");
	
	STAssertNil(e, @"Creating post (with nil responses) shouldn't have resulted in an error.");
	STAssertNotNil(post.responses, @"Created a post with nil responses array, should have an empty array on return.");
	STAssertTrue(post.responses.count == 0, @"Array should be empty on return.");
	
	e = nil;
	
	post.responses = [NSMutableArray array];
	STAssertTrue([post remoteUpdate:&e],@"");
	
	STAssertNil(e, @"Creating post (with empty responses) shouldn't have resulted in an error.");
	STAssertNotNil(post.responses, @"Made an empty responses array, array should exist on return.");
	STAssertTrue(post.responses.count == 0, @"Made an empty responses array, array should be empty on return.");
	
	e = nil;
	
	Response *response = [[Response alloc] init];
	[post.responses addObject:response];
	
	STAssertFalse([post remoteUpdate:&e],@"");
	
	STAssertNotNil([[e userInfo] objectForKey:NSRValidationErrorsKey], @"Should've been a validation error in sending reponse without content/author.");
	STAssertTrue(post.responses.count == 1, @"Local array should still have response even though wasn't created properly.");
	STAssertNotNil(response, @"Validation failed on nested create but local object should still be there (external)");
	
	e = nil;
	
	response.content = @"Response content";
	response.author = @"Response author";
	
	STAssertTrue([post remoteUpdate:&e],@"");
	
	STAssertNil(e, @"There should be no error nesting Response creation");
	STAssertTrue(post.responses.count == 1, @"Local responses array should still have response (created properly).");
	STAssertNotNil(response, @"Local Response object should still be here (created properly)");
	
	STAssertNil(response.remoteID, @"Response should have a nil remoteID since it was created on update");
	STAssertThrowsSpecificNamed([Response remoteObjectWithID:response.remoteID error:&e], NSException, NSInvalidArgumentException, @"Should throw NSInvalidArgumentException for nil remoteID");
	
	e = nil;
	
	//try fetching and seeing if rID exists
	STAssertTrue([post remoteFetch:&e], @"");
	
	Response *fetchedResponse = [[post responses] lastObject];
	
	STAssertTrue(fetchedResponse != response, @"Should be different because first response had no ID, so didn't know to reuse this object");
	
	STAssertNotNil([fetchedResponse remoteID], @"Response should have a remoteID after fetching the post");
	
	e = nil;
	
	STAssertNotNil([Response remoteObjectWithID:fetchedResponse.remoteID error:&e], @"Should be a vaild ID");
	STAssertNil(e, @"Should be no error");
	
	e = nil;
	
	fetchedResponse.remoteDestroyOnNesting = YES;
	STAssertTrue([post remoteUpdate:&e],@"");
	
	STAssertNil(e, @"There should be no error nesting Response deletion");
	STAssertTrue(post.responses.count == 1, @"Local responses array should still have response (deleted properly).");
	
	e = nil;
	
	
	STAssertNil([Response remoteObjectWithID:fetchedResponse.remoteID error:&e], @"Should've been deleted");
	STAssertNotNil(e, @"Response object should've been nest-deleted, where's the error in retrieving it?");
	
	e = nil;
	
	//test nest-creation via RESPONSE-side, meaning we set its post variable (this should fail without the -b flag)
	Response *newResponse = [[Response alloc] init];
	newResponse.content = @"Test";
	newResponse.author = @"Test";
	newResponse.post = post;
	
	STAssertFalse([newResponse remoteCreate:&e],@"");
	STAssertNotNil(e, @"Tried to send Rails a 'post_attributes' key in belongs_to association, where's the error?");
	STAssertNil(newResponse.remoteID, @"newResponse's ID should be nil - there was an error in create.");
	
	e = nil;
	
	//now try with -b flag
	Response *belongsTo = [[Response alloc] init];
	belongsTo.content = @"Test";
	belongsTo.belongsToPost = YES;
	belongsTo.author = @"Test";
	belongsTo.post = post;
	
	STAssertTrue([belongsTo remoteCreate:&e],@"");
	
	STAssertNil(e, @"There should be no error with sending response marked with 'belongs_to' - 'post_id' should've been used instead of _attributes");
	STAssertTrue(post == belongsTo.post, @"Belongs-to response's post should be the same after create");
	STAssertNotNil(belongsTo.remoteID, @"belongsTo response's ID should exist - there was no error in create.");
	
	e = nil;
	
	STAssertTrue([belongsTo remoteFetch:&e],@"");
	
	STAssertNil(e, @"There should be no error in retrieving response.");
	STAssertEqualObjects(belongsTo.post.remoteID, post.remoteID, @"The Post remoteID coming from the newly created Response should be the same as the post object under which we made it.");
	
	e = nil;
	
	belongsTo.post = nil;	
	
	STAssertTrue([belongsTo remoteUpdate:&e],@"");
	STAssertNil(e, @"There should be no error with sending response marked with nil 'belongs_to' post");
	STAssertNil(belongsTo.post, @"belongsTo.post should still be nil");
	
	e = nil;
	
	STAssertTrue([post remoteFetch:&e],@"Should retrieve post just fine");
	STAssertTrue(post.responses.count == 0, @"Retrieved post should have 0 responses ('deleted' b-t)");
	
	//recreate belongsTo
	belongsTo.post = post;
	belongsTo.remoteID = nil;
	
	STAssertTrue([belongsTo remoteCreate:&e],@"");
	STAssertTrue([post remoteFetch:&e],@"Should retrieve post just fine");
	STAssertTrue(post.responses.count == 1, @"Retrieved post should have 1 responses (just recreated b-t)");
	
	
	//now test with dicts
	Post *dictionariesPost = [[Post alloc] init];
	dictionariesPost.author = @"author";
	dictionariesPost.content = @"content";
	dictionariesPost.noResponseRelationship = YES;
	dictionariesPost.responses = [NSMutableArray array];
	
	Response *testResponse = [[Response alloc] init];
	testResponse.author = @"Test";
	testResponse.belongsToPost = YES;
	testResponse.content = @"Test";
	
	[dictionariesPost.responses addObject:[testResponse remoteDictionaryRepresentationWrapped:NO]];
	
	STAssertFalse([dictionariesPost remoteCreate:&e],@"");
	STAssertNotNil(e, @"Should be error, since tried to send attrs without _attributes");
	STAssertNil(dictionariesPost.remoteID, @"Model ID shouldn't be present if there was an error on create...");
	
	e = nil;
	
	// on retrieve, it should set responses in dictionary form
	dictionariesPost.remoteID = post.remoteID;
	
	STAssertTrue([dictionariesPost remoteFetch:&e],@"e=%@",e);
	STAssertNil(e, @"There should've been no errors on the retrieve, even if no nested model defined.");
	STAssertEquals(dictionariesPost.responses.count, post.responses.count, @"Should still come back with same number of dicts as responses (1)");
	STAssertTrue([[dictionariesPost.responses objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Should've filled it with NSDictionaries. Got %@ instead",NSStringFromClass([[dictionariesPost.responses objectAtIndex:0] class]));
	
	e = nil;
	
	//testResponse will fail destroy
	STAssertThrowsSpecificNamed([testResponse remoteDestroy:&e], NSException, NSRNullRemoteIDException, @"testResponse object was never set an ID (since the retrieve only returned dictionaries), so it should throw an exception on destroy.");
	
	e = nil;
	
	//now, let's manually add it from the dictionary and destroy
	testResponse.remoteID = [[dictionariesPost.responses objectAtIndex:0] objectForKey:@"id"];
	STAssertTrue([testResponse remoteDestroy:&e],@"");	
	STAssertNil(e, @"testResponse object should've been destroyed fine after manually setting ID from dictionary (nothing to do with nesting, just cleaning up)");
}

- (void) test_date_conversion
{	
	NSRAssertNoServer(noServer);
	
	Post *post = [[Post alloc] init];
	post.author = @"Author";
	post.content = @"test_date_conversion";
	
	NSError *e = nil;
	
	STAssertTrue([post remoteCreate:&e],@"");
	
	STAssertNil(e, @"There should be no error in remoteCreate");
	STAssertNotNil(post.updatedAt,@"updatedAt should've been set from remoteCreate");
	
	e = nil;
	
	//sleep to make a substantial difference in updated_at
	sleep(2);
	
	post.content = @"change";
	STAssertTrue([post remoteUpdate:&e],@"");
	
	STAssertNil(e,@"There should be no error in updating post");
	
	e = nil;
	
	STAssertTrue([post remoteFetch:&e],@"");
	
	STAssertNil(e, @"There should be no error in remoteFetch");
	STAssertNotNil(post.updatedAt,@"updatedAt should be present");
	
	STAssertTrue([post remoteDestroy:&e],@"");
	
	STAssertNil(e,@"There should be no problem remotely destroying post - just cleaning up.");
}

- (void) test_array_category
{
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	NSError *e = nil;
	
	STAssertThrowsSpecificNamed([array remoteFetchAll:[NSString class] error:&e], NSException, NSInvalidArgumentException, @"Should crash if class is not NSRailsModel subclass");
	
	STAssertThrowsSpecificNamed([array remoteFetchAll:nil error:&e], NSException, NSInvalidArgumentException, @"Should crash if class is not NSRailsModel subclass");
	
	NSRAssertNoServer(noServer);
	
	STAssertFalse([array remoteFetchAll:[Faker class] error:&e],@"");
	
	STAssertNotNil(e, @"Error should be present -- Faker doesn't really exist");
	
	e = nil;
	
	NSArray *posts = [Post remoteAll:&e];
	STAssertNil(e,@"Should be no error retrieving all posts (e=%@)",e);
	
	for (Post *p in posts)
	{
		e = nil;
		STAssertTrue([p remoteDestroy:&e], @"");
		STAssertNil(e,@"Should be no error deleting this post (e=%@)",e);
	}
	
	e = nil;
	
	STAssertTrue([array remoteFetchAll:[Post class] error:&e],@"");
	
	STAssertNil(e, @"Error shouldn't be present e=%@",e);
	
	e = nil;
	
	Post *p = [[Post alloc] init];
	p.author = @"dan";
	p.content = @"content";
	STAssertTrue([p remoteCreate:&e], @"");
	STAssertNil(e,@"Should be no error creating post (e=%@)",e);
	
	e = nil;
	
	STAssertTrue([array remoteFetchAll:[Post class] error:&e],@"");
	
	STAssertNil(e, @"Error shouldn't be present e=%@",e);
	STAssertTrue(array.count == 1, @"array should have 1 post");
	STAssertTrue([[array lastObject] isKindOfClass:[Post class]],@"should be Post class member");
	
	Post *thePost = [array lastObject];
	
	e = nil;
	
	STAssertTrue([array remoteFetchAll:[Post class] error:&e],@"");
	
	STAssertNil(e, @"Error shouldn't be present e=%@",e);
	STAssertTrue(array.count == 1, @"array should have 1 post again");
	STAssertTrue(thePost == [array lastObject],@"should be the same Post object");
	
	e = nil;
	
	STAssertTrue([p remoteDestroy:&e],@"");
	STAssertNil(e,@"Should be no error destroying post e=%@",e);
	
	e = nil;
	
	//make a few posts
	for (int i = 0; i < 4; i++)
	{
		Post *p2 = [[Post alloc] init];
		p2.author = @"dan2";
		p2.content = @"content2";
		STAssertTrue([p2 remoteCreate:&e], @"");
		STAssertNil(e,@"Should be no error creating post (e=%@)",e);
	}
	
	e = nil;
	
	STAssertTrue([array remoteFetchAll:[Post class] error:&e],@"");
	
	STAssertNil(e, @"Error shouldn't be present e=%@",e);
	STAssertTrue(array.count == 4, @"array should have 1 post again");
	STAssertFalse(thePost == [array lastObject],@"should be a different Post object");
	
	e = nil;
	
	Post *thePost2 = [array lastObject];
	
	thePost2.content = @"changed!!";
	STAssertTrue([thePost2 remoteUpdate:&e], @"");
	STAssertNil(e,@"Should be no error updating post (e=%@)",e);
	
	e = nil;
	
	STAssertTrue([array remoteFetchAll:[Post class] error:&e],@"");
	
	STAssertNil(e, @"Error shouldn't be present e=%@",e);
	STAssertTrue(array.count == 4, @"array should have 1 post again");
	STAssertTrue(thePost2 == [array lastObject],@"should be the same Post object");
	STAssertEqualObjects([[array lastObject] content], @"changed!!", @"content should be updated");
	
	e = nil;
	
	Post *thePostRetrieved = [Post remoteObjectWithID:thePost2.remoteID error:&e];
	STAssertNotNil(thePostRetrieved, @"should exist (we just created it");
	STAssertNil(e,@"Should be no error retrieving post (e=%@)",e);
	
	e = nil;
	
	thePostRetrieved.content = @"changed externally!";
	STAssertTrue([thePostRetrieved remoteUpdate:&e], @"");
	STAssertNil(e,@"Should be no error updating post (e=%@)",e);
	
	for (int i = 0; i < 2; i++)
	{
		e = nil;
		
		STAssertTrue([array remoteFetchAll:[Post class] error:&e],@"");
		
		STAssertNil(e, @"Error shouldn't be present e=%@ (iteration %d)",e,i);
		STAssertTrue(array.count == 4, @"array should have 1 post again (iteration %d)",i);
		STAssertEqualObjects([[array lastObject] content], @"changed externally!", @"content should be updated (iteration %d)",i);
		
		//behavior should be identical to if it was empty to begin with
		if (i == 0)
			[array removeAllObjects];
	}
	
	[array addObject:@"please remove me"];
	
	STAssertThrows([array remoteFetchAll:[Post class] error:nil],@"Should throw an exception if non-NSRRO object is entered (KVC)");
}


+ (void)setUp
{
	// Run at start of all tests in the class
	
	NSError *e = nil;
	
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000/"];
	
	[[[NSRRequest GET] routeTo:@"404.html"] sendSynchronous:&e];
	
	//if error, and it's NSURL domain, must be that the server isn't running
	if (e && [[e domain] isEqualToString:NSURLErrorDomain])
	{
		noServer = YES;
	}
}

+ (void)tearDown
{
	NSError *e = nil;
	
	NSArray *posts = [Post remoteAll:&e];
	NSAssert(!e,@"Should be no error retrieving all posts (e=%@)",e);
	
	for (Post *p in posts)
	{
		e = nil;
		NSAssert([p remoteDestroy:&e], @"");
		NSAssert(!e,@"Should be no error deleting this post (e=%@)",e);
	}
	
	e = nil;
	
	NSArray *responses = [Response remoteAll:&e];
	NSAssert(!e,@"Should be no error retrieving all responses (e=%@)",e);
	
	for (Response *r in responses)
	{ 
		e = nil;
		NSAssert([r remoteDestroy:&e], @"");
		NSAssert(!e,@"Should be no error deleting this response (e=%@)",e);
	}
}

- (void)setUp
{
	[NSRConfig resetConfigs];
	
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
	
	// Run before each test method
}

- (void)tearDown 
{
	// Run after each test method
} 

@end