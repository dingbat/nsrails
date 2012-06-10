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

#import "NSRPropertyCollection.h"

#import "NSData+Additions.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface NSRRemoteObject (NSRailsInternal)

+ (NSRConfig *) getRelevantConfig;
- (NSRConfig *) getRelevantConfig;
+ (NSRConfig *) getRelevantConfigFromPropertyCollection:(NSRPropertyCollection *)propertyCollection;

+ (NSRPropertyCollection *) propertyCollection;
- (NSRPropertyCollection *) propertyCollection;

- (NSRRemoteObject *) makeRelevantModelFromClass:(NSString *)classN basedOn:(NSDictionary *)dict;
- (id) remoteRepresentationOfObjectForProperty:(NSRProperty *)prop;

+ (NSString *) NSRMap;

+ (NSString *) masterNSRMapWithOverrideString:(NSString *)override;
+ (NSString *) masterNSRMap;

+ (id) performSelectorWithoutClimbingHierarchy:(SEL)selector;

- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped fromNesting:(BOOL)nesting;

- (NSManagedObjectContext *) managedObjectContext;
+ (NSManagedObjectContext *) getGlobalManagedObjectContextFromCmd:(SEL)cmd;

+ (id) findFirstObjectByAttribute:(NSString *)attrName withValue:(id)value inContext:(NSManagedObjectContext *)context;

@end

@interface NSRRemoteObject (NSRDateHelper)

//will return if difference between dates is greater than 1.25 seconds (to account for truncation)
- (BOOL) significantChangeBetweenDate:(NSDate *)date andDate:(NSDate *)date2;

@end

@interface NSRRemoteObject (NSRNoClimb)

//these methods will ONLY look for the method in the receiver, not going up to super

//returns nil if method not implemented in receiver
+ (id) performSelectorWithoutClimbingHierarchy:(SEL)selector;
+ (BOOL) respondsToSelectorWithoutClimbingHierarchy:(SEL)selector;

@end

@interface NSRRemoteObject (NSRIntrospection)

//returns an array of all properties declared in class
+ (NSArray *) allProperties;

//returns type of the given property for that instance variable (ie, NSString)
+ (NSString *) typeForProperty:(NSString *)property;

@end

@interface NSRProperty (NSRInflection)

+ (NSString *) underscoredString:(NSString *)string stripPrefix:(BOOL)stripPrefix;

@end


///////////////////////////////////

//Quick NSObject category to "pose" as NSManagedObject (so Xcode doesn't get angry when building without CoreData)
@interface NSObject (NSRCoreData)

- (id) managedObjectContext;

@end

//Expose private NSRConfig method for detecting any "use" blocks
@interface NSRConfig (internal)

+ (NSRConfig *) overrideConfig;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation NSRRemoteObject
@synthesize remoteDestroyOnNesting, remoteAttributes;
_NSR_REMOTEID_SYNTH remoteID;

#pragma mark - Meta-NSR stuff

//returns the sync string expanded (* => all properties) & inherited (adds NSRMaps from superclasses)
//override string is in case there's a custom sync string defined
+ (NSString *) masterNSRMapWithOverrideString:(NSString *)override
{
	//base case
	if (self == [NSRRemoteObject class])
		return @"remoteID=id";
	
	NSString *mapStr = (override ? override : [self performSelectorWithoutClimbingHierarchy:@selector(NSRMap)]);
	
	// If no NSRMap declared in that class, default to *
	if (!mapStr)
		mapStr = @"*";
	
	if ([mapStr rangeOfString:@"*"].location != NSNotFound)
	{
		mapStr = [mapStr stringByReplacingOccurrencesOfString:@"*" withString:@""];
		
		//expand the star to everything in the class
		NSString *expanded = [self.allProperties componentsJoinedByString:@", "];
		if (expanded)
		{
			//properties need to be appended to existing sync string since they can be overridden like with -x (and stripped of *)
			mapStr = [mapStr stringByAppendingFormat:@", %@", expanded];
		}
	}
	
	if ([mapStr rangeOfString:_NSRNoCarryFromSuper_STR].location != NSNotFound)
	{
		mapStr = [mapStr stringByReplacingOccurrencesOfString:_NSRNoCarryFromSuper_STR withString:@""];
		
		//skip right up the hierarchy to NSRRemoteObject
		return [mapStr stringByAppendingFormat:@", %@", [NSRRemoteObject masterNSRMapWithOverrideString:nil]];
	}
	
	//traverse up the hierarchy (always getting the default NSRMap)
	return [mapStr stringByAppendingFormat:@", %@", [self.superclass masterNSRMapWithOverrideString:nil]];
}

