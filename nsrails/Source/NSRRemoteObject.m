/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRRemoteObject.m
 
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

#import "NSRRemoteObject.h"

#import "NSData+Additions.h"
#import "NSString+Inflection.h"

#import <objc/runtime.h>


////////////////////////////////////////////////////////////////////////////////////////////////////

@interface NSRRemoteObject (NSRailsInternal)

+ (NSRConfig *) getRelevantConfig;

- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped fromNesting:(BOOL)nesting;

- (NSManagedObjectContext *) managedObjectContext;
+ (NSManagedObjectContext *) getGlobalManagedObjectContextFromCmd:(SEL)cmd;

+ (id) findFirstObjectByAttribute:(NSString *)attrName withValue:(id)value inContext:(NSManagedObjectContext *)context;

@end

///////////////////////////////////

//Expose private NSRConfig method for detecting any "use" blocks
@interface NSRConfig (internal)

+ (NSRConfig *) overrideConfig;
+ (NSRConfig *) configForClass:(Class)class;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation NSRRemoteObject
@synthesize remoteDestroyOnNesting, remoteAttributes;
_NSR_REMOTEID_SYNTH remoteID;

#pragma mark - Meta-NSR stuff

+ (NSRConfig *) getRelevantConfig
{
	if ([NSRConfig overrideConfig])
		return [NSRConfig overrideConfig];
	
	if ([NSRConfig configForClass:self])
		return [NSRConfig configForClass:self];
	
	return [NSRConfig defaultConfig];
}

#pragma mark - Overrides

+ (NSString *) remoteModelName
{
	if (self == [NSRRemoteObject class])
		return nil;
	
	//Default behavior is to return name of this class
	
	NSString *class = NSStringFromClass(self);
	
	if ([self getRelevantConfig].autoinflectsClassNames)
	{
		return [class nsr_stringByUnderscoringIgnoringPrefix:[self getRelevantConfig].ignoresClassPrefixes];
	}
	else
	{
		return class;
	}
}

+ (NSString *) remoteControllerName
{
	NSString *singular = [self remoteModelName];
	
	//Default behavior is to return pluralized model name
	
	//Arbitrary pluralization - should probably support more
	if ([singular isEqualToString:@"person"])
		return @"people";
	
	if ([singular isEqualToString:@"Person"])
		return @"People";
	
	if ([singular hasSuffix:@"y"] && ![singular hasSuffix:@"ey"])
		return [[singular substringToIndex:singular.length-1] stringByAppendingString:@"ies"];
	
	if ([singular hasSuffix:@"s"])
		return [singular stringByAppendingString:@"es"];
	
	return [singular stringByAppendingString:@"s"];
}

+ (NSMutableDictionary *) remoteProperties
{
	unsigned int propertyCount;
	
	objc_property_t *properties = class_copyPropertyList(self, &propertyCount);
	if (properties)
	{
		NSMutableDictionary *results = [NSMutableDictionary dictionaryWithCapacity:propertyCount];
		
		while (propertyCount--)
		{
			//get each ivar name/type and add it to the results
			NSString *prop = [NSString stringWithCString:property_getName(properties[propertyCount]) encoding:NSASCIIStringEncoding];
			NSString *atts = [NSString stringWithCString:property_getAttributes(properties[propertyCount]) encoding:NSASCIIStringEncoding];
			
			NSString *type = nil;
			
			for (NSString *att in [atts componentsSeparatedByString:@","])
				if ([att hasPrefix:@"T"])
					type = [att substringFromIndex:1];
			
			if (type)
			{
				type = [[type stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByReplacingOccurrencesOfString:@"@" withString:@""];
				
				[results setObject:type forKey:prop];
			}
		}
		
		free(properties);	
		return results;
	}
	return nil;
}

- (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)verb
{
	return nil;
}

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
#ifdef NSR_USE_COREDATA
	NSRelationshipDescription *cdRelation = [[self.entity relationshipsByName] objectForKey:property];
	if (cdRelation)
	{
		Class class = NSClassFromString(cdRelation.destinationEntity.name);
		if (cdRelation.isToMany)
			return [NSRRelationship hasMany:class];
		if (cdRelation.maxCount == 1)
			return [NSRRelationship belongsTo:class];
	}
#endif
	
	Class propType = NSClassFromString([[self.class remoteProperties] objectForKey:property]);
	if ([propType isSubclassOfClass:[NSRRemoteObject class]])
	{
		return [NSRRelationship belongsTo:propType];
	}
	
	return nil;
}

