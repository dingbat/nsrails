//
//  CoreData.m
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRAsserts.h"

@interface NSRRemoteObject (private_overrides)

- (Class) containerClassForRelationProperty:(NSString *)property;

@end

/** CoreData Mock Classes **/

@interface CDPost : NSRRemoteManagedObject

@property (nonatomic, strong) NSString *author, *content;
@property (nonatomic, strong) NSSet *responses;

@property BOOL shouldNotValidateUniqueness;

@end

@interface CDResponse : NSRRemoteManagedObject

@property (nonatomic, strong) NSString *content, *author;
@property (nonatomic, strong) CDPost *post;

@end

@implementation CDPost
@dynamic author, content, responses;
@synthesize shouldNotValidateUniqueness;

- (BOOL) validatesRemoteIDUniqueness
{
    if (shouldNotValidateUniqueness) {
        return NO;
    }
    return [super validatesRemoteIDUniqueness];
}

+ (NSString *) entityName
{
    return @"Post";
}

@end

@implementation CDResponse
@dynamic author, content, post;

+ (NSString *) entityName
{
    return @"Response";
}

- (BOOL) shouldOnlySendIDKeyForNestedObjectProperty:(NSString *)property
{
    return [property isEqualToString:@"post"];
}

@end


/******** **********/

@interface CoreData : XCTestCase

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CoreData

- (void) test_exceptions
{
    [[NSRConfig defaultConfig] setManagedObjectContext:nil];
    
    XCTAssertThrows(([[CDPost alloc] initInserted]), @"");
    XCTAssertThrows([[NSRRemoteManagedObject alloc] initInserted], @"");

    [[NSRConfig defaultConfig] setManagedObjectContext:self.managedObjectContext];

    CDPost *p = [[CDPost alloc] initInserted];
    p.remoteID = @(15);
    [p saveContext];
}

- (void) test_crud
{
    //test server is rails 3
    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion3];
    
    NSError *e = nil;
    [[[NSRRequest GET] routeTo:@"404.html"] sendSynchronous:&e];
    NSRAssertNoServer([[e domain] isEqualToString:NSURLErrorDomain]);

    
    CDPost *p = [[CDPost alloc] initInserted];
    
    //shouldn't save the context
    XCTAssertTrue(p.hasChanges, @"");
    
    p.remoteID = @(15);
    
    XCTAssertTrue(p.hasChanges, @"");
    
    [p setPropertiesUsingRemoteDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"hi", @"author", @"hello", @"content", nil]];
    
    XCTAssertTrue(p.hasChanges, @"");
    
    XCTAssertTrue([p remoteCreate:nil], @"");
    XCTAssertTrue(p == [CDPost findObjectWithRemoteID:@(p.remoteID.integerValue)], @"should find obj with that ID (just made)");
    
    XCTAssertFalse(p.hasChanges, @"");
    
    
    CDResponse *r = [[CDResponse alloc] initInserted];
    r.author = @"yo";
    r.content = @"po";
    r.post = p;
    
    XCTAssertTrue([r remoteCreate:nil],@"");
    XCTAssertTrue(r == [CDResponse findObjectWithRemoteID:@(r.remoteID.integerValue)], @"should find obj with that ID (just made)");
    
    
    XCTAssertTrue([p remoteFetch:nil], @"");
    XCTAssertEqual(p.responses.count, (NSUInteger)1, @"");
    XCTAssertTrue([[p.responses anyObject] isKindOfClass:[CDResponse class]], @"");
    XCTAssertTrue([p.responses anyObject] == r, @"");
    XCTAssertEqual((CDPost *)[[p.responses anyObject] post], p, @"");
    
    
    p.content = @"changed!";
    
    XCTAssertTrue(p.isUpdated, @"");
    XCTAssertTrue([p remoteUpdate:nil], @"");
    XCTAssertFalse(p.hasChanges, @"");
    
    CDPost *retrieved = [CDPost findObjectWithRemoteID:@(p.remoteID.integerValue)];
    XCTAssertTrue(p == retrieved, @"");
    XCTAssertEqualObjects(retrieved.content, p.content, @"");
    XCTAssertEqualObjects(retrieved.author, p.author, @"");
    
    XCTAssertTrue([p remoteDestroy:nil],@"");
    
    XCTAssertNil([CDPost findObjectWithRemoteID:p.remoteID], @"");
}

