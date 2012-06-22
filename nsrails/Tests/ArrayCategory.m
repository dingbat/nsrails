//
//  ArrayCategory.m
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRAsserts.h"

@interface ArrayCategory : SenTestCase

@end

@implementation ArrayCategory

- (void) test_array_category
{
	NSMutableArray *a = [[NSMutableArray alloc] init];
	
	STAssertThrows([a translateRemoteDictionariesIntoInstancesOfClass:nil], @"Should throw exception if no class given");
	STAssertThrows([a translateRemoteDictionariesIntoInstancesOfClass:[NSString class]], @"Should throw exception if bad given");
	
	[a translateRemoteDictionariesIntoInstancesOfClass:[Post class]];
	
	STAssertTrue(a.count == 0, @"should still have 0 elements after empty array");
	
	[a addObject:NSRDictionary(NSRNumber(5),@"id",@"hi",@"author")];
	[a addObject:NSRDictionary(NSRNumber(6),@"id",@"hi",@"3f2f3f")];
	
	for (int i = 0; i < 2; i++)
	{
		[a translateRemoteDictionariesIntoInstancesOfClass:[Post class]];
		
		STAssertTrue(a.count == (i == 0 ? 2 : 3), @"should still have X elements after translation");
		
		STAssertTrue([[a objectAtIndex:0] isKindOfClass:[Post class]], @"should be NoSyncStringTester after translation");
		STAssertEqualObjects([[a objectAtIndex:0] remoteID],NSRNumber(5), @"should have appropriate remoteID");
		STAssertEqualObjects([[a objectAtIndex:0] author],@"hi", @"should have appropriate property1");
		
		STAssertTrue([[a objectAtIndex:1] isKindOfClass:[Post class]], @"should be NoSyncStringTester after translation");
		STAssertEqualObjects([[a objectAtIndex:1] remoteID],NSRNumber(6), @"should have appropriate remoteID");
		STAssertNil([[a objectAtIndex:1] author],@"should have appropriate property1");
		
		if (i == 1)
		{
			STAssertTrue([[a objectAtIndex:2] isKindOfClass:[NSString class]], @"should be NSString after translation");
		}
		
		[a addObject:@"str"];
	}	
}

@end
