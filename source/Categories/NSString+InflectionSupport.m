//
//  NSString+InflectionSupport.m
//  
//
//  Created by Ryan Daigle on 7/31/08.
//  Copyright 2008 yFactorial, LLC. All rights reserved.
//
// This category borrowed from ObjectiveResource

#import "NSString+InflectionSupport.h"

@implementation NSString (InflectionSupport)

- (NSCharacterSet *)capitals {
	return [NSCharacterSet uppercaseLetterCharacterSet];
}

- (NSCharacterSet *)camelcaseDelimiters {
	return [NSCharacterSet characterSetWithCharactersInString:@"-_"];
}

//improved by NSRails to support more circumstances (see test_inflection in /test)
- (NSString *)deCamelizeWith:(NSString *)delimiter 
{	
	unichar *buffer = calloc([self length], sizeof(unichar));
	[self getCharacters:buffer];
	NSMutableString *underscored = [NSMutableString string];
	
	NSString *currChar;
	BOOL previousLetterWasCaps = NO;
	for (int i = 0; i < [self length]; i++) 
	{
		currChar = [NSString stringWithCharacters:buffer+i length:1];
		if ([[self capitals] characterIsMember:buffer[i]]) 
		{
			BOOL nextLetterIsCaps = (i+1 == self.length || [[self capitals] characterIsMember:buffer[i+1]]);
			//only add the delimiter if, it's not the first letter, it's not in the middle of a bunch of caps, and it's not a repeat
			if (i != 0 && !(previousLetterWasCaps && nextLetterIsCaps) && ![[self camelcaseDelimiters] characterIsMember:buffer[i-1]])
			{
				[underscored appendString:delimiter];
			}
			[underscored appendString:[currChar lowercaseString]];
			previousLetterWasCaps = YES;
		}
		else 
		{
			[underscored appendString:currChar];
			previousLetterWasCaps = NO;
		}
	}
	
	free(buffer);
	return underscored;
}
	

- (NSString *)dasherize {
	return [self deCamelizeWith:@"-"];
}

- (NSString *)underscore
{
	return [self deCamelizeWith:@"_"];
}

- (NSString *)camelize
{
	unichar *buffer = calloc([self length], sizeof(unichar));
	[self getCharacters:buffer ];
	NSMutableString *underscored = [NSMutableString string];
	
	BOOL capitalizeNext = NO;
	NSCharacterSet *delimiters = [self camelcaseDelimiters];
	for (int i = 0; i < [self length]; i++) {
		NSString *currChar = [NSString stringWithCharacters:buffer+i length:1];
		if([delimiters characterIsMember:buffer[i]]) {
			capitalizeNext = YES;
		} else {
			if(capitalizeNext) {
				[underscored appendString:[currChar uppercaseString]];
				capitalizeNext = NO;
			} else {
				[underscored appendString:currChar];
			}
		}
	}
	
	free(buffer);
	return underscored;
}

- (NSString *)titleize {
	NSArray *words = [self componentsSeparatedByString:@" "];
	NSMutableString *output = [NSMutableString string];
	for (NSString *word in words) {
		[output appendString:[[word substringToIndex:1] uppercaseString]];
		[output appendString:[[word substringFromIndex:1] lowercaseString]];
		[output appendString:@" "];
	}
	return [output substringToIndex:[self length]];
}

- (NSString *)toClassName {
	NSString *result = [self camelize];
	return [result stringByReplacingCharactersInRange:NSMakeRange(0,1) 
										 withString:[[result substringWithRange:NSMakeRange(0,1)] uppercaseString]];
}

//NSRails addition
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