- (void) test_finds
{
    XCTAssertNil([CDPost findObjectWithRemoteID:@(12)], @"should be nothing with rID 12");
    
    CDPost *p = [CDPost objectWithRemoteDictionary:@{@"id":@12}];
    
    XCTAssertNotNil(p, @"");
    XCTAssertEqualObjects(p.remoteID, @(12), @"");
    XCTAssertTrue(p.hasChanges, @"");
    
    CDPost *p2 = [CDPost findObjectWithRemoteID:@(12)];
    XCTAssertNotNil(p2,@"");
    XCTAssertTrue(p2 == p, @"");
    XCTAssertEqualObjects(p2.remoteID, @(12), @"");
    XCTAssertTrue(p2.hasChanges, @"");
    
    CDPost *p3 = [CDPost objectWithRemoteDictionary:@{@"id":@12,@"content":@"hi"}];
    
    XCTAssertNotNil(p3,@"");
    XCTAssertTrue(p3 == p2,@"");
    XCTAssertEqualObjects(p3.content, @"hi", @"");
    XCTAssertTrue(p3.hasChanges, @"");
    
    CDPost *p4 = [CDPost objectWithRemoteDictionary:@{@"content":@"hi"}];
    
    XCTAssertNotNil(p4,@"");
    XCTAssertEqualObjects(p4.remoteID, @(0));
    XCTAssertEqualObjects(p4.content, @"hi", @"");
    XCTAssertTrue(p4.hasChanges, @"");
}

- (void) test_remote_id_uniqueness_validation
{
    CDPost *p = [[CDPost alloc] initInserted];
    p.remoteID = @(99);
    
    XCTAssertNil([p saveContext]);
    
    CDPost *p2 = [[CDPost alloc] initInserted];
    p2.remoteID = @(99);
    
    XCTAssertNotNil([p2 saveContext]);
}

- (void) test_no_remote_id_uniqueness_validation
{
    CDPost *p = [[CDPost alloc] initInserted];
    p.remoteID = @(99);
    
    XCTAssertNil([p saveContext]);
    
    CDPost *p2 = [[CDPost alloc] initInserted];
    p2.remoteID = @(99);
    p2.shouldNotValidateUniqueness = YES;
    
    XCTAssertNil([p2 saveContext]);
}

- (void) test_nested_class_override
{
    CDPost *p = [CDPost objectWithRemoteDictionary:@{@"id":@12}];
    CDResponse *r = [CDResponse objectWithRemoteDictionary:@{@"id":@12}];
    
    Class responseClass = [p nestedClassForProperty:@"responses"];
    XCTAssertEqual(responseClass, [CDResponse class]);

    Class postClass = [r nestedClassForProperty:@"post"];
    XCTAssertEqual(postClass, [CDPost class]);
}

- (void) test_container_class_override
{
    CDPost *p = [CDPost objectWithRemoteDictionary:@{@"id":@12}];

    Class unorderedClass = [p containerClassForRelationProperty:@"responses"];
    XCTAssertEqual(unorderedClass, [NSMutableSet class]);

    Class orderedClass = [p containerClassForRelationProperty:@"orderedResponses"];
    XCTAssertEqual(orderedClass, [NSMutableOrderedSet class]);
}



/////////////////////////////////////////////

- (void) setUp
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:@"Test" withExtension:@"momd"];
    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
    
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    [self.managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];

    [[NSRConfig defaultConfig] setManagedObjectContext:self.managedObjectContext];
}

+ (void)setUp
{
    [[NSRConfig defaultConfig] setRootURL:[NSURL URLWithString:@"http://localhost:3000"]];
    [[NSRConfig defaultConfig] setBasicAuthUsername:@"NSRails"];
    [[NSRConfig defaultConfig] setBasicAuthPassword:@"iphone"];
}


@end
