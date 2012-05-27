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
#import "NSObject+Properties.h"
#import "NSString+Inflection.h"

@implementation NSRProperty
@synthesize sendable, retrievable, encodable, decodable, remoteEquivalent, nestedClass, date, name, includedOnNesting;
@synthesize belongsTo, array;

- (BOOL) isHasMany
{
	return array && nestedClass;
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		self.sendable = [aDecoder decodeBoolForKey:@"sendable"];
		self.retrievable = [aDecoder decodeBoolForKey:@"retrievable"];
		self.decodable = [aDecoder decodeBoolForKey:@"decodable"];
		self.encodable = [aDecoder decodeBoolForKey:@"encodable"];
		self.array = [aDecoder decodeBoolForKey:@"array"];
		self.belongsTo = [aDecoder decodeBoolForKey:@"belongsTo"];
		self.date = [aDecoder decodeBoolForKey:@"date"];
		self.includedOnNesting = [aDecoder decodeBoolForKey:@"includedOnNesting"];
		
		self.remoteEquivalent = [aDecoder decodeObjectForKey:@"remoteEquivalent"];
		self.name = [aDecoder decodeObjectForKey:@"name"];
		self.nestedClass = [aDecoder decodeObjectForKey:@"nestedClass"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:remoteEquivalent forKey:@"remoteEquivalent"];
	[aCoder encodeObject:name forKey:@"name"];
	[aCoder encodeObject:nestedClass forKey:@"nestedClass"];

	[aCoder encodeBool:includedOnNesting forKey:@"includedOnNesting"];
	[aCoder encodeBool:sendable forKey:@"sendable"];
	[aCoder encodeBool:retrievable forKey:@"retrievable"];
	[aCoder encodeBool:decodable forKey:@"decodable"];
	[aCoder encodeBool:encodable forKey:@"encodable"];
	[aCoder encodeBool:array forKey:@"array"];
	[aCoder encodeBool:belongsTo forKey:@"belongsTo"];
	[aCoder encodeBool:date forKey:@"date"];
}


@end


#define NSRRaiseSyncError(x, ...) [NSException raise:NSRMapException format:x,__VA_ARGS__,nil]

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
			
			NSArray *eqSplit = [[modSplit objectAtIndex:0] componentsSeparatedByString:@"="];
			NSString *equivalent = (eqSplit.count == 1 ? nil : [[eqSplit lastObject] stringByTrimmingCharactersInSet:wn]);

			NSString *objcProp = [[eqSplit objectAtIndex:0] stringByTrimmingCharactersInSet:wn];
						
			//if it's previously been marked with the '-x' flag OR was already added, ignore it
			if ([alreadyAdded containsObject:objcProp])
				continue;

			//now ignore it (done so that explicit flags can override the * (which comes after), and so subclasses can  override their parents' NSRMap - properties furthest up the list will have greatest priority)
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
				NSRRaiseSyncError(@"Property '%@' declared in NSRMap for class %@ was found to be of primitive type '%@' - please use NSNumber*.", objcProp, NSStringFromClass(class), type);
				continue;
			}
			
			BOOL typeIsArray = [type isEqualToString:@"NSArray"] || [type isEqualToString:@"NSMutableArray"];
			
			// Looks like we're ready to officially add this property
			NSRProperty *property = [[NSRProperty alloc] init];
			property.name = objcProp;
			
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
			
			//Check for all other flags (-)
			if (options)
			{
				if ([options rangeOfString:@"e"].location != NSNotFound)
					property.encodable = YES;

				if ([options rangeOfString:@"d"].location != NSNotFound)
					property.decodable = YES;
				
				if ([options rangeOfString:@"b"].location != NSNotFound)
					property.belongsTo = YES;
				
				if ([options rangeOfString:@"n"].location != NSNotFound)
					property.includedOnNesting = YES;
				
				if ([options rangeOfString:@"m"].location != NSNotFound) 
					property.array = YES;
			}
			
			BOOL explicitDate = [nestedModel isEqualToString:@"NSDate"];
			if (explicitDate || [type isEqualToString:@"NSDate"])
			{
				nestedModel = nil;
				property.date = YES;
			}
			
			if (typeIsArray)
			{
				property.array = YES;
			}
			
			if (nestedModel)
			{
				Class nestedClass = NSClassFromString(nestedModel);
				
				if (!nestedClass)
				{
					NSRRaiseSyncError(@"Failed to find class '%@', declared as class for nested property '%@' of class '%@'.",nestedModel,objcProp,class);
				}
				else if (![nestedClass isSubclassOfClass:[NSRRemoteObject class]] && !explicitDate)
				{
					NSRRaiseSyncError(@"'%@' was declared as the class for the nested property '%@' of class '%@', but '%@' is not a subclass of NSRRemoteObject.",nestedModel,objcProp, NSStringFromClass(class),nestedModel);
				}
				else
				{
					property.nestedClass = nestedModel;
				}
			}
			//if not array or has an explicit nested model set, see if we should automatically nest it (if it's an NSRRemoteObject)
			else if ([NSClassFromString(type) isSubclassOfClass:[NSRRemoteObject class]])
			{
				property.nestedClass = type;
			}
			
			[properties setObject:property forKey:objcProp];
		}
	}
	
	return self;
}

- (NSArray *) objcPropertiesForRemoteEquivalent:(NSString *)remoteProp autoinflect:(BOOL)autoinflect
{
	NSString *inflectedRemoteProp = (autoinflect ? [remoteProp camelize] : remoteProp);
	
	NSMutableArray *props = [NSMutableArray array];
	for (NSString *property in properties)
	{
		NSRProperty *propObject = [properties objectForKey:property];
		NSString *remote = propObject.remoteEquivalent ? propObject.remoteEquivalent : propObject.name;
		
		//if explicit equiv found, compare it to the non-inflected version
		if ([remote isEqualToString:(propObject.remoteEquivalent ? remoteProp : inflectedRemoteProp)])
			[props addObject:propObject];
	}
	return props;
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		self.properties = [aDecoder decodeObjectForKey:@"properties"];
		self.customConfig = [aDecoder decodeObjectForKey:@"customConfig"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:properties forKey:@"properties"];
	[aCoder encodeObject:customConfig forKey:@"customConfig"];
}

@end
