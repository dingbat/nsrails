//
//  NSString+Inflection.m
//  NSRails
//
//  Created by Dan Hassin on 3/20/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//
//  Credit for some code here goes to Ryan Daigle (2008 yFactorial, LLC) - thank you!

#import "NSString+Inflection.h"

@implementation NSString (NSR_Inflection)

- (NSCharacterSet *) capitals 
{
	return [NSCharacterSet uppercaseLetterCharacterSet];
}

- (NSCharacterSet *) camelcaseDelimiters 
{
	return [NSCharacterSet characterSetWithCharactersInString:@"-_"];
}

- (NSString *) underscore
{
	return [self underscoreIgnorePrefix:NO];
}

- (NSString *) underscoreIgnorePrefix:(BOOL)ignorePrefix
{	
	NSString *delimiter = @"_";
	
	NSMutableString *underscored = [NSMutableString string];
	
	BOOL isPrefix = YES;
	
	BOOL previousLetterWasCaps = NO;
	for (int i = 0; i < [self length]; i++) 
	{
		unichar c = [self characterAtIndex:i];
		NSString *currChar = [NSString stringWithFormat:@"%C",c];
		if ([[self capitals] characterIsMember:c]) 
		{
			BOOL nextLetterIsCaps = (i+1 == self.length || [[self capitals] characterIsMember:[self characterAtIndex:i+1]]);
			//only add the delimiter if, it's not the first letter, it's not in the middle of a bunch of caps, and it's not a repeat
			if (i != 0 && !(previousLetterWasCaps && nextLetterIsCaps) && ![[self camelcaseDelimiters] characterIsMember:[self characterAtIndex:i-1]])
			{
				if (isPrefix && ignorePrefix)
				{
					underscored = [NSMutableString string];
				}
				else 
				{
					[underscored appendString:delimiter];
				}
			}
			[underscored appendString:[currChar lowercaseString]];
			previousLetterWasCaps = YES;
		}
		else 
		{
			isPrefix = NO;
			
			[underscored appendString:currChar];
			previousLetterWasCaps = NO;
		}
	}
	
	return underscored;
}

- (NSString *) toClassName
{
	if (self.length == 0)
		return self;
	
	NSString *result = [self camelize];
	return [result stringByReplacingCharactersInRange:NSMakeRange(0,1) 
										   withString:[[result substringWithRange:NSMakeRange(0,1)] uppercaseString]];
}

- (NSString *) camelize
{
	NSMutableString *underscored = [NSMutableString string];
	
	BOOL capitalizeNext = NO;
	NSCharacterSet *delimiters = [self camelcaseDelimiters];
	for (int i = 0; i < [self length]; i++) 
	{
		unichar c = [self characterAtIndex:i];

		if ([delimiters characterIsMember:c])
		{
			capitalizeNext = YES;
		} 
		else 
		{
			NSString *str = [NSString stringWithFormat:@"%C", c];
			if (capitalizeNext) 
			{
				[underscored appendString:[str uppercaseString]];
				capitalizeNext = NO;
			} 
			else 
			{
				[underscored appendString:str];
			}
		}
	}
	
	return underscored;
}

- (NSString *) pluralize
{
	if (self.length == 0)
		return self;
	
	if ([self isEqualToString:@"person"])
		return @"people";
	
	if ([self isEqualToString:@"Person"])
		return @"People";
	
	if ([[self substringFromIndex:self.length-1] isEqualToString:@"y"] &&
		(self.length == 1 || ![[self substringFromIndex:self.length-2] isEqualToString:@"ey"]))
		return [[self substringToIndex:self.length-1] stringByAppendingString:@"ies"];
	
	if ([[self substringFromIndex:self.length-1] isEqualToString:@"s"])
		return [self stringByAppendingString:@"es"];
	
	return [self stringByAppendingString:@"s"];
}

@end
