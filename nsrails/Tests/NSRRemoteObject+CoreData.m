//
//  NSRRemoteObject+CoreData.m
//  NSRails
//
//  Created by Dan Hassin on 5/27/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "NSRAsserts.h"


@interface Post : NSRRemoteObject

@property (nonatomic, strong) NSString *author, *content;
@property (nonatomic, strong) NSMutableSet *responses;

@end

@implementation Post
@synthesize author, content, responses;
NSRMap(*, responses:Response);

@end


@interface Response : NSRRemoteObject

@property (nonatomic, strong) NSString *content, *author;
@property (nonatomic, strong) Post *post;

@end

@implementation Response
@synthesize author, content, post;
NSRMap(*, post -b);

@end

@interface NSRRemoteObject_CoreData : SenTestCase

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


@implementation NSRRemoteObject_CoreData
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (void) test_coredata_enabled
{
	STAssertTrue([NSRRemoteObject isSubclassOfClass:[NSManagedObject class]], @"");
}

#ifdef NSR_USE_COREDATA

- (void) test_exceptions
{
	[[NSRConfig defaultConfig] setManagedObjectContext:nil];
	
	STAssertThrows([[Post alloc] initInserted], @"");
	STAssertThrows([[NSRRemoteObject alloc] initInserted], @"");
	STAssertThrows([[Post alloc] initWithCustomMap:nil customConfig:nil], @"");
	STAssertThrows([[Post alloc] initWithCustomMap:nil customConfig:[[NSRConfig alloc] initWithAppURL:@"hufihiufh"]], @"");
	
	Post *p = [[Post alloc] initInsertedIntoContext:__managedObjectContext];
	p.remoteID = NSRNumber(15);
	[p saveContext];
	
	Post *p2 = [[Post alloc] initInsertedIntoContext:__managedObjectContext];
	p2.remoteID = NSRNumber(15);
	STAssertThrows([p2 saveContext],@"");	
}

- (void) test_crud
{
	Post *p = [[Post alloc] initInserted];
	
	STAssertFalse(p.hasChanges, @"");

	p.author = @"hi";
	p.content = @"hello";
	p.remoteID = NSRNumber(15);
	
	STAssertTrue(p.hasChanges, @"");
	
	STAssertTrue([p remoteCreate:nil], @"");
	STAssertTrue(p == [Post findObjectWithRemoteID:NSRNumber(p.remoteID.integerValue)], @"should find obj with that ID (just made)");
	
	STAssertFalse(p.hasChanges, @"");

	
	Response *r = [[Response alloc] initInserted];
	r.author = @"yo";
	r.content = @"po";
	r.post = p;
	
	STAssertTrue([r remoteCreate:nil],@"");
	STAssertTrue(r == [Response findObjectWithRemoteID:NSRNumber(r.remoteID.integerValue)], @"should find obj with that ID (just made)");

	
	STAssertTrue([p remoteFetch:nil], @"");
	STAssertEquals(p.responses.count, (NSUInteger)1, @"");
	STAssertTrue([[p.responses anyObject] isKindOfClass:[Response class]], @"");
	STAssertTrue([p.responses anyObject] == r, @"");
	STAssertTrue([[p.responses anyObject] post] == p, @"");
	
	
	p.content = @"changed!";

	//TODO
	//Not even close to being an expert with CoreData... anyone know why this is failing?
	//STAssertTrue(p.isUpdated, @"");
	STAssertTrue([p remoteUpdate:nil], @"");
	STAssertFalse(p.hasChanges, @"");
	
	Post *retrieved = [Post findObjectWithRemoteID:NSRNumber(p.remoteID.integerValue)];
	STAssertTrue(p == retrieved, @"");
	STAssertEqualObjects(retrieved.content, p.content, @"");
	STAssertEqualObjects(retrieved.author, p.author, @"");
	
	STAssertTrue([p remoteDestroy:nil],@"");
	
	STAssertNil([Post findObjectWithRemoteID:p.remoteID], @"");
}

- (void) test_finds
{
	STAssertNil([Post findObjectWithRemoteID:NSRNumber(12)], @"should be nothing with rID 12");

	Post *p = [Post findOrInsertObjectUsingRemoteDictionary:NSRDictionary(NSRNumber(12),@"id")];
	
	STAssertNotNil(p, @"");
	STAssertEqualObjects(p.remoteID, NSRNumber(12), @"");
	STAssertFalse(p.hasChanges, @"");

	Post *p2 = [Post findObjectWithRemoteID:NSRNumber(12)];
	STAssertNotNil(p2,@"");
	STAssertTrue(p2 == p, @"");
	STAssertEqualObjects(p2.remoteID, NSRNumber(12), @"");
	STAssertFalse(p2.hasChanges, @"");

	Post *p3 = [Post findOrInsertObjectUsingRemoteDictionary:NSRDictionary(NSRNumber(12),@"id",@"hi",@"content")];
	
	STAssertNotNil(p3,@"");
	STAssertTrue(p3 == p2,@"");
	STAssertEqualObjects(p3.content, @"hi", @"");
	STAssertFalse(p3.hasChanges, @"");
	
	STAssertNil([Post findOrInsertObjectUsingRemoteDictionary:NSRDictionary(@"hi",@"content")], @"should be nil if no rID");
}

#endif

- (void) setUp
{
	[[NSRConfig defaultConfig] setManagedObjectContext:[self managedObjectContext]];
}

+ (void)setUp
{
	[[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
	[[NSRConfig defaultConfig] setAppUsername:@"NSRails"];
	[[NSRConfig defaultConfig] setAppPassword:@"iphone"];
}



- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:@"Test" withExtension:@"momd"];
	
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    return __managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }
        
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    [__persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
    
    return __persistentStoreCoordinator;
}

@end
