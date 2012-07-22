/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSMutableArray+NSRails.m
 
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

#import "NSMutableArray+NSRails.h"
#import "NSRails.h"

@implementation NSMutableArray (NSRFetch)

- (void) assertValidSubclass:(Class)class cmd:(SEL)cmd
{
	if (![class isSubclassOfClass:[NSRRemoteObject class]])
	{
		[NSException raise:NSInvalidArgumentException format:@"Class passed into -[NSMutableArray %@] (%@) is not a subclass of NSRRemoteObject.",NSStringFromSelector(cmd), class];
	}
}

- (void) translateRemoteDictionariesIntoInstancesOfClass:(Class)class
{
	[self assertValidSubclass:class cmd:_cmd];
	
	for (int i = 0; i < self.count; i++)
	{
		NSDictionary *dict = [self objectAtIndex:i];
		if ([dict isKindOfClass:[NSDictionary class]])
		{
			NSRRemoteObject *obj = [class objectWithRemoteDictionary:dict];	
			
			[self replaceObjectAtIndex:i withObject:obj];
		}
	}
}

//helper method to set array to returned values - has to keep the objects, just update them individually to their new dict
- (void) setSelfToRemoteArray:(NSArray *)array forClass:(Class)class
{
	NSMutableArray *itemsToDelete = [self mutableCopy];
	
	for (NSDictionary *dict in array)
	{
		NSNumber *railsID = [dict objectForKey:@"id"];
		id existing = nil;
		
		if (railsID)
			existing = [[self filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"remoteID == %@",railsID]] lastObject];
		
		if (!existing)
		{
			id new = [class objectWithRemoteDictionary:dict];
			[self addObject:new];
		}
		else
		{
			[existing setPropertiesUsingRemoteDictionary:dict];

			[itemsToDelete removeObject:existing];
		}
	}
	
	if (itemsToDelete.count > 0)
	{
		[self removeObjectsInArray:itemsToDelete];
	}
}

- (BOOL) remoteFetchAll:(Class)class error:(NSError **)errorPtr
{
    return [self remoteFetchAll:class viaObject:nil error:errorPtr];
}

- (BOOL) remoteFetchAll:(Class)class viaObject:(NSRRemoteObject *)obj error:(NSError **)errorPtr
{
	[self assertValidSubclass:class cmd:_cmd];
	
	NSArray *array = [[NSRRequest requestToFetchAllObjectsOfClass:class viaObject:obj] sendSynchronous:errorPtr];
	
	if (!array)
		return NO;
	
	[self setSelfToRemoteArray:array forClass:class];
	
	return YES;
}

- (void) remoteFetchAll:(Class)class async:(NSRBasicCompletionBlock)block
{
    [self remoteFetchAll:class viaObject:nil async:block];
}

- (void) remoteFetchAll:(Class)class viaObject:(NSRRemoteObject *)obj async:(NSRBasicCompletionBlock)block
{
	[self assertValidSubclass:class cmd:_cmd];
	
	[[NSRRequest requestToFetchAllObjectsOfClass:class viaObject:obj] sendAsynchronous:
	 ^(id jsonRep, NSError *error) 
	 {
		 if (jsonRep)
		 {
			 [self setSelfToRemoteArray:jsonRep forClass:class];
		 }
		 block(error);
	 }];
}

@end
