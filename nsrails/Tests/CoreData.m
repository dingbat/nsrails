//
//  CoreData.m
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
/*
#import "NSRAsserts.h"

@interface CoreData : SenTestCase

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CoreData
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (void) test_exceptions
{
	[[NSRConfig defaultConfig] setManagedObjectContext:nil];
	
	STAssertThrows([[CDPost alloc] initInserted], @"");
	STAssertThrows([[NSRRemoteManagedObject alloc] initInserted], @"");
	
	CDPost *p = [[CDPost alloc] initInsertedIntoContext:__managedObjectContext];
	p.remoteID = NSRNumber(15);
	[p saveContext];
	
	CDPost *p2 = [[CDPost alloc] initInsertedIntoContext:__managedObjectContext];
	p2.remoteID = NSRNumber(15);
	STAssertThrows([p2 saveContext],@"");	
}

- (void) test_crud
{
	CDPost *p = [[CDPost alloc] initInserted];
	
	STAssertFalse(p.managedObject.hasChanges, @"");
	
	p.author = @"hi";
	p.content = @"hello";
	p.remoteID = NSRNumber(15);
	
	STAssertTrue(p.managedObject.hasChanges, @"");
	
	STAssertTrue([p remoteCreate:nil], @"");
	STAssertTrue(p == [CDPost findObjectWithRemoteID:NSRNumber(p.remoteID.integerValue)], @"should find obj with that ID (just made)");
	
	STAssertFalse(p.managedObject.hasChanges, @"");
	
	
	CDResponse *r = [[CDResponse alloc] initInserted];
	r.author = @"yo";
	r.content = @"po";
	r.post = p;
	
	STAssertTrue([r remoteCreate:nil],@"");
	STAssertTrue(r == [CDResponse findObjectWithRemoteID:NSRNumber(r.remoteID.integerValue)], @"should find obj with that ID (just made)");
	
	
	STAssertTrue([p remoteFetch:nil], @"");
	STAssertEquals(p.responses.count, (NSUInteger)1, @"");
	STAssertTrue([[p.responses anyObject] isKindOfClass:[CDResponse class]], @"");
	STAssertTrue([p.responses anyObject] == r, @"");
	STAssertTrue([[p.responses anyObject] post] == p, @"");
	
	
	p.content = @"changed!";
	
	//TODO
	//Not even close to being an expert with CoreData... anyone know why this is failing?
	//STAssertTrue(p.isUpdated, @"");
	STAssertTrue([p remoteUpdate:nil], @"");
	STAssertFalse(p.managedObject.hasChanges, @"");
	
	CDPost *retrieved = [CDPost findObjectWithRemoteID:NSRNumber(p.remoteID.integerValue)];
	STAssertTrue(p == retrieved, @"");
	STAssertEqualObjects(retrieved.content, p.content, @"");
	STAssertEqualObjects(retrieved.author, p.author, @"");
	
	STAssertTrue([p remoteDestroy:nil],@"");
	
	STAssertNil([CDPost findObjectWithRemoteID:p.remoteID], @"");
}

- (void) test_finds
{
	STAssertNil([CDPost findObjectWithRemoteID:NSRNumber(12)], @"should be nothing with rID 12");
	
	CDPost *p = [CDPost objectWithRemoteDictionary:NSRDictionary(NSRNumber(12),@"id")];
	
	STAssertNotNil(p, @"");
	STAssertEqualObjects(p.remoteID, NSRNumber(12), @"");
	STAssertFalse(p.managedObject.hasChanges, @"");
	
	CDPost *p2 = [CDPost findObjectWithRemoteID:NSRNumber(12)];
	STAssertNotNil(p2,@"");
	STAssertTrue(p2 == p, @"");
	STAssertEqualObjects(p2.remoteID, NSRNumber(12), @"");
	STAssertFalse(p2.managedObject.hasChanges, @"");
	
	CDPost *p3 = [CDPost objectWithRemoteDictionary:NSRDictionary(NSRNumber(12),@"id",@"hi",@"content")];
	
	STAssertNotNil(p3,@"");
	STAssertTrue(p3 == p2,@"");
	STAssertEqualObjects(p3.content, @"hi", @"");
	STAssertFalse(p3.managedObject.hasChanges, @"");
	
	STAssertNil([CDPost objectWithRemoteDictionary:NSRDictionary(@"hi",@"content")], @"should be nil if no rID");
}

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

@end*/
