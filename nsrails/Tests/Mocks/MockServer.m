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
	NSString *text = [[NSString alloc] initWithContentsOfFile:[@"Tests/Mocks/" stringByAppendingFormat:@"%@.txt",file]
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
	return NSRDictionary(NSRArray(NSRDictionary(@"im",@"so"),NSRDictionary(@"hip",@"!")), @"dictionaries");
}

+ (NSDictionary *) newCustomCoder
{
	return NSRDictionary(@"LoweRCasE?",@"locally_lowercase",@"upper",@"remotely_uppercase",@"http://nsrails.com",@"locally_url",@"one,two,three",@"csv_array",@"invisible",@"remote_only",@"something",@"code_to_nil",@"2012-05-07T04:41:52Z",@"date_override_send",@"afsofauh",@"date_override_ret",NSRDictionary(@"COMP LOWERCASE?", @"component_name"),@"component");
}

+ (NSDictionary *) newCustomSender
{
	return NSRDictionary(@"retrieve", @"retrieve_only",@"send",@"send_only",@"shared",@"shared", @"shared explicit",@"shared_explicit", @"x",@"undefined");
}



@end