- (id) encodeValueForProperty:(NSString *)key
{	
	NSRRelationship *relationship = [self relationshipForProperty:key];
		
	id val = [self valueForKey:key];
	
	//if the ivar is an array, we need to make every element into JSON and then put them back in the array
	//this is done before the next 'if' becuase Rails will get angry if you send it a nil array - has to be empty
	if ([val isKindOfClass:[NSArray class]] || [val isKindOfClass:[NSSet class]] || [val isKindOfClass:[NSOrderedSet class]])
	{
		NSMutableArray *new = [NSMutableArray arrayWithCapacity:[val count]];
		
		for (id element in val)
		{
			id encodedObj = element;
			
			//if it's an NSRRemoteObject, we can use its remoteDictionaryRepresentationWrapped
			if ([element isKindOfClass:[NSRRemoteObject class]])
			{
				encodedObj = [element remoteDictionaryRepresentationWrapped:NO fromNesting:YES];
			}
			else if ([element isKindOfClass:[NSDate class]])
			{
				encodedObj = [[self.class getRelevantConfig] stringFromDate:element];
			}
			
			[new addObject:encodedObj];
		}
		
		return new;
	}
	
	if (val)
	{
		if (relationship)
		{
			//if it's belongs_to, only return the ID
			if (relationship.isBelongsTo)
				return [val remoteID];
			
			return [val remoteDictionaryRepresentationWrapped:NO fromNesting:YES];
		}
		
		if ([val isKindOfClass:[NSDate class]])
		{
			return [[self.class getRelevantConfig] stringFromDate:val];
		}
	}

	return val;
}

- (void) decodeValue:(id)railsObject forProperty:(NSString *)key change:(BOOL *)change
{
	NSRRelationship *relationship = [self relationshipForProperty:key];
	NSString *type = [[self.class.remoteProperties objectForKey:key] lowercaseString];
	BOOL isDate = ([type isEqualToString:@"date"] || 
				   [type isEqualToString:@"nsdate"] || 
				   [type isEqualToString:@"datetime"]);
	
	id previousVal = [self valueForKey:key];
	id decodedObj = nil;
	
	if (railsObject)
	{
		if (relationship.isToMany)
		{
			BOOL changes = NO;
			
			BOOL checkForChange = ([railsObject count] == [previousVal count]);
			if (!checkForChange)
				changes = YES;
			
			id newArray = [[NSMutableArray alloc] init];
		
			//array of NSRRemoteObjects is tricky, we need to go through each existing element, see if it needs an update (or delete), and then add any new ones
			
			id previousArray = ([previousVal isKindOfClass:[NSSet class]] ? 
								[previousVal allObjects] :
								[previousVal isKindOfClass:[NSOrderedSet class]] ?
								[previousVal array] :
								previousVal);
			
			for (id railsElement in railsObject)
			{
				id decodedElement;
				
				//see if there's a nester that matches this ID - we'd just have to update it w/this dict
				NSNumber *railsID = [railsElement objectForKey:@"id"];
				id existing = nil;
				
				if (railsID)
					existing = [[previousArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"remoteID == %@",railsID]] lastObject];
				
				if (!existing)
				{
					//didn't previously exist - make a new one
					decodedElement = [relationship.class findOrInsertObjectUsingRemoteDictionary:railsElement];
					
					changes = YES;
				}
				else
				{
					//existed - simply update that one (recursively)
					decodedElement = existing;
					BOOL neededChange = [decodedElement setPropertiesUsingRemoteDictionary:railsElement];
					
					if (neededChange)
						changes = YES;
				}
				
				[newArray addObject:decodedElement];
			}
			
#ifdef NSR_USE_COREDATA
			BOOL ordered = [[[self.entity propertiesByName] objectForKey:property.name] isOrdered];
			
			if (ordered)
				newArray = [NSMutableOrderedSet orderedSetWithArray:newArray];
			else
				newArray = [NSMutableSet setWithArray:newArray];
#endif
			
			*change = changes;
		}
		else if (isDate)
		{
			decodedObj = [[self.class getRelevantConfig] dateFromString:railsObject];
			
			//account for any discrepancies between NSDate object and a string (which doesn't include milliseconds) 
			if (fabs([decodedObj timeIntervalSinceDate:previousVal]) > 1.25)
			{
				*change = YES;
			}
		}
		else if (relationship)
		{
			//if the nested object didn't exist before, make it & set it
			if (!previousVal)
			{
				decodedObj = [relationship.class findOrInsertObjectUsingRemoteDictionary:railsObject];
			}
			//otherwise, keep the old object & only mark as change if its properties changed (recursive)
			else
			{
				decodedObj = previousVal;
				
				*change = [decodedObj setPropertiesUsingRemoteDictionary:railsObject];
			}
		}
		//otherwise, if not nested or anything, just use what we got (number, string, dictionary, array)
		else
		{
			decodedObj = railsObject;
		}
	}
	
	[self setValue:decodedObj forKey:key];
}