+ (NSString *) masterNSRMap
{
	return [self masterNSRMapWithOverrideString:nil];
}

+ (NSRPropertyCollection *) propertyCollection
{
	static NSMutableDictionary *propertyCollections = nil;
	static dispatch_once_t onceToken;
	
	//singleton initializer
    dispatch_once(&onceToken, ^{
		propertyCollections = [[NSMutableDictionary alloc] init];
    });
	
	NSString *class = NSStringFromClass(self);
	NSRPropertyCollection *collection = [propertyCollections objectForKey:class];
	if (!collection)
	{
		collection = [[NSRPropertyCollection alloc] initWithClass:self syncString:[self masterNSRMap]];
		
		[propertyCollections setObject:collection forKey:class];
	}
	
	return collection;
}

- (NSRPropertyCollection *) propertyCollection
{
	if (customProperties)
		return customProperties;
	
	return [[self class] propertyCollection];
}

+ (NSRConfig *) getRelevantConfigFromPropertyCollection:(NSRPropertyCollection *)propertyCollection
{	
	//if there's an overriding config in this context (an -[NSRConfig use] was called (explicitly or implicity via a block))
	if ([NSRConfig overrideConfig])
	{
		return [NSRConfig overrideConfig];
	}
	
	//if this class/instance has a custom config, use it over the default
	else if (propertyCollection.customConfig)
	{
		return propertyCollection.customConfig;
	}
	
	//otherwise, use the default config
	else
	{
		return [NSRConfig defaultConfig];
	}
}

+ (NSRConfig *) getRelevantConfig
{
	return [self getRelevantConfigFromPropertyCollection:[self propertyCollection]];
}

- (NSRConfig *) getRelevantConfig
{
	if (!customProperties)
		return [[self class] getRelevantConfig];
	
	return [[self class] getRelevantConfigFromPropertyCollection:customProperties];
}


- (id) initWithCustomMap:(NSString *)str customConfig:(NSRConfig *)config
{
#ifdef NSR_USE_COREDATA
	NSRConfig *relevantConfig;
	if (config)
		relevantConfig = config;
	else
		relevantConfig = [[self class] getRelevantConfig];
	
	NSManagedObjectContext *moc = relevantConfig.managedObjectContext;
	if (!moc && config)
	{
		[NSException raise:NSRCoreDataException format:@"Custom config provided to -[%@ initWithCustomMap:customConfig:] doesn't have a managedObjectContext set. This is necessary when using CoreData.",self.class];
	}
	self = [self initInsertedIntoContext:moc];
#else
	self = [super init];
#endif
	
	if (self)
	{
		//apply inheritance rules etc to the given string
		str = [[self class] masterNSRMapWithOverrideString:str];
		
		customProperties = [[NSRPropertyCollection alloc] initWithClass:[self class] syncString:str];
		customProperties.customConfig = config;
	}
	return self;
}

- (id) initWithCustomMap:(NSString *)str
{
	self = [self initWithCustomMap:str customConfig:nil];
	return self;
}

#pragma mark - Overrides

