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

@interface NSRRemoteManagedObject (private)

- (NSManagedObjectContext *) managedObjectContext;
+ (NSManagedObjectContext *) getGlobalManagedObjectContextFromCmd:(SEL)cmd;

+ (id) findFirstObjectByAttribute:(NSString *)attrName withValue:(id)value inContext:(NSManagedObjectContext *)context;

@end

@implementation NSRRemoteManagedObject
@synthesize managedObject;

- (id) forwardingTargetForSelector:(SEL)aSelector
{
	if (![self respondsToSelector:aSelector] && [managedObject respondsToSelector:aSelector])
		return managedObject;
	
	return self;
}

#pragma mark - Overrides

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
	NSRelationshipDescription *cdRelation = [[managedObject.entity relationshipsByName] objectForKey:property];
	if (cdRelation)
	{
		Class class = NSClassFromString(cdRelation.destinationEntity.name);
		if (cdRelation.isToMany)
			return [NSRRelationship hasMany:class];
		if (cdRelation.maxCount == 1)
			return [NSRRelationship belongsTo:class];
	}

	return [super relationshipForProperty:property];
}


+ (id) objectWithRemoteDictionary:(NSDictionary *)dict
{
	NSRRemoteObject *obj = nil;
	
	NSNumber *objID = [dict objectForKey:@"id"];
	if (!objID)
		return nil;
	
	obj = [[self class] findObjectWithRemoteID:objID];
	
	if (obj)
	{
		[obj setPropertiesUsingRemoteDictionary:dict];
		return obj;
	}
	else
	{
		return [super objectWithRemoteDictionary:dict];
	}
	return obj;
}

- (id) init
{
	self = [self initInsertedIntoContext:[[self class] getGlobalManagedObjectContextFromCmd:_cmd]];
	
	return self;
}

- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict
{
	BOOL changes = [super setPropertiesUsingRemoteDictionary:dict];
	
	if (changes)
		[self saveContext];
	
	return changes;
}

#pragma mark - Overridden operations

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
		 
		 completionBlock(error);
	 }];
}

- (BOOL) remoteDestroy:(NSError **)error
{
	if (![super remoteDestroy:error])
		return NO;
	
	[self.managedObjectContext deleteObject:(id)self];
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
			 [self.managedObjectContext deleteObject:(id)self];
			 [self saveContext];
		 }
		 completionBlock(error);
	 }];
}

#pragma mark - Helpers

- (NSManagedObjectContext *) managedObjectContext
{
	return [managedObject managedObjectContext];
}

- (BOOL) saveContext 
{
	NSError *error = nil;
	
	if (![managedObject.managedObjectContext save:&error])
	{
		//TODO
		// maybe notify a client delegate to handle this error?
		// raise exception?
		
		NSLog(@"NSR Warning: Failed to save CoreData context with error %@", error);
		
		return NO;
	}
	else
	{
		return YES;
	}
}

+ (id) findObjectWithRemoteID:(NSNumber *)rID
{
	return [self findFirstObjectByAttribute:@"remoteID" 
								  withValue:rID
								  inContext:[self getGlobalManagedObjectContextFromCmd:_cmd]];
}

+ (id) findFirstObjectByAttribute:(NSString *)attrName withValue:(id)value inContext:(NSManagedObjectContext *)context
{
	NSString *str = NSStringFromClass([self class]);
	NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:str];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", attrName, value];
	fetch.predicate = predicate;
	fetch.fetchLimit = 1;
	
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:fetch error:&error];
	if (results.count > 0) 
	{
		return [results objectAtIndex:0];
	}
	return nil;
}

- (BOOL) validateRemoteID:(id *)value error:(NSError **)error 
{
	if ([*value intValue] == 0)
		return YES;
	
	NSString *str = NSStringFromClass([self class]);
	NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:str];
	fetch.includesPropertyValues = NO;
	fetch.fetchLimit = 1;
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteID == %@) && (self != %@)", *value, self];
	fetch.predicate = predicate;
	
	NSArray *results = [self.managedObjectContext executeFetchRequest:fetch error:NULL];
	
	if (results.count > 0)
	{
		NSString *reason = [NSString stringWithFormat:@"%@ with remoteID %@ already exists",self.class,*value];
		
		*error = [NSError errorWithDomain:NSRCoreDataException code:0 
								 userInfo:[NSDictionary dictionaryWithObject:reason forKey:NSLocalizedDescriptionKey]];
		
		return NO;
	}
	else
	{
		return YES;
	}
}

+ (NSManagedObjectContext *) getGlobalManagedObjectContextFromCmd:(SEL)cmd
{
	NSManagedObjectContext *ctx = [NSRConfig relevantConfigForClass:self].managedObjectContext;
	if (!ctx)
	{
		[NSException raise:NSRCoreDataException format:@"-[%@ %@] called when the current config's managedObjectContext is nil. A vaild managedObjectContext is necessary when using CoreData. Set your managed object context like so: [[NSRConfig defaultConfig] setManagedObjectContext:<#your moc#>].", self.class, NSStringFromSelector(cmd)];
	}
	return ctx;
}

- (id) initInsertedIntoContext:(NSManagedObjectContext *)context
{
	if (![self isKindOfClass:[NSManagedObject class]])
	{
		[NSException raise:NSRCoreDataException format:@"Trying to use NSRails with CoreData? Go in NSRails.h and uncomment `#define NSR_CORE_DATA`. You can also add NSR_USE_COREDATA to \"Preprocessor Macros Not Used in Precompiled Headers\" in your target's build settings."];
	}
	
	self = [NSEntityDescription insertNewObjectForEntityForName:[self.class description]
										 inManagedObjectContext:context];
	[self saveContext];
	
	return self;
}



@end
