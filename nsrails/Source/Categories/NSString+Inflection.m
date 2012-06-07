/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSString+Inflection.m
 
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

// Credit for some code here goes to Ryan Daigle (2008 yFactorial, LLC) - thank you!

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

- (NSString *) firstLetterCapital
{
	if (self.length == 0)
		return self;
	
	return [self stringByReplacingCharactersInRange:NSMakeRange(0,1) 
										 withString:[[self substringWithRange:NSMakeRange(0,1)] uppercaseString]];
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

    // replace items that end in Id with ID
    if([[underscored substringWithRange:NSMakeRange(underscored.length - 2, 2)] isEqualToString:@"Id"])
        [underscored replaceCharactersInRange:NSMakeRange(underscored.length - 2, 2) withString:@"ID"];
	
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
