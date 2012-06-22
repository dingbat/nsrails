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

#import "NSRails.h"

#import "NSString+Inflection.h"
#import <objc/runtime.h>


////////////////////////////////////////////////////////////////////////////////////////////////////

@interface NSRRemoteObject (private)

- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped fromNesting:(BOOL)nesting;

- (BOOL) propertyIsTimestamp:(NSString *)property;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation NSRRemoteObject
@synthesize remoteDestroyOnNesting, remoteAttributes, remoteID;

- (NSNumber *) primitiveRemoteID
{
	return remoteID;
}

#pragma mark - Overrides

#pragma mark Encouraged

+ (NSRConfig *) config
{
    return [NSRConfig relevantConfigForClass:self];
}

- (NSRConfig *) config
{
    return [self.class config];
}

+ (NSString *) remoteModelName
{
	if (self == [NSRRemoteObject class])
		return nil;
	
	//Default behavior is to return name of this class
	
	NSString *class = NSStringFromClass(self);
	
	if ([self config].autoinflectsClassNames)
	{
		return [class nsr_stringByUnderscoringIgnoringPrefix:[self config].ignoresClassPrefixes];
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

- (BOOL) propertyIsTimestamp:(NSString *)property
{
	return ([property isEqualToString:@"createdAt"] || [property isEqualToString:@"updatedAt"] ||
			[property isEqualToString:@"created_at"] || [property isEqualToString:@"updated_at"]);
}

- (BOOL) valueIsArray:(id)value
{
    return ([value isKindOfClass:[NSArray class]] || 
            [value isKindOfClass:[NSSet class]] || 
            [value isKindOfClass:[NSOrderedSet class]]);
}

- (BOOL) propertyIsDate:(NSString *)property
{
	//give rubymotion the _at dates for frees
	return ([self propertyIsTimestamp:property] ||
			[[self.class typeForProperty:property] isEqualToString:@"@\"NSDate\""]);
}

+ (NSString *) typeForProperty:(NSString *)prop
{
	objc_property_t property = class_getProperty(self, [prop UTF8String]);
	if (!property)
		return nil;
	
	// This will return some garbage like "Ti,GgetFoo,SsetFoo:,Vproperty"
	// See https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
	
	NSString *atts = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
	
	for (NSString *att in [atts componentsSeparatedByString:@","])
		if ([att hasPrefix:@"T"])
			return [att substringFromIndex:1];
	
	return nil;
}

+ (Class) typeClassForProperty:(NSString *)property
{
    NSString *propType = [[[self.class typeForProperty:property] stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByReplacingOccurrencesOfString:@"@" withString:@""];
    
    return NSClassFromString(propType);
}

+ (NSMutableArray *) remotePropertiesForClass:(Class)c
{
	unsigned int propertyCount;
	
	objc_property_t *properties = class_copyPropertyList(c, &propertyCount);
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:propertyCount];
	
	if (properties)
	{
		while (propertyCount--)
		{
			NSString *name = [NSString stringWithCString:property_getName(properties[propertyCount]) encoding:NSASCIIStringEncoding];
			
			// makes sure it's not primitive
			if ([[self typeForProperty:name] rangeOfString:@"@"].location != NSNotFound)
 			{
				[results addObject:name];
			}
		}
		
		free(properties);
	}
	
	if (c == [NSRRemoteObject class])
	{
		return results;
	}
	else
	{
		NSMutableArray *superProps = [self remotePropertiesForClass:c.superclass];
		[superProps addObjectsFromArray:results];
		return superProps;
	}
}

- (NSMutableArray *) remoteProperties
{
	NSMutableArray *master = [self.class remotePropertiesForClass:self.class];
	[master removeObject:@"remoteAttributes"];
	return master;
}

- (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)verb
{
	return nil;
}

- (BOOL) shouldOnlySendIDKeyForNestedObjectProperty:(NSString *)property
{
    return NO;
}

- (Class) nestedClassForProperty:(NSString *)property
{ 
	Class class = [self.class typeClassForProperty:property];
    
    return [class isSubclassOfClass:[NSRRemoteObject class]] ? class : nil;
}

- (id) encodeValueForProperty:(NSString *)property remoteKey:(NSString **)remoteKey
{	
	if ([property isEqualToString:@"remoteID"])
		*remoteKey = @"id";
	
    Class nestedClass = [self nestedClassForProperty:property];
    id val = [self valueForKey:property];
    
    if (nestedClass)
    {
		if ([self shouldOnlySendIDKeyForNestedObjectProperty:property])
		{			
			*remoteKey = [*remoteKey stringByAppendingString:@"_id"];
			return [val remoteID];
		}
		
		*remoteKey = [*remoteKey stringByAppendingString:@"_attributes"];
		
		if ([self valueIsArray:val])
		{
			NSMutableArray *new = [NSMutableArray arrayWithCapacity:[val count]];
			
			for (id element in val)
			{
				id encodedObj = [element remoteDictionaryRepresentationWrapped:NO fromNesting:YES];
				[new addObject:encodedObj];
			}
			
			return new;
		}
		
		return [val remoteDictionaryRepresentationWrapped:NO fromNesting:YES];
	}

	if ([val isKindOfClass:[NSDate class]])
	{
		return [[self config] stringFromDate:val];
	}

	return val;
}

- (NSString *) propertyForRemoteKey:(NSString *)remoteKey
{
	NSString *property = remoteKey;
	
	if ([self config].autoinflectsPropertyNames)
		property = [property nsr_stringByCamelizing];
	
	if ([remoteKey isEqualToString:@"id"])
		property = @"remoteID";
	
	if (![self.remoteProperties containsObject:property])
		return nil;
	
	return property;
}

- (Class) containerClassForRelationProperty:(NSString *)property
{
	return [NSMutableArray class];
}

- (void) decodeRemoteValue:(id)railsObject forRemoteKey:(NSString *)remoteKey change:(BOOL *)change
{
	NSString *property = [self propertyForRemoteKey:remoteKey];
	
	if (!property)
		return;

	Class nestedClass = [self nestedClassForProperty:property];
	
	id previousVal = [self valueForKey:property];
    
	//TODO
	//RUBYMOTION BUG...... returns NSNull instead of nil in a really specific case
	if (previousVal == [NSNull null])
		previousVal = nil;
    
	id decodedObj = nil;
	
	BOOL changes = -1;
	
	if (railsObject)
	{
        if (nestedClass)
        {
            if ([self valueIsArray:railsObject])
            {
                changes = NO;
                
                BOOL checkForChange = ([railsObject count] == [previousVal count]);
                if (!checkForChange)
                    changes = YES;
                
                decodedObj = [[[self containerClassForRelationProperty:property] alloc] init];
                
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
                        decodedElement = [nestedClass objectWithRemoteDictionary:railsElement];
                        
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
                    
                    [decodedObj addObject:decodedElement];
                }
            }
            else
            {
                //if the nested object didn't exist before, make it & set it
                if (!previousVal)
                {
                    decodedObj = [nestedClass objectWithRemoteDictionary:railsObject];
                }
                //otherwise, keep the old object & only mark as change if its properties changed (recursive)
                else
                {
                    decodedObj = previousVal;
                    
                    changes = [decodedObj setPropertiesUsingRemoteDictionary:railsObject];
                }
            }
        }
        else if ([self propertyIsDate:property])
		{
			decodedObj = [[self config] dateFromString:railsObject];
			
			//account for any discrepancies between NSDate object and a string (which doesn't include milliseconds) 
			CGFloat diff = fabs([decodedObj timeIntervalSinceDate:previousVal]);
			changes = (!previousVal || (diff > 1.25));
		}
		//otherwise, if not nested or anything, just use what we got (number, string, dictionary, array)
		else
		{
			decodedObj = railsObject;
		}
	}
	
	//means we should check for straight equality (no *change was set)
	if (changes == -1)
	{
		changes = NO;

		//if it existed before but now nil, mark change
		if (!decodedObj && previousVal)
		{
			changes = YES;
		}
		else if (decodedObj)
		{
			changes = ![decodedObj isEqual:previousVal];
		}
	}
	
	*change = changes;
	
	[self setValue:decodedObj forKey:property];
}

- (BOOL) shouldSendProperty:(NSString *)property whenNested:(BOOL)nested
{
	//don't include id if it's nil or on the main object (nested guys need their IDs)
	if ([property isEqualToString:@"remoteID"] && (!self.remoteID || !nested))
		return NO;
	
	//don't include updated_at or created_at
	if ([self propertyIsTimestamp:property])
		return NO;
    
    Class nestedClass = [self nestedClassForProperty:property];
	
	if (nestedClass && ![self shouldOnlySendIDKeyForNestedObjectProperty:property])
	{
		//this is recursion-protection. we don't want to include every nested class in this class because one of those nested class could nest us, causing infinite loop. of course, overridable
		if (nested)
		{
			return NO;
		}
		
		id val = [self valueForKey:property];

		//it's an _attributes. don't send if there's no val or empty (is okay on belongs_to bc we send a null id)
        
		//TODO
		//the NSNull check is part of an RM bug
		if (val == [NSNull null] || !val || ([self valueIsArray:val] && [val count] == 0))
		{
			return NO;
		}
	}
	
	return YES;
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
	
	for (NSString *remoteKey in dict)
	{
		id remoteObject = [dict objectForKey:remoteKey];
		if (remoteObject == [NSNull null])
			remoteObject = nil;

		BOOL change = NO;
		[self decodeRemoteValue:remoteObject forRemoteKey:remoteKey change:&change];

		if (change)
			changes = YES;
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
	
	for (NSString *objcProperty in [self remoteProperties])
	{
		if (![self shouldSendProperty:objcProperty whenNested:nesting])
			continue;
		
		NSString *remoteKey = objcProperty;
		if ([self config].autoinflectsPropertyNames)
			remoteKey = [remoteKey nsr_stringByUnderscoring];
		
		id remoteRep = [self encodeValueForProperty:objcProperty remoteKey:&remoteKey];
		if (!remoteRep)
			remoteRep = [NSNull null];
		
		BOOL JSONParsable = ([remoteRep isKindOfClass:[NSArray class]] ||
							 [remoteRep isKindOfClass:[NSDictionary class]] ||
							 [remoteRep isKindOfClass:[NSString class]] ||
							 [remoteRep isKindOfClass:[NSNumber class]] ||
							 [remoteRep isKindOfClass:[NSNull class]]);
		
		if (!JSONParsable)
		{
			[NSException raise:NSRJSONParsingException format:@"Trying to encode property '%@' in class '%@', but the result (%@) was not JSON-parsable. Override -[NSRRemoteObject encodeValueForProperty:remoteKey:] if you want to encode a property that's not NSDictionary, NSArray, NSString, NSNumber, or NSNull. Remember to call super if it doesn't need custom encoding.",objcProperty, self.class, remoteRep];
		}
		
		
		[dict setObject:remoteRep forKey:remoteKey];
	}
	
	if (remoteDestroyOnNesting)
	{
		[dict setObject:[NSNumber numberWithBool:YES] forKey:@"_destroy"];
	}
	
	if (wrapped)
		return [NSDictionary dictionaryWithObject:dict forKey:[self.class remoteModelName]];
	
	return dict;
}


+ (id) objectWithRemoteDictionary:(NSDictionary *)dict
{
	NSRRemoteObject *obj = [[self alloc] init];
	[obj setPropertiesUsingRemoteDictionary:dict];

	return obj;
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
	return !![[NSRRequest requestToUpdateObject:self] sendSynchronous:error];
}

- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToUpdateObject:self] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
		 completionBlock(error);
	 }];
}

#pragma mark Replace

- (BOOL) remoteReplace:(NSError **)error
{
	return !![[NSRRequest requestToReplaceObject:self] sendSynchronous:error];
}

- (void) remoteReplaceAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToReplaceObject:self] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
		 completionBlock(error);
	 }];
}

#pragma mark Destroy

- (BOOL) remoteDestroy:(NSError **)error
{
	return !![[NSRRequest requestToDestroyObject:self] sendSynchronous:error];
}

- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToDestroyObject:self] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
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
		return [[self class] objectWithRemoteDictionary:objData];
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
			 id obj = [[self class] objectWithRemoteDictionary:jsonRep];
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

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		self.remoteID = [aDecoder decodeObjectForKey:@"remoteID"];
		remoteAttributes = [aDecoder decodeObjectForKey:@"remoteAttributes"];
		self.remoteDestroyOnNesting = [aDecoder decodeBoolForKey:@"remoteDestroyOnNesting"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.remoteID forKey:@"remoteID"];
	[aCoder encodeObject:remoteAttributes forKey:@"remoteAttributes"];
	[aCoder encodeBool:remoteDestroyOnNesting forKey:@"remoteDestroyOnNesting"];
}

@end

