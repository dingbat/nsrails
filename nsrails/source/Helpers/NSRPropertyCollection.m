/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRPropertyCollection.m
 
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

#import "NSRPropertyCollection.h"
#import "NSRails.h"
#import "NSObject+Properties.h"
#import "NSString+Inflection.h"

//this is the marker (blank string) for the propertyEquivalents dictionary if there's no explicit equivalence set
static NSString const * NSRNoEquivalentMarker = @"";

//this will be the marker for any property that has the "-b flag"
//this gonna go in the nestedModelProperties (properties can never have a comma/space in them so we're safe from any conflicts)
#define NSRBelongsToKeyForProperty(prop)	[prop stringByAppendingString:@", belongs_to"]
#define NSRHasManyKeyForProperty(prop)		[prop stringByAppendingString:@", has_many"]

#define NSRRaiseSyncError(x, ...) [NSException raise:NSRailsSyncException format:x,__VA_ARGS__,nil]

@interface NSRailsModel (internal)

+ (NSString *) railsProperties;
+ (NSString *) NSRailsSync;

@end


@implementation NSRPropertyCollection
@synthesize sendableProperties, retrievableProperties, encodeProperties, decodeProperties;
@synthesize nestedModelProperties, propertyEquivalents, customConfig;

#pragma mark -
#pragma mark Parser

- (void) addPropertyAsSendable:(NSString *)prop equivalent:(NSString *)equivalent class:(Class)_class
{
	//for sendable, we can only have ONE property which per Rails attribute which is marked as sendable
	//  (otherwise, which property's value should we stick in the json?)
	
	//so, see if there are any other properties defined so far with the same Rails equivalent that are marked as sendable
	NSArray *objs = [propertyEquivalents allKeysForObject:equivalent];
	NSMutableArray *sendables = [NSMutableArray arrayWithObject:prop];
	for (NSString *sendable in objs)
	{
		if ([sendableProperties containsObject:sendable])
			[sendables addObject:sendable];
	}
	//greater than 1 cause we're including this property
	if (equivalent && sendables.count > 1)
	{
		if ([equivalent isEqualToString:@"id"])
		{
			NSRRaiseSyncError(@"Obj-C property %@ (class %@) found to set equivalence with 'id'. This is fine for retrieving but should not be marked as sendable.", prop, NSStringFromClass(_class));
		}
		else
		{
			NSRRaiseSyncError(@"Multiple Obj-C properties marked as sendable (%@) found pointing to the same Rails attribute ('%@'). Only using data from the first Obj-C property listed. Please fix by only having one sendable property per Rails attribute (you can make the others retrieve-only with the -r flag).", sendables, equivalent);
		}
	}
	else
	{
		[sendableProperties addObject:prop];
	}
}