- (BOOL) shouldSendProperty:(NSString *)property onRequest:(NSRRequest *)request
{
	BOOL nested = (self != request.destinationObject);
	
	//don't include id if it's nil or on the main object (nested guys need their IDs)
	if ([property isEqualToString:@"remoteID"] && (!self.remoteID || !nested))
		return NO;

	NSRRelationship *relationship = [self relationshipForProperty:property];
	
	if (relationship)
	{
		if (nested && !relationship.isBelongsTo)
		{
			//this is recursion-protection. we don't want to include every nested class in this class because one of those nested class could nest us, causing infinite loop
			//  we are safe to include all nestedclasses on top-level (if not from within nesting)
			//  if we are a class being nested, we have to be careful - only inlude nestedclass attrs that were defined with -n
			//     except if belongs-to, since then attrs aren't being included - just "_id"

			return NO;
		}
		
		id val = [self valueForKey:property];
		
		//if it's an _attributes and either there's no val, don't send (is okay on belongs_to bc we send a null id)
		if (!relationship.isBelongsTo && !val)
		{
			return NO;
		}
	}
	
	return YES;
}

- (NSString *) remoteEquivalenceForProperty:(NSString *)property
{
	return nil;
}

- (NSString *) remoteKeyForProperty:(NSString *)property
{
	NSString *bidirectional = [self remoteEquivalenceForProperty:property];
	if (bidirectional)
		return bidirectional;
	
	NSString *key;
	
	if ([self.class getRelevantConfig].autoinflectsPropertyNames)
		key = [property nsr_stringByUnderscoring];
	else
		key = property;
	
	// append stuff to nested properties
	NSRRelationship *relationship = [self relationshipForProperty:key];
	if (relationship)
	{
		if (relationship.isBelongsTo)
			key = [key stringByAppendingString:@"_id"];
		else
			key = [key stringByAppendingString:@"_attributes"];
	}
	
	return key;
}

- (NSString *) propertyForRemoteKey:(NSString *)remoteProp
{
	NSString *bidirectional = [self remoteEquivalenceForProperty:remoteProp];
	if (bidirectional)
		return bidirectional;

	if ([self.class getRelevantConfig].autoinflectsPropertyNames)
		return [remoteProp nsr_stringByCamelizing];
	
	return remoteProp;
}

#pragma mark - Internal NSR stuff

- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict
{
	remoteAttributes = dict;
	
	//support JSON that comes in like {"post"=>{"something":"something"}}
	NSDictionary *innerDict = [dict objectForKey:[self.class remoteModelName]];
	if (dict.count == 1 && [innerDict isKindOfClass:[NSDictionary class]])
	{
		dict = innerDict;
	}
	
	BOOL changes = NO;
	
	for (NSString *railsProperty in dict)
	{
		NSString *property = [self propertyForRemoteKey:railsProperty];

		id railsObject = [dict objectForKey:railsProperty];
		if (railsObject == [NSNull null])
			railsObject = nil;
		
		BOOL isKVC = [self respondsToSelector:NSSelectorFromString(property)];
		id previousVal;
		
		if (isKVC)
		{
			previousVal = [self valueForKey:property];
		}

		BOOL change = -1;
		[self decodeValue:railsObject forProperty:property change:&change];
		
		if (isKVC)
		{
			id newVal = [self valueForKey:property];
			
			//means it wasn't set by decodeValue:::, so do the default check - straight equality
			if (change == -1)
			{
				//if it existed before but now nil, mark change
				if (!newVal && previousVal)
				{
					change = YES;
				}
				else if (newVal)
				{
					change = ![newVal isEqual:previousVal];
				}
			}
		}

		if (change > 0)
			changes = YES;
	}
	
	if (changes && self.managedObjectContext)
	{
		[self saveContext];
	}
	
	return changes;
}

- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped
{
	return [self remoteDictionaryRepresentationWrapped:wrapped fromNesting:NO];
}

- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped fromNesting:(BOOL)nesting
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	for (NSString *objcProperty in [self.class remoteProperties])
	{
		if (![self shouldSendProperty:objcProperty nested:nesting])
			continue;
		
		NSString *railsEquivalent = [self remoteKeyForProperty:objcProperty];
		
		id remoteRep = [self encodeValueForProperty:objcProperty];
		if (!remoteRep)
			remoteRep = [NSNull null];
		
		BOOL JSONParsable = ([remoteRep isKindOfClass:[NSArray class]] ||
							 [remoteRep isKindOfClass:[NSDictionary class]] ||
							 [remoteRep isKindOfClass:[NSString class]] ||
							 [remoteRep isKindOfClass:[NSNumber class]] ||
							 [remoteRep isKindOfClass:[NSNull class]]);
		
		if (!JSONParsable)
		{
			[NSException raise:NSRJSONParsingException format:@"Trying to encode property '%@' in class '%@', but the result (%@) was not JSON-parsable. Override -[NSRRemoteObject encodeValueForProperty:] if you want to encode a property that's not NSDictionary, NSArray, NSString, NSNumber, or NSNull. Remember to call super if it doesn't need custom encoding.",objcProperty, self.class, remoteRep];
		}
		
		
		[dict setObject:remoteRep forKey:railsEquivalent];
	}
	
	if (remoteDestroyOnNesting)
	{
		[dict setObject:[NSNumber numberWithBool:YES] forKey:@"_destroy"];
	}
	
	if (wrapped)
		return [NSDictionary dictionaryWithObject:dict forKey:[self.class remoteModelName]];
	
	return dict;
}

- (id) initWithRemoteDictionary:(NSDictionary *)railsDict
{
#ifdef NSR_USE_COREDATA
	self = [self initInserted];
#else
	self = [super init];
#endif
	
	if (self)
	{
		[self setPropertiesUsingRemoteDictionary:railsDict];
	}
	
	return self;
}

#pragma mark - Create

- (BOOL) remoteCreate:(NSError **)error
{
	NSDictionary *jsonResponse = [[NSRRequest requestToCreateObject:self] sendSynchronous:error];

	if (jsonResponse)
		[self setPropertiesUsingRemoteDictionary:jsonResponse];
	
	return !!jsonResponse;
}

- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToCreateObject:self] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
		 if (result)
			 [self setPropertiesUsingRemoteDictionary:result];
		 
		 completionBlock(error);
	 }];
}


#pragma mark Update

- (BOOL) remoteUpdate:(NSError **)error
{
	if (![[NSRRequest requestToUpdateObject:self] sendSynchronous:error])
		return NO;
	
	[self saveContext];
	return YES;
}

- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToUpdateObject:self] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
		 if (result)
		 {
			 [self saveContext];
		 }
		 completionBlock(error);
	 }];
}

#pragma mark Replace

- (BOOL) remoteReplace:(NSError **)error
{
	if (![[NSRRequest requestToReplaceObject:self] sendSynchronous:error])
		return NO;
	
	[self saveContext];
	return YES;
}

- (void) remoteReplaceAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToReplaceObject:self] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
		 if (result)
		 {
			 [self saveContext];
		 }
		 completionBlock(error);
	 }];
}

#pragma mark Destroy

- (BOOL) remoteDestroy:(NSError **)error
{
	if (![[NSRRequest requestToDestroyObject:self] sendSynchronous:error])
		return NO;
	
	[self.managedObjectContext deleteObject:(id)self];
	[self saveContext];
	return YES;
}

- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToDestroyObject:self] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
		 if (result)
		 {
			 [self.managedObjectContext deleteObject:(id)self];
			 [self saveContext];
		 }
		 completionBlock(error);
	 }];
}

#pragma mark Get latest

- (BOOL) remoteFetch:(NSError **)error changes:(BOOL *)changesPtr
{
	NSDictionary *jsonResponse = [[NSRRequest requestToFetchObject:self] sendSynchronous:error];
	
	if (!jsonResponse)
	{
		if (changesPtr)
			*changesPtr = NO;
		return NO;
	}
	
	BOOL changes = [self setPropertiesUsingRemoteDictionary:jsonResponse];
	if (changesPtr)
		*changesPtr = changes;
	
	return YES;
}

- (BOOL) remoteFetch:(NSError **)error
{
	return [self remoteFetch:error changes:NULL];
}

