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

@interface Integration : XCTestCase
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
         XCTAssertNil(error, @"ASYNC remoteAll on Post should have worked.'");
         XCTAssertNotNil(allPeople, @"ASYNC No errors, allPeople should not be nil.");
     }];
    
    
    /////////////////
    //TEST READ BY ID
    
    //try to retrieve ID = -1, obviously error
    [Post remoteObjectWithID:@-1 async:^(id post, NSError *error) {
        XCTAssertNotNil(error, @"ASYNC Obviously no one with ID -1, where's the error?");
        XCTAssertNil(post, @"ASYNC There was an error on remoteObjectWithID, post should be nil.");
    }];
    
    
    /////////////////
    //TEST CREATE
    
    //this should fail on validation b/c no author
    Post *failedPost = [[Post alloc] init];
    failedPost.author = @"Fail";
    [failedPost remoteCreateAsync:^(NSError *e) {
        XCTAssertNotNil(e, @"ASYNC Post should have failed validation b/c no content... where is error?");
        XCTAssertNotNil(failedPost, @"ASYNC Post did fail but object should not be nil.");
        XCTAssertNotNil([e userInfo][NSRErrorResponseBodyKey], @"ASYNC There was an error by validation, so validation error dictionary should be present.");
    }];
    
    //this should go through
    Post *newPost = [[Post alloc] init];
    newPost.author = @"Dan";
    newPost.content = @"Async Test";
    [newPost remoteCreateAsync:^(NSError *e) {
        XCTAssertNil(e, @"ASYNC New post should've been created fine, there should be no error.");
        XCTAssertNotNil(newPost.remoteID, @"ASYNC New post was just created, remoteID shouldn't be nil.");
        XCTAssertNotNil(newPost.remoteAttributes, @"ASYNC New post was just created, remoteAttributes shouldn't be nil.");
        
        /////////////////
        //TEST READ BY ID (again)
        
        [Post remoteObjectWithID:newPost.remoteID async:^(id retrievedPost, NSError *e2) {
            XCTAssertNil(e2, @"ASYNC Retrieving post we just made, should be no errors.");
            XCTAssertNotNil(retrievedPost, @"ASYNC No errors retrieving post we just made, he should not be nil.");
            XCTAssertEqualObjects([retrievedPost remoteID], newPost.remoteID, @"ASYNC Retrieved post should have same remoteID as created post");
            
            newPost.author = @"Dan 2";
            
            /////////////////
            //TEST UPDATE
            //update should go through
            [newPost remoteUpdateAsync:^(NSError *e3) {
                XCTAssertNil(e3, @"ASYNC Update should've gone through, there should be no error");
                
                NSNumber *postID = newPost.remoteID;
                newPost.remoteID = nil;
                
                //test to see that it'll fail on trying to update instance with nil ID
                XCTAssertThrowsSpecificNamed([newPost remoteUpdateAsync:^(NSError *error) {}], NSException, NSRNullRemoteIDException, @"ASYNC Tried to update an instance with a nil ID, where's the exception?");
                
                newPost.remoteID = postID;
                
                //update should fail validation b/c no author
                newPost.author = nil;
                [newPost remoteUpdateAsync:^(NSError *e4) {
                    XCTAssertNotNil(e4, @"ASYNC New post should've failed, there should be an error.");
                    XCTAssertNotNil([e4 userInfo][NSRErrorResponseBodyKey], @"ASYNC There was an error by validation, so validation error dictionary should be present.");
                    XCTAssertNil(newPost.author, @"ASYNC New author failed validation (unchanged) but it should still be nil locally.");
                    
                    ///////////////////////
                    //TEST READ (RETRIVE)
                    
                    [newPost remoteFetchAsync:^(NSError *e5) {
                        XCTAssertNil(e5, @"ASYNC Should be no error retrieving a value.");
                        //see if it correctly set the info on the server (still there after failed validation) to overwrite the local author (set to nil)
                        XCTAssertNotNil(newPost.author, @"ASYNC New post should have gotten back his old author after validation failed (on the retrieve).");
                        
                        newPost.remoteID = nil;
                        
                        //see if there's an exception if trying to retrieve with a nil ID
                        XCTAssertThrowsSpecificNamed([newPost remoteFetchAsync:^(NSError *error) {}], NSException, NSRNullRemoteIDException, @"ASYNC Tried to retrieve an instance with a nil ID, where's the exception?");
                        
                        ///////////////////////
                        //TEST DESTROY
                        
                        //test trying to destroy instance with nil ID
                        XCTAssertThrowsSpecificNamed([newPost remoteDestroyAsync:^(NSError *error) {}], NSException, NSRNullRemoteIDException, @"ASYNC Tried to delete an instance with a nil ID, where's the exception?");
                        newPost.remoteID = postID;
                        
                        [newPost remoteDestroyAsync:^(NSError *e6) {
                            XCTAssertNil(e6, @"ASYNC Deleting new post should have worked, but got back an error.");
                            
                            //should get back an error cause there shouldn't be a post with its ID anymore
                            [newPost remoteDestroyAsync:^(NSError *e7) {
                                XCTAssertNotNil(e7, @"ASYNC Deleting new post for a second time shouldn't have worked, where's the error?");
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
    
    XCTAssertNil(e, @"remoteAll on Post should have worked.'");
    XCTAssertNotNil(allPeople, @"No errors, allPeople should not be nil.");
    
    e = nil;
    
    /////////////////
    //TEST READ BY ID
    
    //try to retrieve ID = -1, obviously error
    Post *post = [Post remoteObjectWithID:@(-1) error:&e];
    
    XCTAssertNotNil(e, @"Obviously no one with ID -1, where's the error?");
    XCTAssertNil(post, @"There was an error on remoteObjectWithID, post should be nil.");
    
    e = nil;
    
    /////////////////
    //TEST CREATE
    
    //this should fail on validation b/c no author
    Post *failedPost = [[Post alloc] init];
    failedPost.author = @"Fail";
    
    XCTAssertFalse([failedPost remoteCreate:&e], @"Should return NO");
    
    XCTAssertNotNil(e, @"Post should have failed validation b/c no content... where is error?");
    XCTAssertNotNil(failedPost, @"Post did fail but object should not be nil.");
    XCTAssertNotNil([e userInfo][NSRErrorResponseBodyKey], @"There was an error by validation, so validation error dictionary should be present.");
    
    e = nil;
    
    //this should go through
    Post *newPost = [[Post alloc] init];
    newPost.author = @"Dan";
    newPost.content = @"Test";
    XCTAssertTrue([newPost remoteCreate:&e], @"Should return YES");
    
    XCTAssertNil(e, @"New post should've been created fine, there should be no error.");
    XCTAssertNotNil(newPost.remoteID, @"New post was just created, remoteID shouldn't be nil.");
    XCTAssertNotNil(newPost.remoteAttributes, @"New post was just created, remoteAttributes shouldn't be nil.");
    XCTAssertNotNil((newPost.remoteAttributes)[@"updated_at"], @"Remote attributes should have updated_at, even though not declared in class.");
    
    NSNumber *oldID = newPost.remoteID;
    
    e = nil;
    
    XCTAssertTrue([newPost remoteCreate:&e],@"");
    XCTAssertNotNil(newPost.remoteID, @"New post was just created, remoteID shouldn't be nil.");
    XCTAssertFalse([newPost.remoteID isEqualToNumber:oldID], @"Should NOT be equal IDs - separate creates");
    
    e = nil;
    
    /////////////////
    //TEST READ BY ID (again)
    
    Post *retrievedPost = [Post remoteObjectWithID:newPost.remoteID error:&e];
    
    XCTAssertNil(e, @"Retrieving post we just made, should be no errors.");
    XCTAssertNotNil(retrievedPost, @"No errors retrieving post we just made, he should not be nil.");
    XCTAssertEqualObjects(retrievedPost.remoteID, newPost.remoteID, @"Retrieved post should have same remoteID as created post");
    
    e = nil;
    
    /////////////////
    //TEST UPDATE
    
    NSNumber *postID = newPost.remoteID;
    //do this twice - using remoteReplace should be the same in this instance since they both use PUT
    for (int i = 0; i < 2; i++)
    {
        //update should go through
        newPost.author = @"Dan 2";
        if (i == 0) {
            XCTAssertTrue([newPost remoteUpdate:&e], @"Should return YES");
        }
        else {
            XCTAssertTrue([newPost remoteReplace:&e], @"Should return YES");
        }
        XCTAssertNil(e, @"Update should've gone through, there should be no error");
        
        e = nil;
        
        newPost.remoteID = nil;
        
        //test to see that it'll fail on trying to update instance with nil ID
        if (i == 0) {
            XCTAssertThrowsSpecificNamed([newPost remoteUpdate:&e], NSException, NSRNullRemoteIDException, @"Tried to update an instance with a nil ID, where's the exception?");
        }
        else {
            XCTAssertThrowsSpecificNamed([newPost remoteReplace:&e], NSException, NSRNullRemoteIDException, @"Tried to update an instance with a nil ID, where's the exception?");
        }
        
        newPost.remoteID = postID;
        
        e = nil;
        
        //update should fail validation b/c no author
        newPost.author = nil;
        if (i == 0) {
            XCTAssertFalse([newPost remoteUpdate:&e],@"");
        }
        else {
            XCTAssertFalse([newPost remoteUpdate:&e],@"");
        }
        
        XCTAssertNotNil(e, @"New post should've failed, there should be an error.");
        XCTAssertNotNil([e userInfo][NSRErrorResponseBodyKey], @"There was an error by validation, so validation error dictionary should be present.");
        XCTAssertNil(newPost.author, @"New author failed validation (unchanged) but it should still be nil locally.");
        
        e = nil;
    }
    
    //not a great test for this
    [[NSRConfig defaultConfig] setUpdateMethod:@"PATCH"];
    
    newPost.author = @"test";
    
    XCTAssertFalse([newPost remoteUpdate:&e], @"Should fail because no PATCH method on server");
    XCTAssertTrue([[e description] rangeOfString:@"PATCH"].location != NSNotFound, @"Should be an error relating to PATCH");
    
    e = nil;
    
    ///////////////////////
    //TEST READ (RETRIVE)
    
    XCTAssertTrue([newPost remoteFetch:&e],@"");
    
    XCTAssertNil(e, @"Should be no error retrieving a value.");
    //see if it correctly set the info on the server (still there after failed validation) to overwrite the local author (set to nil)
    XCTAssertNotNil(newPost.author, @"New post should have gotten back his old author after validation failed (on the retrieve).");
    
    e = nil;
    
    //see if there's an error if trying to retrieve with a nil ID
    newPost.remoteID = nil;
    
    XCTAssertThrowsSpecificNamed([newPost remoteFetch:&e], NSException, NSRNullRemoteIDException, @"Tried to retrieve an instance with a nil ID, where's the exception?");
    
    e = nil;
    
    ///////////////////////
    //TEST DESTROY
    
    //test trying to destroy instance with nil ID
    XCTAssertThrowsSpecificNamed([newPost remoteDestroy:&e], NSException, NSRNullRemoteIDException, @"Tried to delete an instance with a nil ID, where's the exception?");
    newPost.remoteID = postID;
    
    e = nil;
    
    //should work
    XCTAssertTrue([newPost remoteDestroy:&e],@"");
    XCTAssertNil(e, @"Deleting new post should have worked, but got back an error.");
    
    e = nil;
    
    //should get back an error cause there shouldn't be a post with its ID anymore
    XCTAssertFalse([newPost remoteDestroy:&e],@"");
    XCTAssertNotNil(e, @"Deleting new post for a second time shouldn't have worked, where's the error?");
}

- (void) test_json_in_out
{
    NSRAssertNoServer(noServer);
    
    NSError *e = nil;
    
    NSRRequest *req = [NSRRequest GET];
    [req routeTo:@"posts"];
    
    id posts = [req sendSynchronous:&e];
    
    XCTAssertNil(e, @"Should be no error getting posts");
    XCTAssertTrue([posts isKindOfClass:[NSArray class]], @"Response should be an array");
    
    e = nil;
    
    Post *p = [[Post alloc] init];
    p.author = @"author";
    p.content = @"content";
    XCTAssertTrue([p remoteCreate:&e],@"");
    
    XCTAssertNil(e, @"Should be no error creating a post (e=%@)",e);
    XCTAssertNotNil(p.remoteID, @"Newly created post should have remoteID");
    
    e = nil;
    
    [req routeTo:[NSString stringWithFormat:@"posts/%@", p.remoteID]];
    id post = [req sendSynchronous:&e];
    
    XCTAssertNil(e, @"Should be no error getting a post (e=%@)",e);
    XCTAssertTrue([post isKindOfClass:[NSDictionary class]], @"Response should be a dictionary");
    XCTAssertNotNil(post[@"created_at"], @"Should be have created_at, etc");
    
    e = nil;
    
    [req routeTo:@"404"];
    id root = [req sendSynchronous:&e];
    
    XCTAssertNil(e, @"Should be no error getting 404 string HTML (e=%@)",e);
    XCTAssertTrue([root isKindOfClass:[NSString class]], @"Response should be a string");
    XCTAssertTrue([[root lowercaseString] rangeOfString:@"html"].location != NSNotFound, @"Response should be HTML");
    
    e = nil;
    
    [req routeTo:@"8349834"];
    id bad = [req sendSynchronous:&e];
    
    XCTAssertNotNil(e, @"Should be an error getting /8349834");
    XCTAssertNil(bad, @"Response should be nil (error)");
    
    e = nil;
    
    req = [NSRRequest POST];
    [req routeTo:@"posts/create"];
    req.body = @"post%5Bauthor%5D=another+author&post%5Bcontent%5D=more+content";
    [req setAdditionalHTTPHeaders:@{@"Content-Type":@"application/x-www-form-urlencoded"}];
    XCTAssertNil(e, @"Should be no error creating posting with body equal to a url encoded string");
    
    req = [NSRRequest DELETE];
    [req routeTo:[NSString stringWithFormat:@"posts/%@", p.remoteID]];
    
    id responseFromDestroy = [req sendSynchronous:&e];
    
    XCTAssertNil(e, @"Shouldn't be an error from DELETE (e=%@)",e);
    XCTAssertNotNil(responseFromDestroy, @"Response shouldn't be nil, even if blank");
    XCTAssertTrue([responseFromDestroy isKindOfClass:[NSString class]], @"Response should be a string");
    XCTAssertTrue([[responseFromDestroy stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0, @"Response should be blank");
    
    e = nil;
    
    XCTAssertFalse([p remoteDestroy:&e], @"Should return NO if error");
    
    XCTAssertNotNil(e, @"Should be an error destroying a post that we already destroyed");
}

- (void) test_authentication_and_url
{
    NSRAssertNoServer(noServer);
    
    [NSRConfig resetConfigs];
    
    NSRRequest *req = [NSRRequest GET];
    
    NSError *e = nil;
    
    XCTAssertThrowsSpecificNamed([req sendSynchronous:&e], NSException, NSRMissingURLException, @"Should fail on no app URL set in config, where's the error?");
    
    e = nil;
    
    //point app to localhost as it should be, but no authentication
    [[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
    [[NSRConfig defaultConfig] setAppUsername:nil];
    [[NSRConfig defaultConfig] setAppPassword:nil];
    
    [req routeTo:@"404"];
    NSString *root = [req sendSynchronous:&e];
    
    XCTAssertNil(e, @"Should require no authentication for /404 (e=%@)",e);
    XCTAssertNotNil(root, @"Should require no authentication for /404");
    
    e = nil;
    
    [req routeTo:@"posts"];
    NSArray *index = [req sendSynchronous:&e];
    
    XCTAssertNotNil(e, @"Should fail on not authenticated, where's the error?");
    XCTAssertNil(index, @"Response should be nil because there was an authentication error");
    
    e = nil;
    
    //add authentication
    [[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
    [[NSRConfig defaultConfig] setAppPassword:@"iphone"];
    
    index = [req sendSynchronous:&e];
    XCTAssertNil(e, @"Authenticated, should be no error");
    XCTAssertNotNil(index, @"Authenticated, reponse should be present");
    
    e = nil;
    
    //test error domain
    [req routeTo:@"///missing"];
    XCTAssertNil([req sendSynchronous:&e],@"Should be nil");
    XCTAssertTrue(e.domain == NSRRemoteErrorDomain, @"Server error should have NSRRemoteErrorDomain");
}


- (void) test_get_all
{
    NSRAssertNoServer(noServer);
    
    NSError *e = nil;
    
    NSArray *a = [Faker remoteAll:&e];
    XCTAssertNotNil(e, @"Should be an error since route doesn't exist");
    XCTAssertEqualObjects([e domain], NSRRemoteErrorDomain, @"Domain should be NSRRemoteErrorDomain");
    XCTAssertNil(a, @"Array should be nil since there was an error");
    
    e = nil;
    
    NSArray *array = [Post remoteAll:&e];
    
    XCTAssertNil(e, @"Should be no error in retrieving all remote posts");    
    XCTAssertTrue([array isKindOfClass:[NSArray class]], @"Should be an array");
    
    for (Post *p in array)
    {
        e = nil;
        
        XCTAssertTrue([p remoteDestroy:&e],@"");
        XCTAssertNil(e, @"Should be no error in deleting post");    
    }
    
    Post *p = [[Post alloc] init];
    p.content = @"hello";
    p.author = @"dan";
    XCTAssertTrue([p remoteCreate:&e], @"");
    XCTAssertNil(e, @"Should be no error in creating a remote post");    
    
    e = nil;
    
    array = [Post remoteAll:&e];
    
    XCTAssertNil(e, @"Should be no error in retrieving all remote posts again");    
    XCTAssertTrue([array isKindOfClass:[NSArray class]], @"Should be an array");
    
    
    XCTAssertTrue(array.count > 0, @"Should be have at least one post (just made one)");
    XCTAssertTrue([array[0] isKindOfClass:[Post class]], @"Object should be Post instance");
    XCTAssertEqualObjects(p.remoteID, [array[0] remoteID], @"Object should have same ID");
    
    e = nil;
    
    XCTAssertTrue([p remoteDestroy:&e], @"");
    XCTAssertNil(e, @"Should be no error in deleting post");    
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
    
    XCTAssertTrue([post remoteCreate:&e],@"");
    
    XCTAssertNil(e, @"Creating post (with nil responses) shouldn't have resulted in an error.");
    XCTAssertNotNil(post.responses, @"Created a post with nil responses array, should have an empty array on return.");
    XCTAssertTrue(post.responses.count == 0, @"Array should be empty on return.");
    
    e = nil;
    
    post.responses = [NSMutableArray array];
    XCTAssertTrue([post remoteUpdate:&e],@"");
    
    XCTAssertNil(e, @"Creating post (with empty responses) shouldn't have resulted in an error.");
    XCTAssertNotNil(post.responses, @"Made an empty responses array, array should exist on return.");
    XCTAssertTrue(post.responses.count == 0, @"Made an empty responses array, array should be empty on return.");
    
    e = nil;
    
    Response *response = [[Response alloc] init];
    [post.responses addObject:response];
    
    XCTAssertFalse([post remoteUpdate:&e],@"");
    
    XCTAssertNotNil([e userInfo][NSRErrorResponseBodyKey], @"Should've been a validation error in sending reponse without content/author.");
    XCTAssertTrue(post.responses.count == 1, @"Local array should still have response even though wasn't created properly.");
    XCTAssertNotNil(response, @"Validation failed on nested create but local object should still be there (external)");
    
    e = nil;
    
    response.content = @"Response content";
    response.author = @"Response author";
    
    XCTAssertTrue([post remoteUpdate:&e],@"");
    
    XCTAssertNil(e, @"There should be no error nesting Response creation");
    XCTAssertTrue(post.responses.count == 1, @"Local responses array should still have response (created properly).");
    XCTAssertNotNil(response, @"Local Response object should still be here (created properly)");
    
    XCTAssertNil(response.remoteID, @"Response should have a nil remoteID since it was created on update");
    XCTAssertThrowsSpecificNamed([Response remoteObjectWithID:response.remoteID error:&e], NSException, NSInvalidArgumentException, @"Should throw NSInvalidArgumentException for nil remoteID");
    
    e = nil;
    
    //try fetching and seeing if rID exists
    XCTAssertTrue([post remoteFetch:&e], @"");
    
    Response *fetchedResponse = [[post responses] lastObject];
    
    XCTAssertTrue(fetchedResponse != response, @"Should be different because first response had no ID, so didn't know to reuse this object");
    
    XCTAssertNotNil([fetchedResponse remoteID], @"Response should have a remoteID after fetching the post");
    
    e = nil;
    
    XCTAssertNotNil([Response remoteObjectWithID:fetchedResponse.remoteID error:&e], @"Should be a vaild ID");
    XCTAssertNil(e, @"Should be no error");
    
    e = nil;
    
    fetchedResponse.remoteDestroyOnNesting = YES;
    XCTAssertTrue([post remoteUpdate:&e],@"");
    
    XCTAssertNil(e, @"There should be no error nesting Response deletion");
    XCTAssertTrue(post.responses.count == 1, @"Local responses array should still have response (deleted properly).");
    
    e = nil;
    
    
    XCTAssertNil([Response remoteObjectWithID:fetchedResponse.remoteID error:&e], @"Should've been deleted");
    XCTAssertNotNil(e, @"Response object should've been nest-deleted, where's the error in retrieving it?");
    
    e = nil;
    
    //test nest-creation via RESPONSE-side, meaning we set its post variable (this should fail without the -b flag)
    Response *newResponse = [[Response alloc] init];
    newResponse.content = @"Test";
    newResponse.author = @"Test";
    newResponse.post = post;
    
    XCTAssertFalse([newResponse remoteCreate:&e],@"");
    XCTAssertNotNil(e, @"Tried to send Rails a 'post_attributes' key in belongs_to association, where's the error?");
    XCTAssertNil(newResponse.remoteID, @"newResponse's ID should be nil - there was an error in create.");
    
    e = nil;
    
    //now try with -b flag
    Response *belongsTo = [[Response alloc] init];
    belongsTo.content = @"Test";
    belongsTo.belongsToPost = YES;
    belongsTo.author = @"Test";
    belongsTo.post = post;
    
    XCTAssertTrue([belongsTo remoteCreate:&e],@"");
    
    XCTAssertNil(e, @"There should be no error with sending response marked with 'belongs_to' - 'post_id' should've been used instead of _attributes");
    XCTAssertTrue(post == belongsTo.post, @"Belongs-to response's post should be the same after create");
    XCTAssertNotNil(belongsTo.remoteID, @"belongsTo response's ID should exist - there was no error in create.");
    
    e = nil;
    
    XCTAssertTrue([belongsTo remoteFetch:&e],@"");
    
    XCTAssertNil(e, @"There should be no error in retrieving response.");
    XCTAssertEqualObjects(belongsTo.post.remoteID, post.remoteID, @"The Post remoteID coming from the newly created Response should be the same as the post object under which we made it.");
    
    e = nil;
    
    belongsTo.post = nil;    
    
    XCTAssertTrue([belongsTo remoteUpdate:&e],@"");
    XCTAssertNil(e, @"There should be no error with sending response marked with nil 'belongs_to' post");
    XCTAssertNil(belongsTo.post, @"belongsTo.post should still be nil");
    
    e = nil;
    
    XCTAssertTrue([post remoteFetch:&e],@"Should retrieve post just fine");
    XCTAssertTrue(post.responses.count == 0, @"Retrieved post should have 0 responses ('deleted' b-t)");
    
    //recreate belongsTo
    belongsTo.post = post;
    belongsTo.remoteID = nil;
    
    XCTAssertTrue([belongsTo remoteCreate:&e],@"");
    XCTAssertTrue([post remoteFetch:&e],@"Should retrieve post just fine");
    XCTAssertTrue(post.responses.count == 1, @"Retrieved post should have 1 responses (just recreated b-t)");
    
    
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
    
    XCTAssertFalse([dictionariesPost remoteCreate:&e],@"");
    XCTAssertNotNil(e, @"Should be error, since tried to send attrs without _attributes");
    XCTAssertNil(dictionariesPost.remoteID, @"Model ID shouldn't be present if there was an error on create...");
    
    e = nil;
    
    // on retrieve, it should set responses in dictionary form
    dictionariesPost.remoteID = post.remoteID;
    
    XCTAssertTrue([dictionariesPost remoteFetch:&e],@"e=%@",e);
    XCTAssertNil(e, @"There should've been no errors on the retrieve, even if no nested model defined.");
    XCTAssertEqual(dictionariesPost.responses.count, post.responses.count, @"Should still come back with same number of dicts as responses (1)");
    XCTAssertTrue([(dictionariesPost.responses)[0] isKindOfClass:[NSDictionary class]], @"Should've filled it with NSDictionaries. Got %@ instead",NSStringFromClass([dictionariesPost.responses[0] class]));
    
    e = nil;
    
    //testResponse will fail destroy
    XCTAssertThrowsSpecificNamed([testResponse remoteDestroy:&e], NSException, NSRNullRemoteIDException, @"testResponse object was never set an ID (since the retrieve only returned dictionaries), so it should throw an exception on destroy.");
    
    e = nil;
    
    //now, let's manually add it from the dictionary and destroy
    testResponse.remoteID = (dictionariesPost.responses)[0][@"id"];
    XCTAssertTrue([testResponse remoteDestroy:&e],@"");    
    XCTAssertNil(e, @"testResponse object should've been destroyed fine after manually setting ID from dictionary (nothing to do with nesting, just cleaning up)");
}

- (void) test_date_conversion
{    
    NSRAssertNoServer(noServer);
    
    Post *post = [[Post alloc] init];
    post.author = @"Author";
    post.content = @"test_date_conversion";
    
    NSError *e = nil;
    
    XCTAssertTrue([post remoteCreate:&e],@"");
    
    XCTAssertNil(e, @"There should be no error in remoteCreate");
    XCTAssertNotNil(post.updatedAt,@"updatedAt should've been set from remoteCreate");
    
    e = nil;
    
    //sleep to make a substantial difference in updated_at
    sleep(2);
    
    post.content = @"change";
    XCTAssertTrue([post remoteUpdate:&e],@"");
    
    XCTAssertNil(e,@"There should be no error in updating post");
    
    e = nil;
    
    XCTAssertTrue([post remoteFetch:&e],@"");
    
    XCTAssertNil(e, @"There should be no error in remoteFetch");
    XCTAssertNotNil(post.updatedAt,@"updatedAt should be present");
    
    XCTAssertTrue([post remoteDestroy:&e],@"");
    
    XCTAssertNil(e,@"There should be no problem remotely destroying post - just cleaning up.");
}

- (void) test_array_category
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSArray *a;

    a = [Post objectsWithRemoteDictionaries:array];
    XCTAssertNotNil(a, @"should still have 0 elements after empty array");
    XCTAssertTrue(a.count == 0, @"should still have 0 elements after empty array");

    [array addObject:@{@"id":@5,@"author":@"hi"}];
    [array addObject:@{@"id":@6,@"3f2f3f":@"hi"}];
    
    for (int i = 0; i < 2; i++)
    {
        a = [Post objectsWithRemoteDictionaries:array];
        
        XCTAssertTrue(a.count == 2, @"should still have X elements after translation");
        
        XCTAssertTrue([a[0] isKindOfClass:[Post class]], @"should be Post after translation");
        XCTAssertEqualObjects([a[0] remoteID],@(5), @"should have appropriate remoteID");
        XCTAssertEqualObjects([a[0] author],@"hi", @"should have appropriate property1");
        
        XCTAssertTrue([a[1] isKindOfClass:[Post class]], @"should be Post after translation");
        XCTAssertEqualObjects([a[1] remoteID],@(6), @"should have appropriate remoteID");
        XCTAssertNil([a[1] author],@"should have appropriate property1");
        
        [array addObject:@"str"];
    }
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
    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion3];
    
    // Run before each test method
}

- (void)tearDown 
{
    // Run after each test method
} 

@end