- (id) initWithClass:(Class)class syncString:(NSString *)syncString customConfig:(NSRConfig *)config
{
	if ((self = [super init]))
	{
		customConfig = config;
				
		//initialize property categories
		sendableProperties = [[NSMutableArray alloc] init];
		retrievableProperties = [[NSMutableArray alloc] init];
		nestedModelProperties = [[NSMutableDictionary alloc] init];
		propertyEquivalents = [[NSMutableDictionary alloc] init];
		encodeProperties = [[NSMutableArray alloc] init];
		decodeProperties = [[NSMutableArray alloc] init];

		NSCharacterSet *wn = [NSCharacterSet whitespaceAndNewlineCharacterSet];

		//parse the sync string
		//will be something like "property -abc, property2:etc, property3=p"
		NSMutableArray *propsToProcess = [NSMutableArray arrayWithArray:[syncString componentsSeparatedByString:@","]];
		
		NSMutableArray *alreadyAdded = [NSMutableArray array];
		
		for (NSString *rawPropWithFlags in propsToProcess)
		{
			NSString *propWithFlags = [rawPropWithFlags stringByTrimmingCharactersInSet:wn];
			if (propWithFlags.length == 0)
				continue;
			
			//prop can be something like "username=user_name:Class -etc"
			//find string sets between =, :, and -
			NSArray *opSplit = [propWithFlags componentsSeparatedByString:@"-"];
			NSString *options = (opSplit.count == 1 ? nil : [opSplit lastObject]);
			
			NSArray *modSplit = [[opSplit objectAtIndex:0] componentsSeparatedByString:@":"];
			NSString *nestedModel = (modSplit.count == 1 ? nil : [[modSplit lastObject] stringByTrimmingCharactersInSet:wn]);

			NSArray *eqSplit = [[modSplit objectAtIndex:0] componentsSeparatedByString:@"="];
			NSString *equivalent = (eqSplit.count == 1 ? nil : [[eqSplit lastObject] stringByTrimmingCharactersInSet:wn]);

			NSString *objcProp = [[eqSplit objectAtIndex:0] stringByTrimmingCharactersInSet:wn];
						
			//if it's previously been marked with the '-x' flag OR was already added, ignore it
			if ([alreadyAdded containsObject:objcProp])
				continue;

			//now ignore it (done so that explicit flags can override the * (which comes after), and so subclasses can  override their parents' NSRS - properties furthest up the list will have greatest priority)
			[alreadyAdded addObject:objcProp];

			//if options contain an -x, skip the rest of this
			if (options && [options rangeOfString:@"x"].location != NSNotFound)
			{
				continue;
			}
			
			//if -r or -s aren't declared, use -rs by default
			BOOL missingBothRS = (!options || 
								  ([options rangeOfString:@"r"].location == NSNotFound && 
								   [options rangeOfString:@"s"].location == NSNotFound));

			BOOL primitive = NO;
			
			//make sure that the property type is not a primitive
			NSString *type = [class typeForProperty:objcProp isPrimitive:&primitive];
			if (primitive)
			{
				NSRRaiseSyncError(@"Property '%@' declared in NSRailsSync for class %@ was found to be of primitive type '%@' - please use NSNumber*.", objcProp, NSStringFromClass(class), type);
				continue;
			}
			
			BOOL typeIsArray = [type isEqualToString:@"NSArray"] || [type isEqualToString:@"NSMutableArray"];
			
			// Looks like we're ready to officially add this property
			
			//Check for =
			if (equivalent)
			{
				[propertyEquivalents setObject:equivalent forKey:objcProp];
			}
			else
			{
				//if no property explicitly set, make it NSRNoEquivalentMarker
				//later on we'll see if automaticallyCamelize is on for the config and get the equivalence accordingly
				[propertyEquivalents setObject:NSRNoEquivalentMarker forKey:objcProp];
			}
			
			if ([options rangeOfString:@"r"].location != NSNotFound || missingBothRS)
			{
				[retrievableProperties addObject:objcProp];
			}
			
			if ([options rangeOfString:@"s"].location != NSNotFound || missingBothRS)
			{
				[self addPropertyAsSendable:objcProp equivalent:equivalent class:class];
			}
			
			BOOL has_many = NO;
			
			//mark as h_m if -m is declared (or if property is found to be array)
			if ((options && [options rangeOfString:@"m"].location != NSNotFound) || typeIsArray)
			{
				has_many = YES;
				[nestedModelProperties setObject:[NSNumber numberWithBool:YES] forKey:NSRHasManyKeyForProperty(objcProp)];
			}
			
			//Check for all other flags (-)
			if (options)
			{
				if ([options rangeOfString:@"e"].location != NSNotFound)
				{
					[encodeProperties addObject:objcProp];
				}
				
				if ([options rangeOfString:@"d"].location != NSNotFound)
				{
					[decodeProperties addObject:objcProp];
				}
				
				//add a special marker for b_t in nestedModelProperties dict
				if ([options rangeOfString:@"b"].location != NSNotFound)
				{
					[nestedModelProperties setObject:[NSNumber numberWithBool:YES] forKey:NSRBelongsToKeyForProperty(objcProp)];
				}
			}
			
			//Check for :
			if (nestedModel || has_many)
			{
				BOOL dicts = (nestedModel && nestedModel.length == 0); // dicts if indicated (length=0; `nestedArray:`)
				
				if (!dicts)
				{
					Class class = NSClassFromString(nestedModel);
					
					if (!class)
					{
						NSRRaiseSyncError(@"Failed to find class '%@', declared as class for nested property '%@' of class '%@'. Nesting relation not set.",nestedModel,objcProp,NSStringFromClass(class));
					}
					else if (![class isSubclassOfClass:[NSRailsModel class]])
					{
						NSRRaiseSyncError(@"'%@' was declared as the class for the nested property '%@' of class '%@', but '%@' is not a subclass of NSRailsModel.",nestedModel,objcProp, NSStringFromClass(class),nestedModel);
					}
					else
					{
						[nestedModelProperties setObject:nestedModel forKey:objcProp];
					}
				}
			}
			else if (!nestedModel)
			{
				//even if no : was declared for this property, check to see if we should link it anyway
				
				if (typeIsArray)
				{
					NSRRaiseSyncError(@"Property '%@' in class %@ was found to be an array, but no nesting model was set. If you don't want to nest instances of other objects, you can have it populate with NSDictionaries with the retrieved remote attributes by adding a colon to the end of this property in NSRailsSync: `%@:`",objcProp,NSStringFromClass(class),objcProp);
				}
				else if ([type isEqualToString:@"NSDate"])
				{
					[nestedModelProperties setObject:@"NSDate" forKey:objcProp];
				}
				else if ([NSClassFromString(type) isSubclassOfClass:[NSRailsModel class]])
				{
					//automatically link that ivar type (ie, Pet) for that property (ie, pets)
					[nestedModelProperties setObject:type forKey:objcProp];
				}
			}
		}
	}
	
	return self;
}

