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

#import "NSString+NSRInflection.h"
#import <objc/runtime.h>


////////////////////////////////////////////////////////////////////////////////////////////////////

@interface NSRRemoteObject (private)

- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped fromNesting:(BOOL)nesting;
+ (NSArray *) arrayOfInstancesFromRemoteJSON:(id)json;

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
    return [NSRConfig contextuallyRelevantConfig];
}

+ (NSString *) remoteModelName
{
	if (self == [NSRRemoteObject class])
		return nil;
		
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

- (NSMutableArray *) remoteProperties
{
    NSMutableArray *results = [NSMutableArray array];
    
    for (Class c = self.class; c != [NSRRemoteObject class]; c = c.superclass)
    {
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(c, &propertyCount);
        
        if (properties)
        {
            while (propertyCount--)
            {
                NSString *name = [NSString stringWithCString:property_getName(properties[propertyCount]) encoding:NSASCIIStringEncoding];
                // makes sure it's not primitive
                if ([[self.class typeForProperty:name] rangeOfString:@"@"].location != NSNotFound)
                    [results addObject:name];
            }
            
            free(properties);
        }
    }
    
    [results addObject:@"remoteID"];
    return results;
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
    return ([class isSubclassOfClass:[NSRRemoteObject class]] ? class : nil);
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
		return [[self.class config] stringFromDate:val];
	}

	return val;
}

- (NSString *) propertyForRemoteKey:(NSString *)remoteKey
{
	if ([remoteKey isEqualToString:@"id"])
		return @"remoteID";

	NSString *property = remoteKey;
	if ([self.class config].autoinflectsPropertyNames)
		property = [property nsr_stringByCamelizing];
	
	return ([self.remoteProperties containsObject:property] ? property : nil);
}

- (Class) containerClassForRelationProperty:(NSString *)property
{
	return [NSMutableArray class];
}

- (void) decodeRemoteValue:(id)railsObject forRemoteKey:(NSString *)remoteKey
{
	NSString *property = [self propertyForRemoteKey:remoteKey];
	
	if (!property)
		return;

	Class nestedClass = [self nestedClassForProperty:property];
	
	id previousVal = [self valueForKey:property];
	id decodedObj = nil;
	
	if (railsObject)
	{
        if (nestedClass)
        {
            if ([self valueIsArray:railsObject])
            {
                decodedObj = [[[self containerClassForRelationProperty:property] alloc] init];
                                
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
                    }
                    else
                    {
                        //existed - simply update that one (recursively)
                        decodedElement = existing;
                        [decodedElement setPropertiesUsingRemoteDictionary:railsElement];
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
                //otherwise, keep the old object & update to whatever was given
                else
                {
                    decodedObj = previousVal;
					[decodedObj setPropertiesUsingRemoteDictionary:railsObject];
                }
            }
        }
        else if ([self propertyIsDate:property])
		{
			decodedObj = [[self.class config] dateFromString:railsObject];
		}
		//otherwise, if not nested or anything, just use what we got (number, string, dictionary, array)
		else
		{
			decodedObj = railsObject;
		}
	}
	
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

		//don't send if there's no val or empty (is okay on belongs_to bc we send a null id)
		if (!val || ([self valueIsArray:val] && [val count] == 0))
		{
			return NO;
		}
	}
	
	return YES;
}

#pragma mark - Internal NSR stuff

- (void) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict
{
    if (dict)
        remoteAttributes = dict;
	
	//support JSON that comes in like {"post"=>{"something":"something"}}
	NSDictionary *innerDict = [dict objectForKey:[self.class remoteModelName]];
	if (dict.count == 1 && [innerDict isKindOfClass:[NSDictionary class]])
	{
		dict = innerDict;
	}
		
	for (NSString *remoteKey in dict)
	{
		id remoteObject = [dict objectForKey:remoteKey];
		if (remoteObject == [NSNull null])
			remoteObject = nil;

		[self decodeRemoteValue:remoteObject forRemoteKey:remoteKey];
	}
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
		if ([self.class config].autoinflectsPropertyNames)
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
	
	[self setPropertiesUsingRemoteDictionary:jsonResponse];
	return !!jsonResponse;
}

- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToCreateObject:self] sendAsynchronous:
	 ^(id result, NSError *error) 
	 {
		 [self setPropertiesUsingRemoteDictionary:result];
		 if (completionBlock)
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
		 if (completionBlock)
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
		 if (completionBlock)
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
		 if (completionBlock)
			 completionBlock(error);
	 }];
}

#pragma mark Get latest

- (BOOL) remoteFetch:(NSError **)error
{
	NSDictionary *jsonResponse = [[NSRRequest requestToFetchObject:self] sendSynchronous:error];
	
	if (jsonResponse)
		[self setPropertiesUsingRemoteDictionary:jsonResponse];
	
	return !!jsonResponse;
}

- (void) remoteFetchAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[NSRRequest requestToFetchObject:self] sendAsynchronous:
	 ^(id jsonRep, NSError *error) 
	 {
		 if (jsonRep)
			 [self setPropertiesUsingRemoteDictionary:jsonRep];
		 if (completionBlock)
			 completionBlock(error);
	 }];
}

#pragma mark Get specific object (class-level)

+ (id) remoteObjectWithID:(NSNumber *)mID error:(NSError **)error
{
	NSDictionary *objData = [[NSRRequest requestToFetchObjectWithID:mID ofClass:self] sendSynchronous:error];
	
    return (objData ? [self objectWithRemoteDictionary:objData] : nil);
}

+ (void) remoteObjectWithID:(NSNumber *)mID async:(NSRFetchObjectCompletionBlock)completionBlock
{
	[[NSRRequest requestToFetchObjectWithID:mID ofClass:self] sendAsynchronous:
	 ^(id jsonRep, NSError *error) 
	 {
         id obj = (jsonRep ? [self objectWithRemoteDictionary:jsonRep] : nil);
		 if (completionBlock)
			 completionBlock(obj, error);
	 }];
}

#pragma mark Get all objects (class-level)

+ (NSArray *) arrayOfInstancesFromRemoteJSON:(id)json
{
	if (!json)
		return nil;
	
	if ([json isKindOfClass:[NSDictionary class]])
	{
		//probably has root in front of it - "posts":[{},{}]
		if ([json count] == 1)
		{
			json = [[json allValues] objectAtIndex:0];
		}
	}
	
	[json translateRemoteDictionariesIntoInstancesOfClass:self];
	return json;
}

+ (NSArray *) remoteAll:(NSError **)error
{
	return [self remoteAllViaObject:nil error:error];
}

+ (NSArray *) remoteAllViaObject:(NSRRemoteObject *)obj error:(NSError **)error
{
    id json = [[NSRRequest requestToFetchAllObjectsOfClass:self viaObject:obj] sendSynchronous:error];
	return [self arrayOfInstancesFromRemoteJSON:json];
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
		 if (completionBlock)
			 completionBlock([self arrayOfInstancesFromRemoteJSON:result],error);
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

