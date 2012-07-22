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
	if (shouldNotValidateUniqueness)
		return NO;
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
	
	STAssertThrows(([[CDPost alloc] initInserted]), @"");
	STAssertThrows([[NSRRemoteManagedObject alloc] initInserted], @"");

	[[NSRConfig defaultConfig] setManagedObjectContext:__managedObjectContext];

	CDPost *p = [[CDPost alloc] initInserted];
	p.remoteID = NSRNumber(15);
	[p saveContext];
}

- (void) test_crud
{
	NSError *e = nil;
	[[[NSRRequest GET] routeTo:@"404.html"] sendSynchronous:&e];
	NSRAssertNoServer([[e domain] isEqualToString:NSURLErrorDomain]);

	
	CDPost *p = [[CDPost alloc] initInserted];
	
	//shouldn't save the context
	STAssertTrue(p.hasChanges, @"");
	
	p.remoteID = NSRNumber(15);
	
	STAssertTrue(p.hasChanges, @"");
	
	[p setPropertiesUsingRemoteDictionary:[NSDictionary dictionaryWithObjectsAndKeys:@"hi", @"author", @"hello", @"content", nil]];
	
	STAssertTrue(p.hasChanges, @"");
	
	STAssertTrue([p remoteCreate:nil], @"");
	STAssertTrue(p == [CDPost findObjectWithRemoteID:NSRNumber(p.remoteID.integerValue)], @"should find obj with that ID (just made)");
	
	STAssertFalse(p.hasChanges, @"");
	
	
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
	STAssertEquals([[p.responses anyObject] post], p, @"");
	
	
	p.content = @"changed!";
	
	STAssertTrue(p.isUpdated, @"");
	STAssertTrue([p remoteUpdate:nil], @"");
	STAssertFalse(p.hasChanges, @"");
	
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
	STAssertTrue(p.hasChanges, @"");
	
	CDPost *p2 = [CDPost findObjectWithRemoteID:NSRNumber(12)];
	STAssertNotNil(p2,@"");
	STAssertTrue(p2 == p, @"");
	STAssertEqualObjects(p2.remoteID, NSRNumber(12), @"");
	STAssertTrue(p2.hasChanges, @"");
	
	CDPost *p3 = [CDPost objectWithRemoteDictionary:NSRDictionary(NSRNumber(12),@"id",@"hi",@"content")];
	
	STAssertNotNil(p3,@"");
	STAssertTrue(p3 == p2,@"");
	STAssertEqualObjects(p3.content, @"hi", @"");
	STAssertTrue(p3.hasChanges, @"");
	
	CDPost *p4 = [CDPost objectWithRemoteDictionary:NSRDictionary(@"hi",@"content")];
	
	STAssertNotNil(p4,@"");
	STAssertEqualObjects(p4.remoteID, NSRNumber(0), nil);
	STAssertEqualObjects(p4.content, @"hi", @"");
	STAssertTrue(p4.hasChanges, @"");
}

- (void) test_remote_id_uniqueness_validation
{
	CDPost *p = [[CDPost alloc] initInserted];
	p.remoteID = NSRNumber(99);
	
	STAssertTrue([p saveContext],nil);
	
	CDPost *p2 = [[CDPost alloc] initInserted];
	p2.remoteID = NSRNumber(99);
	
	STAssertFalse([p2 saveContext],nil);
}

- (void) test_no_remote_id_uniqueness_validation
{
	CDPost *p = [[CDPost alloc] initInserted];
	p.remoteID = NSRNumber(99);
	
	STAssertTrue([p saveContext],nil);
	
	CDPost *p2 = [[CDPost alloc] initInserted];
	p2.remoteID = NSRNumber(99);
	p2.shouldNotValidateUniqueness = YES;
	
	STAssertTrue([p2 saveContext],nil);
}

- (void) test_nested_class_override
{
	CDPost *p = [CDPost objectWithRemoteDictionary:NSRDictionary(NSRNumber(12),@"id")];
	CDResponse *r = [CDResponse objectWithRemoteDictionary:NSRDictionary(NSRNumber(12),@"id")];
	
	Class responseClass = [p nestedClassForProperty:@"responses"];
	STAssertEquals(responseClass, [CDResponse class], nil);

	Class postClass = [r nestedClassForProperty:@"post"];
	STAssertEquals(postClass, [CDPost class], nil);
}

- (void) test_container_class_override
{
	CDPost *p = [CDPost objectWithRemoteDictionary:NSRDictionary(NSRNumber(12),@"id")];

	Class unorderedClass = [p containerClassForRelationProperty:@"responses"];
	STAssertEquals(unorderedClass, [NSMutableSet class], nil);

	Class orderedClass = [p containerClassForRelationProperty:@"orderedResponses"];
	STAssertEquals(orderedClass, [NSMutableOrderedSet class], nil);
}



/////////////////////////////////////////////

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
