/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSString+NSRInflection.m
 
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

#import "NSString+NSRInflection.h"

@implementation NSString (NSRInflection)

- (NSString *) nsr_stringByCamelizing
{
	NSMutableString *camelized = [NSMutableString string];
	BOOL capitalizeNext = NO;
	for (int i = 0; i < self.length; i++) 
	{
		NSString *str = [self substringWithRange:NSMakeRange(i, 1)];
		
		if ([str isEqualToString:@"_"])
		{
			capitalizeNext = YES;
			continue;
		}
		
		if (capitalizeNext) 
		{
			[camelized appendString:[str uppercaseString]];
			capitalizeNext = NO;
		} 
		else
		{
			[camelized appendString:str];
		}
	}
	
	// replace items that end in Id with ID
	if ([camelized hasSuffix:@"Id"])
		[camelized replaceCharactersInRange:NSMakeRange(camelized.length - 2, 2) withString:@"ID"];
	
	// replace items that end in Ids with IDs
	if ([camelized hasSuffix:@"Ids"])
		[camelized replaceCharactersInRange:NSMakeRange(camelized.length - 3, 3) withString:@"IDs"];
	
	return camelized;
}

- (NSString *) nsr_stringByUnderscoring
{
	return [self nsr_stringByUnderscoringIgnoringPrefix:NO];
}

- (NSString *) nsr_stringByUnderscoringIgnoringPrefix:(BOOL)stripPrefix
{
	NSCharacterSet *caps = [NSCharacterSet uppercaseLetterCharacterSet];
	
	NSMutableString *underscored = [NSMutableString string];
	BOOL isPrefix = YES;
	BOOL previousLetterWasCaps = NO;
	
	for (int i = 0; i < self.length; i++) 
	{
		unichar c = [self characterAtIndex:i];
		NSString *currChar = [NSString stringWithFormat:@"%C",c];
		if ([caps characterIsMember:c]) 
		{
			BOOL nextLetterIsCaps = (i+1 == self.length || [caps characterIsMember:[self characterAtIndex:i+1]]);
			
			//only add the delimiter if, it's not the first letter, it's not in the middle of a bunch of caps, and it's not a _ repeat
			if (i != 0 && !(previousLetterWasCaps && nextLetterIsCaps) && [self characterAtIndex:i-1] != '_')
			{
				if (isPrefix && stripPrefix)
				{
					underscored = [NSMutableString string];
				}
				else 
				{
					[underscored appendString:@"_"];
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


@end
