/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSObject+Properties.m
 
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

#import "NSObject+Properties.h"
#import <objc/runtime.h>
#import "NSString+Inflection.h"

@implementation NSObject (NSRPropertySupport)


+ (NSMutableArray *) classPropertyNames
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
			[results addObject:[NSString stringWithCString:propName encoding:NSASCIIStringEncoding]];
		}
		
		free(properties);	
		return results;
	}
	return nil;
}

+ (NSString *) getType:(NSString *)prop
{
	//get class's ivar for the property
	Ivar var = class_getInstanceVariable(self, [prop UTF8String]);
	if (!var)
		return nil;
	
	return [NSString stringWithCString:ivar_getTypeEncoding(var) encoding:NSUTF8StringEncoding];
}

+ (NSString *) propertyIsPrimitive:(NSString *)prop
{
	NSDictionary *primitives = [NSDictionary dictionaryWithObjectsAndKeys:
								@"int", @"i",
								@"double", @"d",
								@"float", @"f",
								@"long", @"l",
								@"long long", @"q",
								@"char", @"c",
								@"short", @"s",
								@"bool", @"b", nil];
	
	//get property type
	NSString *propType = [self getType:prop];
	
	//see if any object comes back for that property type (then it would be a primitive)
	NSString *primitiveType = [primitives objectForKey:propType];
	
	//if nothing, check uppercase too
	if (!primitiveType)
		primitiveType = [primitives objectForKey:[propType uppercaseString]];

	return primitiveType;
}

+ (NSString *) getPropertyType:(NSString *)prop
{
	NSString *type = [self getType:prop];	
	
	//type will be like @"NSString", so strip "s and @s
	return [[type stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByReplacingOccurrencesOfString:@"@" withString:@""];
}

+ (SEL) getProperty:(NSString *)prop attributePrefix:(NSString *)str
{
	objc_property_t property = class_getProperty(self, [prop UTF8String]);
	if (!property)
		return nil;
	
	NSString *atts = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
	//this will return some garbage like "Ti,GgetFoo,SsetFoo:,Vproperty"
	//getter is prefixed by a G and setter is prefixed by an S
	//split it by attribute and return anything matching the prefix specified (would be S or G)
	for (NSString *att in [atts componentsSeparatedByString:@","])
	{
		if (att.length > 0 && [[att substringToIndex:1] isEqualToString:str])
		{
			NSString *setter = [att substringFromIndex:1];
			return NSSelectorFromString(setter);
		}
	}
	
	return nil;
}

+ (SEL) getPropertyGetter:(NSString *)prop
{
	SEL s = [self getProperty:prop attributePrefix:@"G"];
	//if no custom getter specified, return the standard "etc"
	if (!s)
	{
		s = NSSelectorFromString(prop);
	}
	return s;
}

+ (SEL) getPropertySetter:(NSString *)prop
{
	SEL s = [self getProperty:prop attributePrefix:@"S"];
	//if no custom setter specified, return the standard "setEtc:"
	if (!s)
	{
		s = NSSelectorFromString([NSString stringWithFormat:@"set%@:",[prop properCase]]);
	}
	return s;
}


@end
