/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRRemoteManagedObject.m
 
 Copyright (c) 2012 Dan Hassin.
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <NSRails/NSRails.h>
#import <CoreData/CoreData.h>

NSString * const NSRCoreDataException = @"NSRCoreDataException";

@interface NSRRemoteObject (private_overrides)

- (Class) containerClassForRelationProperty:(NSString *)property;
- (NSNumber *) primitiveRemoteID;

@end

@implementation NSRRemoteManagedObject

#pragma mark - RemoteID CoreData getter/setters

- (void) setRemoteID:(NSNumber *)rID
{
    [self willChangeValueForKey:@"remoteID"];
    [self setPrimitiveValue:rID forKey:@"remoteID"];
    [self didChangeValueForKey:@"remoteID"];
}

- (NSNumber *) remoteID
{
    [self willAccessValueForKey:@"remoteID"];
    NSNumber *rID = [self primitiveRemoteID];
    [self didAccessValueForKey:@"remoteID"];
    return rID;
}

#pragma mark - Behavior overrides

+ (instancetype) objectWithRemoteDictionary:(NSDictionary *)dictionary
{
    NSRRemoteManagedObject *obj = nil;
    
    NSNumber *objID = dictionary[@"id"];
    
    if (objID) {
        obj = [self findObjectWithRemoteID:objID];
    }
    
    if (!obj) {
        obj = [[self alloc] initInserted];
    }

    [obj setPropertiesUsingRemoteDictionary:dictionary];
    
    return obj;
}

- (Class) containerClassForRelationProperty:(NSString *)property
{
    BOOL ordered = [self.entity.propertiesByName[property] isOrdered];
    return ordered ? [NSMutableOrderedSet class] : [NSMutableSet class];
}

#pragma mark - New overridables

+ (NSString *) entityName
{
    return NSStringFromClass(self);
}

- (BOOL) validatesRemoteIDUniqueness
{
    return ([self.primitiveRemoteID intValue] != 0 && self.changedValues[@"remoteID"]);
}

#pragma mark - Standard overrides

- (Class) nestedClassForProperty:(NSString *)property
{
    NSDictionary *relationships = self.entity.relationshipsByName;
    if (relationships.count > 0)
    {
        NSRelationshipDescription *cdRelation = relationships[property];
        if (cdRelation)
        {
            Class class = NSClassFromString(cdRelation.destinationEntity.managedObjectClassName);
            return class;
        }
    }
    
    return [super nestedClassForProperty:property];
}

#pragma mark - Overridden operations (w/coredata)

- (BOOL) remoteFetch:(NSError *__autoreleasing *)error
{
    if (![super remoteFetch:error]) {
        return NO;
    }
    
    [self saveContext];
    return YES;
}

- (void) remoteFetchAsync:(NSRBasicCompletionBlock)completionBlock
{
    [super remoteFetchAsync:
     ^(NSError *error)
     {
         if (!error) {
             [self saveContext];
         }
         
         if (completionBlock) {
             completionBlock(error);
         }
     }];
}

- (BOOL) remoteCreate:(NSError **)error
{
    if (![super remoteCreate:error]) {
        return NO;
    }
    
    [self saveContext];
    return YES;
}

- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock
{
    [super remoteCreateAsync:
     ^(NSError *error)
     {
         if (!error) {
             [self saveContext];
         }
         
         if (completionBlock) {
             completionBlock(error);
         }
     }];
}

- (BOOL) remoteUpdate:(NSError **)error
{
    if (![super remoteUpdate:error]) {
        return NO;
    }
    
    [self saveContext];
    return YES;
}

- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock
{
    [super remoteUpdateAsync:
     ^(NSError *error)
     {
         if (!error) {
             [self saveContext];
         }
         
         if (completionBlock) {
             completionBlock(error);
         }
     }];
}

- (BOOL) remoteReplace:(NSError **)error
{
    if (![super remoteReplace:error]) {
        return NO;
    }
    
    [self saveContext];
    return YES;
}

- (void) remoteReplaceAsync:(NSRBasicCompletionBlock)completionBlock
{
    [super remoteReplaceAsync:
     ^(NSError *error)
     {
         if (!error) {
             [self saveContext];
         }
         
         if (completionBlock) {
             completionBlock(error);
         }
     }];
}

- (BOOL) remoteDestroy:(NSError **)error
{
    if (![super remoteDestroy:error]) {
        return NO;
    }
    
    [self.managedObjectContext deleteObject:self];
    [self saveContext];
    return YES;
}

- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock
{
    [super remoteDestroyAsync:
     ^(NSError *error) 
     {
         if (!error)
         {
             [self.managedObjectContext deleteObject:self];
             [self saveContext];
         }
         if (completionBlock) {
             completionBlock(error);
         }
     }];
}


#pragma mark - Helpers

- (NSError *) saveContext
{
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    return error;
}

+ (instancetype) findObjectWithRemoteID:(NSNumber *)rID
{
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:self.entityName];
    fetch.predicate = [NSPredicate predicateWithFormat:@"remoteID == %@", rID];
    fetch.fetchLimit = 1;
    
    NSManagedObjectContext *context = [self getGlobalManagedObjectContextFromCmd:_cmd];
    
    NSArray *results = [context executeFetchRequest:fetch error:nil];
    return [results lastObject];
}

+ (NSManagedObjectContext *) getGlobalManagedObjectContextFromCmd:(SEL)cmd
{
    NSManagedObjectContext *ctx = [self config].managedObjectContext;
    if (!ctx)
    {
        [NSException raise:NSRCoreDataException format:@"-[%@ %@] called when the current config's managedObjectContext is nil. A vaild managedObjectContext is necessary when using CoreData. Set your managed object context like so: [[NSRConfig defaultConfig] setManagedObjectContext:<#your moc#>].", self.class, NSStringFromSelector(cmd)];
    }
    return ctx;
}

- (id) initInserted
{
    if (![self isKindOfClass:[NSManagedObject class]])
    {
        [NSException raise:NSRCoreDataException format:@"Trying to use NSRails with CoreData? With CocoaPods, use pod 'NSRails/CoreData' instead of pod 'NSRails'. Otherwise, add `#define NSR_USE_COREDATA` to your precompiled header file, or add NSR_USE_COREDATA to \"Preprocessor Macros\" in your target's build settings. If you're in RubyMotion, change \":target => 'NSRails'\" to \":target => 'NSRailsCD'\" in your Rakefile."];
    }
    
    NSManagedObjectContext *context = [[self class] getGlobalManagedObjectContextFromCmd:_cmd];
    self = [NSEntityDescription insertNewObjectForEntityForName:[self.class entityName]
                                         inManagedObjectContext:context];
    
    return self;
}

- (BOOL) validateRemoteID:(id *)value error:(NSError **)error
{
    if (![self validatesRemoteIDUniqueness]) {
        return YES;
    }
    
    NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:self.class.entityName];
    fetch.includesPropertyValues = NO;
    fetch.fetchLimit = 1;
    fetch.predicate = [NSPredicate predicateWithFormat:@"(remoteID == %@) && (self != %@)", *value, self];
    
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetch error:NULL];
    
    if (results.count > 0)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:NSRCoreDataException
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ with remoteID %@ already exists",self.class,*value]}];
        }
        
        return NO;
    }
    else
    {
        return YES;
    }
}


@end