+ (NSString *) remoteModelName //(overridable)
{
	if (self == [NSRRemoteObject class])
		return nil;
	
	//Default behavior is to return name of this class
	
	NSString *class = NSStringFromClass(self);
	
	if ([self getRelevantConfig].autoinflectsClassNames)
	{
		return [NSRProperty underscoredString:class stripPrefix:[self getRelevantConfig].ignoresClassPrefixes];
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

- (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)verb
{
	return nil;
}

- (id) encodeValueForProperty:(NSString *)key
{	
	NSRProperty *prop = [[self propertyCollection].properties objectForKey:key];
	
	id val = [self valueForKey:prop.name];
	
	//if the ivar is an array, we need to make every element into JSON and then put them back in the array
	//this is done before the next 'if' becuase Rails will get angry if you send it a nil array - has to be empty
	if (prop.isArray)
	{
		NSMutableArray *new = [NSMutableArray arrayWithCapacity:[val count]];
		
		for (id element in val)
		{
			id encodedObj = element;
			
			//if it's an NSRRemoteObject, we can use its dictionaryOfRemoteProperties
			if ([element isKindOfClass:[NSRRemoteObject class]])
			{
				encodedObj = [element remoteDictionaryRepresentationWrapped:NO fromNesting:YES];
			}
			else if ([element isKindOfClass:[NSDate class]])
			{
				encodedObj = [[self getRelevantConfig] stringFromDate:element];
			}
			
			[new addObject:encodedObj];
		}
		
		return new;
	}
	
	if (val)
	{
		if (prop.nestedClass)
		{
			//if it's belongs_to, only return the ID
			if (prop.isBelongsTo)
				return [val remoteID];
			
			return [val remoteDictionaryRepresentationWrapped:NO fromNesting:YES];
		}
		
		if (prop.isDate)
		{
			return [[self getRelevantConfig] stringFromDate:val];
		}
	}

	return val;
}

// Helper method used when decoding remote nested properties
- (NSRRemoteObject *) makeRelevantModelFromClass:(NSString *)classN basedOn:(NSDictionary *)dict
{
	Class objClass = NSClassFromString(classN);
	NSRRemoteObject *obj = [objClass findOrInsertObjectUsingRemoteDictionary:dict];
	
	//see if we can assign an association to its parent (self)
	NSString *parentModelName = [[self class] remoteModelName];
	NSArray *properties = [[obj propertyCollection] objcPropertiesForRemoteEquivalent:parentModelName 
																		  autoinflect:[self getRelevantConfig].autoinflectsPropertyNames];
	
	for (NSRProperty *property in properties)
	{
		//only assign me to the child if it has me defined as a property and it's marked as nested to me
		if (property.retrievable &&
			[property.nestedClass isEqualToString:[self.class description]])
		{
			[obj setValue:self forKey:property.name];
		}
	}
	
	return obj;
}

- (void) decodeValue:(id)railsObject forProperty:(NSString *)key change:(BOOL *)change
{
	NSRProperty *property = [[self propertyCollection].properties objectForKey:key];
	
	id previousVal = [self valueForKey:key];
	id decodedObj = nil;
	
	if (railsObject)
	{
		//custom-encode if it's a datearray or if it's an array of nested classes
		if (property.isHasMany || (property.isDate && property.isArray))
		{
			BOOL changes = NO;
			
			BOOL checkForChange = ([railsObject count] == [previousVal count]);
			if (!checkForChange)
				changes = YES;
			
			id newArray = [[NSMutableArray alloc] init];
			
			if (property.nestedClass)
			{							
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
						decodedElement = [self makeRelevantModelFromClass:property.nestedClass basedOn:railsElement];
						
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
				
			}
			else if (property.isDate)
			{
				//array of NSDates
				for (int i = 0; i < [railsObject count]; i++)
				{
					id railsElement = [railsObject objectAtIndex:i];
					NSDate *newDate = [[self getRelevantConfig] dateFromString:railsElement];
					[newArray addObject:newDate];
					
					if (checkForChange)
					{
						NSDate *oldDate = [previousVal objectAtIndex:i];
						
						if ([self significantChangeBetweenDate:newDate andDate:oldDate])
							changes = YES;
					}
				}
			}
			decodedObj = newArray;
			*change = changes;
		}
		else if (property.isDate)
		{
			decodedObj = [[self getRelevantConfig] dateFromString:railsObject];
			
			*change = [self significantChangeBetweenDate:decodedObj andDate:previousVal];
		}
		else if (property.nestedClass)
		{
			//if the nested object didn't exist before, make it & set it
			if (!previousVal)
			{
				decodedObj = [self makeRelevantModelFromClass:property.nestedClass basedOn:railsObject];
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

- (BOOL) shouldSendProperty:(NSString *)property nested:(BOOL)nested
{
	NSRProperty *objcProperty = [[self propertyCollection].properties objectForKey:property];
	
	//this is recursion-protection. we don't want to include every nested class in this class because one of those nested class could nest us, causing infinite loop
	//  we are safe to include all nestedclasses on top-level (if not from within nesting)
	//  if we are a class being nested, we have to be careful - only inlude nestedclass attrs that were defined with -n
	//     except if belongs-to, since then attrs aren't being included - just "_id"

	if (nested && objcProperty.nestedClass && !objcProperty.belongsTo && !objcProperty.includedOnNesting)
		return NO;
	
	//don't include id if it's nil or on the main object (nested guys need their IDs)
	if ([property isEqualToString:@"remoteID"] && (!self.remoteID || !nested))
		return NO;
	
	//legacy support
	if (!objcProperty.sendable)
		return NO;
	
	return YES;
}

#pragma mark - Internal NSR stuff

- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict
{
	remoteAttributes = dict;
	
	//support JSON that comes in like {"post"=>{"something":"something"}}
	NSDictionary *innerDict = [dict objectForKey:[[self class] remoteModelName]];
	if (dict.count == 1 && [innerDict isKindOfClass:[NSDictionary class]])
	{
		dict = innerDict;
	}
	
	BOOL changes = NO;
	
	for (NSString *railsProperty in dict)
	{
		NSArray *equivalents = [[self propertyCollection] objcPropertiesForRemoteEquivalent:railsProperty 
																				autoinflect:[self getRelevantConfig].autoinflectsPropertyNames];
		
		//loop through just in case there are multiple objcProps set to retrieve same remoteEquiv
		for (NSRProperty *property in equivalents)
		{
			if (!property.retrievable)
				continue;
			
			id railsObject = [dict objectForKey:railsProperty];
			if (railsObject == [NSNull null])
				railsObject = nil;
			
			id previousVal = [self valueForKey:property.name];

			BOOL change = -1;
			[self decodeValue:railsObject forProperty:property.name change:&change];
			
			id newVal = [self valueForKey:property.name];
			
			//means it wasn't set by decodeValue:::, so do the default check - straight equality
			if (change == -1)
			{
				change = NO;
				
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

			if (change)
				changes = YES;
		}
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
	
	for (NSRProperty *objcProperty in [self propertyCollection].properties.allValues)
	{
		if (![self shouldSendProperty:objcProperty.name nested:nesting])
			continue;
		
		NSString *railsEquivalent = objcProperty.remoteEquivalent;
		if (!railsEquivalent)
		{
			if ([NSRConfig defaultConfig].autoinflectsPropertyNames)
			{
				railsEquivalent = [NSRProperty underscoredString:objcProperty.name stripPrefix:NO];
			}
			else
			{
				railsEquivalent = objcProperty.name;
			}
			
			if (objcProperty.isBelongsTo)
			{
				railsEquivalent = [railsEquivalent stringByAppendingString:@"_id"];
			}
			else if (objcProperty.nestedClass)
			{
				railsEquivalent = [railsEquivalent stringByAppendingString:@"_attributes"];
			}
		}
		
		id remoteRep = [self encodeValueForProperty:objcProperty.name];
		if (!remoteRep)
			remoteRep = [NSNull null];
		
		BOOL JSONParsable = ([remoteRep isKindOfClass:[NSArray class]] ||
							 [remoteRep isKindOfClass:[NSDictionary class]] ||
							 [remoteRep isKindOfClass:[NSString class]] ||
							 [remoteRep isKindOfClass:[NSNumber class]] ||
							 [remoteRep isKindOfClass:[NSNull class]]);
		
		if (!JSONParsable)
		{
			[NSException raise:NSRJSONParsingException format:@"Trying to encode property '%@' in class '%@', but the result (%@) was not JSON-parsable. Override -[NSRRemoteObject encodeValueForProperty:] if you want to encode a property that's not NSDictionary, NSArray, NSString, NSNumber, or NSNull. Remember to call super if it doesn't need custom encoding.",objcProperty.name, [self class], remoteRep];
		}
		
		
		[dict setObject:remoteRep forKey:railsEquivalent];
	}
	
	if (remoteDestroyOnNesting)
	{
		[dict setObject:[NSNumber numberWithBool:YES] forKey:@"_destroy"];
	}
	
	if (wrapped)
		return [NSDictionary dictionaryWithObject:dict forKey:[[self class] remoteModelName]];
	
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
		id obj = [[self class] findOrInsertObjectUsingRemoteDictionary:objData];
		return obj;
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
	
	[json translateRemoteDictionariesIntoInstancesOfClass:[self class]];
    
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
		 if (!result)
		 {
			 completionBlock(nil, error);
		 }
		 else
		 {
			 [result translateRemoteDictionariesIntoInstancesOfClass:[self class]];

			 completionBlock(result,error);
		 }
	 }];
}


#pragma mark - CoreData Helpers

- (NSManagedObjectContext *) managedObjectContext
{
	if ([self isKindOfClass:[NSManagedObject class]])
		return [super managedObjectContext];
	
	return nil;
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
		
		if (error)
			*error = [NSError errorWithDomain:NSRCoreDataException code:0 userInfo:[NSDictionary dictionaryWithObject:reason forKey:NSLocalizedDescriptionKey]];
		
		//Should this even throw an exception?
		[NSException raise:NSRCoreDataException format:reason];
		
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


//=======================================
#pragma mark - Helper implementations
//=======================================

@implementation NSRRemoteObject (NSRDateHelper)

- (BOOL) significantChangeBetweenDate:(NSDate *)date andDate:(NSDate *)date2
{
	return (fabs([date timeIntervalSinceDate:date2]) > 1.25);
}

@end

@implementation NSRRemoteObject (NSRNoClimb)

//this will suppress the compiler warnings that come with ARC when using performSelector
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

// This is a trick to make sure ONLY THIS class declares `selector`, and no superclasses
//   It's hard to tell because the method gets transparently forwarded to superclass if not found
// This method actually compares both class's implementations of the method, and if identical (ie, it inherits), ignore it
+ (id) performSelectorWithoutClimbingHierarchy:(SEL)selector
{
	if ([self respondsToSelectorWithoutClimbingHierarchy:selector])
		return [self performSelector:selector];
	
	return nil;
}

+ (BOOL) respondsToSelectorWithoutClimbingHierarchy:(SEL)selector
{
	if ([self respondsToSelector:selector])
	{
		IMP mine = [self methodForSelector:selector]; //will find superclass if necessary
		IMP supe = [self.superclass methodForSelector:selector];
		
		if (mine != supe)
			return YES;
	}
	return NO;
}

//pop the warning suppressor defined above
#pragma clang diagnostic pop

@end


#import <objc/runtime.h>

@implementation NSRRemoteObject (NSRIntrospection)

+ (NSArray *) allProperties
{
	unsigned int propertyCount;
	//copy all properties for self (will be a Class)
	objc_property_t *properties = class_copyPropertyList(self, &propertyCount);
	if (properties)
	{
		NSMutableArray *results = [NSMutableArray arrayWithCapacity:propertyCount];
		
		while (propertyCount--)
		{
			//get each ivar name and add it to the results
			const char *propName = property_getName(properties[propertyCount]);
			NSString *prop = [NSString stringWithCString:propName encoding:NSASCIIStringEncoding];
			[results addObject:prop];
		}
		
		free(properties);	
		return results;
	}
	return nil;
}

+ (NSString *) getAttributeForProperty:(NSString *)prop prefix:(NSString *)attrPrefix
{
	objc_property_t property = class_getProperty(self, [prop UTF8String]);
	if (!property)
		return nil;
	
	// This will return some garbage like "Ti,GgetFoo,SsetFoo:,Vproperty"
	// See https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
	
	NSString *atts = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
	
	for (NSString *att in [atts componentsSeparatedByString:@","])
		if ([att hasPrefix:attrPrefix])
			return [att substringFromIndex:1];
	
	return nil;
}

+ (NSString *) typeForProperty:(NSString *)property
{
	return [self getAttributeForProperty:property prefix:@"T"];
}

@end

