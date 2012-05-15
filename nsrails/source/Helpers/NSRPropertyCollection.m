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

#import "NSRProperty.h"


#define NSRRaiseSyncError(x, ...) [NSException raise:NSRailsSyncException format:x,__VA_ARGS__,nil]

@implementation NSRPropertyCollection
@synthesize properties;
@synthesize customConfig;

#pragma mark -
#pragma mark Parser

- (void) addPropertyAsSendable:(NSRProperty *)prop
{
	//for sendable, we can only have ONE property which per Rails attribute which is marked as sendable
	//  (otherwise, which property's value should we stick in the json?)
	
	//so, see if there are any other properties defined so far with the same Rails equivalent that are marked as sendable
	for (NSString *otherPropName in properties)
	{
		NSRProperty *otherProp = [properties objectForKey:otherPropName];
		if (otherProp.sendable && [otherProp.remoteEquivalent isEqualToString:prop.remoteEquivalent])
		{
			NSRRaiseSyncError(@"Multiple Obj-C properties marked as sendable found pointing to the same Rails attribute ('%@'). It's okay to have >1 retrievable property, but only one sendable property per Rails attribute is allowed (you can make the others retrieve-only with the -r flag).", prop.remoteEquivalent);
		}
	}
	
	prop.sendable = YES;
}

- (id) initWithClass:(Class)class syncString:(NSString *)syncString customConfig:(NSRConfig *)config
{
	if ((self = [super init]))
	{
		customConfig = config;
				
		//initialize property categories
		properties = [[NSMutableDictionary alloc] init];
		
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
			if (nestedModel.length == 0)
				nestedModel = nil;
			
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
			NSRProperty *property = [[NSRProperty alloc] init];
			property.propertyName = objcProp;
			
			//Check for =
			if (equivalent)
			{
				//just "property_name=" is indicator for exact match
				if (equivalent.length == 0)
					property.remoteEquivalent = objcProp;
				else
					property.remoteEquivalent = equivalent;
			}
			
			if ([options rangeOfString:@"r"].location != NSNotFound || missingBothRS)
			{
				property.retrievable = YES;
			}
			
			if ([options rangeOfString:@"s"].location != NSNotFound || missingBothRS)
			{
				[self addPropertyAsSendable:property];
			}
			
			//mark as h_m if -m is declared (or if property is found to be array)
			if ((options && [options rangeOfString:@"m"].location != NSNotFound) || typeIsArray)
			{
				property.hasMany = YES;
			}
			
			//Check for all other flags (-)
			if (options)
			{
				if ([options rangeOfString:@"e"].location != NSNotFound)
				{
					property.encodable = YES;
				}
				
				if ([options rangeOfString:@"d"].location != NSNotFound)
				{
					property.decodable = YES;
				}
				
				//add a special marker for b_t in nestedModelProperties dict
				if ([options rangeOfString:@"b"].location != NSNotFound)
				{
					property.belongsTo = YES;
				}
			}
			
			if (typeIsArray)
			{
				property.hasMany = YES;
			}
			
			if (([nestedModel isEqualToString:@"NSDate"] || [type isEqualToString:@"NSDate"]) && !property.hasMany)
			{
				property.date = YES;
			}
			else if (property.hasMany || nestedModel)
			{
				Class class = NSClassFromString(nestedModel);
				
				if (!nestedModel && typeIsArray)
				{
					NSRRaiseSyncError(@"Property '%@' in class %@ was found to be an array, but no nesting model was set. If you don't want to nest instances of other objects, you can have it populate with NSDictionaries with the retrieved remote attributes by adding a colon to the end of this property in NSRailsSync: `%@:`",objcProp,NSStringFromClass(class),objcProp);

				}
				else if (!class)
				{
					NSRRaiseSyncError(@"Failed to find class '%@', declared as class for nested property '%@' of class '%@'. Nesting relation not set.",nestedModel,objcProp,NSStringFromClass(class));
				}
				else if (![class isSubclassOfClass:[NSRailsModel class]])
				{
					NSRRaiseSyncError(@"'%@' was declared as the class for the nested property '%@' of class '%@', but '%@' is not a subclass of NSRailsModel.",nestedModel,objcProp, NSStringFromClass(class),nestedModel);
				}
				else
				{
					property.nestedClass = nestedModel;
				}
			}
			
			[properties setObject:property forKey:objcProp];
		}
	}
	
	return self;
}

#pragma mark -
#pragma mark Special definitions

- (BOOL) propertyIsMarkedBelongsTo:(NSString *)prop
{
	return [[properties objectForKey:prop] isBelongsTo];
}

- (BOOL) propertyIsMarkedHasMany:(NSString *)prop
{
	return [[properties objectForKey:prop] isHasMany];
}

- (NSString *) nestedClassNameForProperty:(NSString *)prop
{
	return [[properties objectForKey:prop] nestedClass];
}

- (BOOL) propertyIsArray:(NSString *)prop
{
	return [[properties objectForKey:prop] isHasMany];
}

- (BOOL) propertyIsDate:(NSString *)prop
{
	return [[properties objectForKey:prop] isDate];
}


- (SEL) encodeSelectorForProperty:(NSString *)prop
{
	if (![[properties objectForKey:prop] isEncodable])
	{
		if ([self propertyIsDate:prop])
			return @selector(nsrails_encodeDate:);

		return NULL;
	}
	
	NSString *sel = [NSString stringWithFormat:@"encode%@", [prop firstLetterCapital]];
	return NSSelectorFromString(sel);	
}

- (SEL) decodeSelectorForProperty:(NSString *)prop
{
	if (![[properties objectForKey:prop] isDecodable])
	{
		if ([self propertyIsDate:prop])
			return @selector(nsrails_decodeDate:);
		
		return NULL;
	}
	
	NSString *sel = [NSString stringWithFormat:@"decode%@:",[prop firstLetterCapital]];
	return NSSelectorFromString(sel);
}


- (NSString *) remoteEquivalentForObjcProperty:(NSString *)objcProperty autoinflect:(BOOL)autoinflect
{
	NSString *railsEquivalent = [[properties objectForKey:objcProperty] remoteEquivalent];
	if (!railsEquivalent)
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
	NSMutableArray *props = [NSMutableArray array];
	for (NSString *property in properties)
	{
		NSString *definedRemote = [[properties objectForKey:property] remoteEquivalent];
		NSString *remote = definedRemote ? definedRemote : [property camelize];
		if ([remote isEqualToString:railsProperty])
		{
			[props addObject:property];
		}
	}
	return props;
}

#pragma mark -
#pragma mark NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		properties = [aDecoder decodeObjectForKey:@"properties"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:properties forKey:@"properties"];
}

@end