- (void) remoteFetchAsync:(NSRFetchCompletionBlock)completionBlock
{
	[[NSRRequest requestToFetchObject:self] sendAsynchronous:
	 ^(id jsonRep, NSError *error) 
	 {
		 BOOL change = NO;
		 if (jsonRep)
			 change = [self setPropertiesUsingRemoteDictionary:jsonRep];
		 completionBlock(change, error);
	 }];
}

#pragma mark Get specific object (class-level)

+ (id) remoteObjectWithID:(NSNumber *)mID error:(NSError **)error
{
	NSDictionary *objData = [[NSRRequest requestToFetchObjectWithID:mID ofClass:self] sendSynchronous:error];
	
	if (objData)
	{
		return [[self class] findOrInsertObjectUsingRemoteDictionary:objData];
	}
	
	return nil;
}

+ (void) remoteObjectWithID:(NSNumber *)mID async:(NSRFetchObjectCompletionBlock)completionBlock
{
	[[NSRRequest requestToFetchObjectWithID:mID ofClass:self] sendAsynchronous:
	 ^(id jsonRep, NSError *error) 
	 {
		 if (!jsonRep)
		 {
			 completionBlock(nil, error);
		 }
		 else
		 {
			 id obj = [[self class] findOrInsertObjectUsingRemoteDictionary:jsonRep];
			 completionBlock(obj, nil);
		 }
	 }];
}

#pragma mark Get all objects (class-level)

+ (NSArray *) remoteAll:(NSError **)error
{
	return [self remoteAllViaObject:nil error:error];
}

+ (NSArray *) remoteAllViaObject:(NSRRemoteObject *)obj error:(NSError **)error
{
    id json = [[NSRRequest requestToFetchAllObjectsOfClass:self viaObject:obj] sendSynchronous:error];
    if (!json)
		return nil;
	
	[json translateRemoteDictionariesIntoInstancesOfClass:self.class];
    
    return json;
}

+ (void) remoteAllAsync:(NSRFetchAllCompletionBlock)completionBlock
{
	[self remoteAllViaObject:nil async:completionBlock];
}

+ (void) remoteAllViaObject:(NSRRemoteObject *)obj async:(NSRFetchAllCompletionBlock)completionBlock
{
    [[NSRRequest requestToFetchAllObjectsOfClass:self viaObject:obj] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
		 if (result)
			 [result translateRemoteDictionariesIntoInstancesOfClass:[self class]];

		 completionBlock(result,error);
	 }];
}


#pragma mark - CoreData Helpers

- (NSManagedObjectContext *) managedObjectContext
{
#ifdef NSR_USE_COREDATA
	return [super managedObjectContext];
#else
	return nil;
#endif
}

- (BOOL) saveContext 
{
	NSError *error = nil;
	
	if (self.managedObjectContext) 
	{
		if (![self.managedObjectContext save:&error])
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
	return NO;
}

+ (id) findOrInsertObjectUsingRemoteDictionary:(NSDictionary *)dict
{
	NSRRemoteObject *obj = nil;
	
#ifdef NSR_USE_COREDATA
	NSNumber *objID = [dict objectForKey:@"id"];
	if (!objID)
		return nil;
	
	obj = [[self class] findObjectWithRemoteID:objID];
	
	if (obj)
		[obj setPropertiesUsingRemoteDictionary:dict];
#endif
	
	if (!obj)
	{
		obj = [[[self class] alloc] initWithRemoteDictionary:dict];
	}
	return obj;
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

+ (NSManagedObjectContext *) getGlobalManagedObjectContextFromCmd:(SEL)cmd
{
	NSManagedObjectContext *ctx = [self.class getRelevantConfig].managedObjectContext;
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

- (id) initInserted
{
	self = [self initInsertedIntoContext:[[self class] getGlobalManagedObjectContextFromCmd:_cmd]];
	
	return self;
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

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		self.remoteID = [aDecoder decodeObjectForKey:@"remoteID"];
		remoteAttributes = [aDecoder decodeObjectForKey:@"remoteAttributes"];
		self.remoteDestroyOnNesting = [aDecoder decodeBoolForKey:@"remoteDestroyOnNesting"];
		
		customProperties = [aDecoder decodeObjectForKey:@"customProperties"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.remoteID forKey:@"remoteID"];
	[aCoder encodeObject:remoteAttributes forKey:@"remoteAttributes"];
	[aCoder encodeBool:remoteDestroyOnNesting forKey:@"remoteDestroyOnNesting"];
	
	[aCoder encodeObject:customProperties forKey:@"customProperties"];
}

@end

