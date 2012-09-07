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

#import "NSRRemoteManagedObject.h"
#import "NSRails.h"

@interface NSRRemoteObject (private_overrides)

- (Class) containerClassForRelationProperty:(NSString *)property;
- (NSNumber *) primitiveRemoteID;

@end

@implementation NSRRemoteManagedObject

#pragma mark - RemoteID CoreData getter/setters

- (void) setRemoteID:(NSNumber *)rID
{
	[self willChangeValueForKey:@"remoteID"];
	[(id)self setPrimitiveValue:rID forKey:@"remoteID"];
	[self didChangeValueForKey:@"remoteID"];
}

- (NSNumber *) remoteID
{
	[(id)self willAccessValueForKey:@"remoteID"];
	NSNumber *rID = [self primitiveRemoteID];
	[(id)self didAccessValueForKey:@"remoteID"];
	return rID;
}

#pragma mark - Behavior overrides

+ (id) objectWithRemoteDictionary:(NSDictionary *)dictionary
{
	NSRRemoteManagedObject *obj = nil;
	
	NSNumber *objID = [dictionary objectForKey:@"id"];
	
	if (objID)
		obj = [self findObjectWithRemoteID:objID];
	
	if (!obj)
		obj = [[self alloc] initInserted];

	[obj setPropertiesUsingRemoteDictionary:dictionary];
	
	return obj;
}

- (Class) containerClassForRelationProperty:(NSString *)property
{
	BOOL ordered = [[[[(id)self entity] propertiesByName] objectForKey:property] isOrdered];
	return ordered ? [NSMutableOrderedSet class] : [NSMutableSet class];
}

#pragma mark - New overridables

+ (NSString *) entityName
{
	return [self description];
}

#pragma mark - Standard overrides

- (Class) nestedClassForProperty:(NSString *)property
{
	NSDictionary *relationships = [[(id)self entity] relationshipsByName];
	if (relationships.count > 0)
	{
		NSRelationshipDescription *cdRelation = [relationships objectForKey:property];
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
	if (![super remoteFetch:error])
		return NO;
	
	[self saveContext];
	return YES;
}

- (void) remoteFetchAsync:(NSRBasicCompletionBlock)completionBlock
{
	[super remoteFetchAsync:
	 ^(NSError *error)
	 {
		 if (!error)
			 [self saveContext];
		 
		 if (completionBlock)
			 completionBlock(error);
	 }];
}

- (BOOL) remoteCreate:(NSError **)error
{
	if (![super remoteCreate:error])
		return NO;
	
	[self saveContext];
	return YES;
}

- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[super remoteCreateAsync:
	 ^(NSError *error)
	 {
		 if (!error)
			 [self saveContext];
		 
		 if (completionBlock)
			 completionBlock(error);
	 }];
}

- (BOOL) remoteUpdate:(NSError **)error
{
	if (![super remoteUpdate:error])
		return NO;
	
	[self saveContext];
	return YES;
}

- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[super remoteUpdateAsync:
	 ^(NSError *error)
	 {
		 if (!error)
			 [self saveContext];
		 
		 if (completionBlock)
			 completionBlock(error);
	 }];
}

- (BOOL) remoteReplace:(NSError **)error
{
	if (![super remoteReplace:error])
		return NO;
	
	[self saveContext];
	return YES;
}

- (void) remoteReplaceAsync:(NSRBasicCompletionBlock)completionBlock
{
	[super remoteReplaceAsync:
	 ^(NSError *error)
	 {
		 if (!error)
			 [self saveContext];
		 
		 if (completionBlock)
			 completionBlock(error);
	 }];
}

- (BOOL) remoteDestroy:(NSError **)error
{
	if (![super remoteDestroy:error])
		return NO;
	
	[[(id)self managedObjectContext] deleteObject:(id)self];
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
			 [[(id)self managedObjectContext] deleteObject:(id)self];
			 [self saveContext];
		 }
		 if (completionBlock)
			 completionBlock(error);
	 }];
}


#pragma mark - Helpers

- (BOOL) saveContext 
{
	NSError *error = nil;
	if (![[(id)self managedObjectContext] save:&error])
	{
		//TODO
		// maybe notify a client delegate to handle this error?
		// raise exception?
		
		NSLog(@"NSR Warning: Failed to save CoreData context with error %@", error);
	}
	
	return !error;
}

+ (id) findObjectWithRemoteID:(NSNumber *)rID
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
		[NSException raise:NSRCoreDataException format:@"Trying to use NSRails with CoreData? Go in NSRails.h and uncomment `#define NSR_CORE_DATA`. You can also add NSR_USE_COREDATA to \"Preprocessor Macros Not Used in Precompiled Headers\" in your target's build settings. If you're in RubyMotion, change \":target => 'NSRails'\" to \":target => 'NSRailsCD'\" in your Rakefile."];
	}
	
	NSManagedObjectContext *context = [[self class] getGlobalManagedObjectContextFromCmd:_cmd];
	self = [NSEntityDescription insertNewObjectForEntityForName:[self.class entityName]
										 inManagedObjectContext:context];
	
	return self;
}

- (BOOL) validatesRemoteIDUniqueness
{
	return ([self.primitiveRemoteID intValue] != 0 && [[(id)self changedValues] objectForKey:@"remoteID"]);
}

- (BOOL) validateRemoteID:(id *)value error:(NSError **)error
{
	if (![self validatesRemoteIDUniqueness])
		return YES;
	
	NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:self.class.entityName];
	fetch.includesPropertyValues = NO;
	fetch.fetchLimit = 1;
	fetch.predicate = [NSPredicate predicateWithFormat:@"(remoteID == %@) && (self != %@)", *value, self];
	
	NSArray *results = [[(id)self managedObjectContext] executeFetchRequest:fetch error:NULL];
	
	if (results.count > 0)
	{
		if (error)
		{
			*error = [NSError errorWithDomain:NSRCoreDataException
										 code:0
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ with remoteID %@ already exists",self.class,*value] forKey:NSLocalizedDescriptionKey]];
		}
		
		return NO;
	}
	else
	{
		return YES;
	}
}


@end
