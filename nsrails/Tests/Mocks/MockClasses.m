//
//  MockClasses.m
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MockClasses.h"
#import "NSRails.h"

@implementation Tester
@synthesize tester, array, dictionary;
@end

@implementation CustomClass

+ (NSString *) remoteModelName
{
	return @"custom";
}

@end

@implementation SuperClass
@synthesize superString;
@end

@implementation SubClass
@synthesize subDate, anything, primitiveInt, rect;
@end

@implementation Post
@synthesize author, content, updatedAt, responses, noResponseRelationship;

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
	if ([property isEqualToString:@"responses"] && !noResponseRelationship)
	{
		return [NSRRelationship hasMany:[Response class]];
	}
	return [super relationshipForProperty:property];
}

@end

@implementation Response
@synthesize post, content, author, belongsToPost;

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
	if ([property isEqualToString:@"post"] && !belongsToPost)
	{
		return [NSRRelationship hasOne:[Post class]];
	}
	return [super relationshipForProperty:property];
}

@end


@implementation NestParent

+ (NSString *) remoteModelName
{
	return @"parent";
}

@end

@implementation NestChild
@synthesize parent;

@end

@implementation NestChildPrefixed

+ (NSString *) remoteModelName
{
	return @"pref";
}

- (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)req
{
	return self.parent;
}

@end

@implementation NestChildPrefixedChild
@synthesize childParent;

+ (NSString *) remoteModelName
{
	return @"pref2";
}

- (NSRRemoteObject *) objectUsedToPrefixRequest:(NSRRequest *)req
{
	if ([req.httpMethod isEqualToString:@"GET"] || [req.httpMethod isEqualToString:@"PATCH"])
		return childParent;
	return nil;
}

@end

@implementation DictionaryNester
@synthesize dictionaries;
@end


@implementation Book
@synthesize owners, nestPerson;

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
	if ([property isEqualToString:@"owners"])
	{
		return [NSRRelationship hasMany:[Person class]];
	}
	return [super relationshipForProperty:property];
}

- (BOOL) shouldSendProperty:(NSString *)property whenNested:(BOOL)nested
{
	if (nestPerson && nested && [property isEqualToString:@"owners"])
		return YES;
	
	return [super shouldSendProperty:property whenNested:nested];
}

@end

@implementation Person
@synthesize books;

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
	if ([property isEqualToString:@"books"])
		return [NSRRelationship hasMany:[Book class]];
	
	return [super relationshipForProperty:property];
}

@end

@implementation Bird
@synthesize eggs, nestEggs;

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
	if ([property isEqualToString:@"eggs"])
		return [NSRRelationship hasMany:[Egg class]];
	return [super relationshipForProperty:property];
}

- (BOOL) shouldSendProperty:(NSString *)property whenNested:(BOOL)nested
{
	if ([property isEqualToString:@"eggs"] && nested && nestEggs)
		return YES;
	return [super shouldSendProperty:property whenNested:nested];
}

@end

@implementation Egg
@synthesize bird, nest, nestBird, hasOneBird;

- (NSRRelationship *) relationshipForProperty:(NSString *)property
{
	if ([property isEqualToString:@"nest"] || ([property isEqualToString:@"bird"] && hasOneBird))
		return [NSRRelationship hasOne:[Nest class]];
	return [super relationshipForProperty:property];
}

- (BOOL) shouldSendProperty:(NSString *)property whenNested:(BOOL)nested
{
	if ([property isEqualToString:@"bird"] && nested && nestBird)
		return YES;
	return [super shouldSendProperty:property whenNested:nested];
}

@end

@implementation Nest
@end

//////////

@implementation CustomCoderComponent
@synthesize componentName;
@end

@implementation CustomCoder
@synthesize encodeNonJSON;
@synthesize locallyURL, locallyLowercase, remotelyUppercase, componentWithFlippingName, codeToNil, dateOverrideSend, dateOverrideRet, csvArray, remoteOnly;

- (id) encodeValueForProperty:(NSString *)key remoteKey:(NSString **)remoteKey
{
	if ([key isEqualToString:@"remoteOnly"])
	{
		if (encodeNonJSON)
			return [[NSScanner alloc] init];
		return @"remote";		
	}
	if ([key isEqualToString:@"dateOverrideSend"])
	{
		return @"override!";
	}
	if ([key isEqualToString:@"csvArray"])
	{
		return [csvArray componentsJoinedByString:@","];
	}
	if ([key isEqualToString:@"componentWithFlippingName"])
	{
		*remoteKey = @"component";
		componentWithFlippingName.componentName = [componentWithFlippingName.componentName uppercaseString];
		return [componentWithFlippingName remoteDictionaryRepresentationWrapped:YES];	
	}
	if ([key isEqualToString:@"locallyURL"])
	{
		return [locallyURL absoluteString];	
	}
	if ([key isEqualToString:@"remotelyUppercase"])
	{
		return [remotelyUppercase uppercaseString];
	}
	if ([key isEqualToString:@"codeToNil"])
	{
		return nil;
	}
	
	return [super encodeValueForProperty:key remoteKey:remoteKey];
}

- (void) decodeRemoteValue:(id)remoteObject forRemoteKey:(NSString *)remoteKey change:(BOOL *)change
{
	if ([remoteKey isEqualToString:@"date_override_ret"])
	{
		self.dateOverrideRet = [NSDate dateWithTimeIntervalSince1970:0];
	}
	else if ([remoteKey isEqualToString:@"csv_array"])
	{
		self.csvArray = [remoteObject componentsSeparatedByString:@","];
	}
	else if ([remoteKey isEqualToString:@"code_to_nil"])
	{
		self.codeToNil = nil;
	}
	else if ([remoteKey isEqualToString:@"locally_url"])
	{
		self.locallyURL = [NSURL URLWithString:remoteObject];
	}
	else if ([remoteKey isEqualToString:@"locally_lowercase"])
	{
		self.locallyLowercase = [remoteObject lowercaseString];
	}
	else if ([remoteKey isEqualToString:@"component"])
	{
		CustomCoderComponent *new = [CustomCoderComponent objectWithRemoteDictionary:remoteObject];
		new.componentName = [new.componentName lowercaseString];
		self.componentWithFlippingName = new;
	}
	else if (![remoteKey isEqualToString:@"remote_only"])
	{
		[super decodeRemoteValue:remoteObject forRemoteKey:remoteKey change:change];
	}
}

@end

@implementation CustomSender
@synthesize local, retrieveOnly, shared, sharedExplicit, sendOnly, undefined;

- (BOOL) shouldSendProperty:(NSString *)property whenNested:(BOOL)nested
{
	if ([property isEqualToString:@"retrieveOnly"] || [property isEqualToString:@"local"])
		return NO;
	
	return [super shouldSendProperty:property whenNested:nested];
}

- (void) decodeRemoteValue:(id)remoteObject forRemoteKey:(NSString *)remoteKey change:(BOOL *)change
{
	if (![remoteKey isEqualToString:@"send_only"] || [remoteKey isEqualToString:@"local"])
		[super decodeRemoteValue:remoteObject forRemoteKey:remoteKey change:change];
}

+ (NSMutableArray *) remoteProperties
{
	NSMutableArray *props = [super remoteProperties];
	[props removeObject:@"undefined"];
	return props;
}

@end

@implementation CDPost
@synthesize author, content, responses;

+ (NSString *) entityName
{
	return @"Post";
}

@end

@implementation CDResponse
@synthesize author, content, post;

+ (NSString *) entityName
{
	return @"Response";
}

@end
