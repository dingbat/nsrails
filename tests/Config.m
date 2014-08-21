//
//  Config.m
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

extern NSString * const NSRRails3DateFormat;
extern NSString * const NSRRails4DateFormat;

@interface Config : XCTestCase

@end

#define NSRURL(string) [NSURL URLWithString:[@"http://" stringByAppendingString:string]]

#define NSRAssertRelevantConfigURL(string) \
XCTAssertEqualObjects([@"http://" stringByAppendingString:string], [NSRConfig contextuallyRelevantConfig].rootURL.absoluteString)

@implementation Config

- (void) setUp
{
    [NSRConfig resetConfigs];
}

- (void) test_nested_contexts
{
    [[NSRConfig defaultConfig] setRootURL:NSRURL(@"Default")];
    
    NSRAssertRelevantConfigURL(@"Default");
    
    [[NSRConfig defaultConfig] useIn:^
     {
         NSRConfig *c = [[NSRConfig alloc] init];
         c.rootURL = NSRURL(@"Nested");
         [c use];
         
         NSRAssertRelevantConfigURL(@"Nested");
         
         [[NSRConfig defaultConfig] useIn:^
          {
              NSRAssertRelevantConfigURL(@"Default");
              
              [c useIn:^
               {
                   NSRAssertRelevantConfigURL(@"Nested");
               }];
          }];
         
         [c end];
         
         NSRAssertRelevantConfigURL(@"Default");
     }];
    
    XCTAssertEqualObjects(@"custom_coder", [CustomCoder remoteModelName], @"auto-underscoring");
    
    NSRConfig *c = [[NSRConfig alloc] init];
    c.rootURL = NSRURL(@"NoAuto");
    c.autoinflectsClassNames = NO;
    [c useIn:
     ^{
         NSRAssertRelevantConfigURL(@"NoAuto");
         
         XCTAssertEqualObjects(@"CustomCoder", [CustomCoder remoteModelName], @"No auto-underscoring");
     }];
    
    NSRAssertRelevantConfigURL(@"Default");
}

- (void) test_date_conversion
{
    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion3];

    NSString *mockDatetime = [MockServer datetime];
    
    //Default Rails format
    
    //string -> date
    NSDate *date = [[NSRConfig defaultConfig] dateFromString:mockDatetime];
    XCTAssertNotNil(date, @"String -> date conversion failed (default format)");
    
    //date -> string
    NSString *string = [[NSRConfig defaultConfig] stringFromDate:date];
    XCTAssertNotNil(string, @"Date -> string conversion failed (default format)");
    XCTAssertEqualObjects(string, mockDatetime, @"Date -> string conversion didn't return same result from server");
    
    
    //If format changes...
    [[NSRConfig defaultConfig] setDateFormat:@"yyyy"];
    
    //string -> date
    XCTAssertNil([[NSRConfig defaultConfig] dateFromString:mockDatetime], @"Should be nil - receiving config format != server format");
    
    //date -> string
    NSString *string2 = [[NSRConfig defaultConfig] stringFromDate:date];
    XCTAssertFalse([string2 isEqualToString:mockDatetime], @"Datetime string sent and datetime string server accepts should not be equal. (format mismatch)");
    
    NSString *string3 = [[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:100000]];
    XCTAssertEqualObjects(string3, @"1970", @"Datetime string should be formatted to 'yyyy'");
    
    //invalid date format
    [[NSRConfig defaultConfig] setDateFormat:@"!@#@$"];

    XCTAssertEqualObjects([[NSRConfig defaultConfig] stringFromDate:[NSDate dateWithTimeIntervalSince1970:0]], @"!@#@$", @"New format should've been applied");
}

- (void) test_rails_versions
{
    //rails 4 should be the default rails configuration
    
    NSString *df3 = NSRRails3DateFormat;
    NSString *um3 = @"PUT";

    NSString *df4 = NSRRails4DateFormat;
    NSString *um4 = @"PATCH";

    XCTAssertEqualObjects([NSRConfig defaultConfig].dateFormat, df4);
    XCTAssertEqualObjects([NSRConfig defaultConfig].updateMethod, um4);

    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion3];
    XCTAssertEqualObjects([NSRConfig defaultConfig].dateFormat, df3);
    XCTAssertEqualObjects([NSRConfig defaultConfig].updateMethod, um3);
    
    [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion4];
    XCTAssertEqualObjects([NSRConfig defaultConfig].dateFormat, df4);
    XCTAssertEqualObjects([NSRConfig defaultConfig].updateMethod, um4);
}

@end

