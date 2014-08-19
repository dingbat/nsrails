//
//  Inflection.m
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRAsserts.h"

@interface Inflection : SenTestCase

@end

#define NSRAssertEqualsUnderscored(string, underscored, strip) \
STAssertEqualObjects([string nsr_stringByUnderscoringIgnoringPrefix:strip], underscored, nil)

#define NSRAssertEqualsCamelized(string, camelized) \
STAssertEqualObjects([string nsr_stringByCamelizing], camelized, nil)

@implementation Inflection

- (void) test_underscore_no_prefix
{
    NSRAssertEqualsUnderscored(@"post", @"post", YES);
    NSRAssertEqualsUnderscored(@"Post", @"post", YES);
    NSRAssertEqualsUnderscored(@"DPost", @"post", YES);
    NSRAssertEqualsUnderscored(@"DHPost", @"post", YES);
    NSRAssertEqualsUnderscored(@"DHpost", @"hpost", YES);
    NSRAssertEqualsUnderscored(@"PostDH", @"post_dh", YES);
    NSRAssertEqualsUnderscored(@"DHPostDH", @"post_dh", YES);
}

- (void) test_underscore
{
    NSRAssertEqualsUnderscored(@"p", @"p", NO);
    NSRAssertEqualsUnderscored(@"post", @"post", NO);
    NSRAssertEqualsUnderscored(@"Post", @"post", NO);
    NSRAssertEqualsUnderscored(@"POST", @"post", NO);
    NSRAssertEqualsUnderscored(@"DHPost", @"dh_post", NO);
    NSRAssertEqualsUnderscored(@"postObject", @"post_object", NO);
    NSRAssertEqualsUnderscored(@"postObjectA", @"post_object_a", NO);
    NSRAssertEqualsUnderscored(@"postObjectAB", @"post_object_ab", NO);
    NSRAssertEqualsUnderscored(@"postObjectABCSomething", @"post_object_abc_something", NO);
    NSRAssertEqualsUnderscored(@"post_object", @"post_object", NO);
    NSRAssertEqualsUnderscored(@"post_Object", @"post_object", NO);    
}

- (void) test_camelize
{
    NSRAssertEqualsCamelized(@"p", @"p");
    NSRAssertEqualsCamelized(@"post", @"post");
    NSRAssertEqualsCamelized(@"Post", @"Post");
    NSRAssertEqualsCamelized(@"post_object", @"postObject");
    NSRAssertEqualsCamelized(@"post_object_id", @"postObjectID");
    NSRAssertEqualsCamelized(@"post_object_ids", @"postObjectIDs");
    NSRAssertEqualsCamelized(@"post_object_idx", @"postObjectIdx");
    NSRAssertEqualsCamelized(@"post_object_abc", @"postObjectAbc");
    NSRAssertEqualsCamelized(@"post_object_ABC", @"postObjectABC");
    NSRAssertEqualsCamelized(@"post_object_ABC_something", @"postObjectABCSomething");
    NSRAssertEqualsCamelized(@"post__object", @"postObject");
    NSRAssertEqualsCamelized(@"postOBject", @"postOBject");
    NSRAssertEqualsCamelized(@"postObject", @"postObject");
}

@end