#pragma mark -
#pragma mark Special definitions

- (BOOL) propertyIsMarkedBelongsTo:(NSString *)prop
{
	return !![nestedModelProperties objectForKey:NSRBelongsToKeyForProperty(prop)];
}

- (BOOL) propertyIsMarkedHasMany:(NSString *)prop
{
	return !![nestedModelProperties objectForKey:NSRHasManyKeyForProperty(prop)];
}

- (NSString *) nestedClassNameForProperty:(NSString *)prop
{
	return [self propertyIsDate:prop] ? nil : [nestedModelProperties objectForKey:prop];
}

- (BOOL) propertyIsArray:(NSString *)prop
{
	return !![nestedModelProperties objectForKey:NSRHasManyKeyForProperty(prop)];
}

- (BOOL) propertyIsDate:(NSString *)prop
{
	return [[nestedModelProperties objectForKey:prop] isEqualToString:@"NSDate"];
}

- (NSString *) remoteEquivalentForObjcProperty:(NSString *)objcProperty autoinflect:(BOOL)autoinflect
{
	NSString *railsEquivalent = [propertyEquivalents objectForKey:objcProperty];
	if (railsEquivalent == NSRNoEquivalentMarker)
	{
		if (autoinflect)
		{
			return [[objcProperty underscore] lowercaseString];
		}
		else
		{
			return objcProperty;
		}
	}
	return railsEquivalent;
}

- (NSArray *) objcPropertiesForRemoteEquivalent:(NSString *)railsProperty autoinflect:(BOOL)autoinflect
{
	NSArray *properties = [propertyEquivalents allKeysForObject:railsProperty];
		
	if (properties.count == 0)
	{
		//no keys (rails equivs) match the railsProperty
		//could mean that there's no PROPERTY or that there's no EQUIVALENCE
		
		//if the autoequivalence exists, send it back cause it's correct
		NSString *autoObjcEquivalence = autoinflect ? [railsProperty camelize] : railsProperty;
		
		if ([propertyEquivalents objectForKey:autoObjcEquivalence])
			return [NSArray arrayWithObject:autoObjcEquivalence];
		
		//prop does not exist, sorry. we tried.
		return nil;
	}
	
	return properties;
}

#pragma mark -
#pragma mark NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		sendableProperties = [aDecoder decodeObjectForKey:@"sendableProperties"];
		retrievableProperties = [aDecoder decodeObjectForKey:@"retrievableProperties"];
		encodeProperties = [aDecoder decodeObjectForKey:@"encodeProperties"];
		decodeProperties = [aDecoder decodeObjectForKey:@"decodeProperties"];
		nestedModelProperties = [aDecoder decodeObjectForKey:@"nestedModelProperties"];
		propertyEquivalents = [aDecoder decodeObjectForKey:@"propertyEquivalents"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:sendableProperties forKey:@"sendableProperties"];
	[aCoder encodeObject:retrievableProperties forKey:@"retrievableProperties"];
	[aCoder encodeObject:encodeProperties forKey:@"encodeProperties"];
	[aCoder encodeObject:decodeProperties forKey:@"decodeProperties"];
	[aCoder encodeObject:nestedModelProperties forKey:@"nestedModelProperties"];
	[aCoder encodeObject:propertyEquivalents forKey:@"propertyEquivalents"];
}

@end
