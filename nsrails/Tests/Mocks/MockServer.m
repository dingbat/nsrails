//
//  MockServer.m
//  NSRails
//
//  Created by Dan Hassin on 5/7/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "MockServer.h"
#import "NSRAsserts.h"

@implementation MockServer

+ (NSString *) datetime
{
	return @"2012-05-07T04:41:52Z";
}

+ (NSString *) creation201
{
	return @"{\"author\":\"Soemthig\",\"content\":\"test\",\"created_at\":\"2012-05-07T21:17:30Z\",\"id\":133,\"updated_at\":\"2012-05-07T21:17:30Z\",\"responses\":[]}\"";
}

+ (NSString *) ok200
{
	return @"";
}

+ (NSString *) fullErrorWithFile:(NSString *)file
{
	NSString *text = [[NSString alloc] initWithContentsOfFile:[[NSBundle bundleForClass:self] pathForResource:file ofType:@"txt"]
												 usedEncoding:NULL
														error:nil];
	
	if (!text)
		[NSException raise:@"Mock server error" format:@"Could not load text file '%@.txt'",file];
	
	return text;
}

+ (NSString *) full404Error
{
	return [self fullErrorWithFile:@"404"];
}

+ (NSString *) full404Error2
{
	return [self fullErrorWithFile:@"404-2"];
}

+ (NSString *) full500Error
{
	return [self fullErrorWithFile:@"500"];
}

+ (NSString *) short500Error
{
	return @"Template is missing";
}

+ (NSString *) short404Error
{
	return @"Couldn't find Post with id=4";
}

+ (NSString *) short404Error2
{
	return @"No route matches [GET] \"/4.json\"";
}

+ (NSString *) validation422Error
{
	return @"{\"content\":[\"can't be blank\"],\"author\":[\"can't be blank\"]}";
}

+ (NSArray *) statusCodes
{
	return [NSArray arrayWithObjects:[NSNumber numberWithInt:404], [NSNumber numberWithInt:404], [NSNumber numberWithInt:500], [NSNumber numberWithInt:422], nil];
}

+ (NSArray *) fullErrors
{
	return [NSArray arrayWithObjects:[self full404Error], [self full404Error2], [self full500Error], @"Unprocessable Entity", nil];
}

+ (NSArray *) shortErrors
{	
	return [NSArray arrayWithObjects:[self short404Error], [self short404Error2], [self short500Error], @"Unprocessable Entity", nil];
}


/**/

+ (NSDictionary *) newDictionaryNester
{
	return @{@"dictionaries":@[@{@"so":@"im"},@{@"!":@"hip"}]};
}

+ (NSDictionary *) newCustomCoder
{
	return @{@"locally_lowercase":@"LoweRCasE?",@"remotely_uppercase":@"upper",@"locally_url":@"http://nsrails.com",@"csv_array":@"one,two,three",@"remote_only":@"invisible",@"code_to_nil":@"something",@"date_override_send":@"2012-05-07T04:41:52Z",@"date_override_ret":@"afsofauh",@"component":@{@"component_name":@"COMP LOWERCASE?"},@"rails":@"renamed"};
}

+ (NSDictionary *) newCustomSender
{
	return @{@"retrieve_only":@"retrieve",@"send_only":@"send",@"shared":@"shared", @"shared_explicit":@"shared explicit", @"undefined":@"x"};
}



@end
