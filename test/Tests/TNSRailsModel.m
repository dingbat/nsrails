//
//  TNSRailsModel.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface PickySender : NSRailsModel
@property (nonatomic, strong) NSString *local, *retrieveOnly, *sendOnly, *shared, *sharedExplicit, *undefined;
@end

@implementation PickySender
@synthesize local, retrieveOnly, shared, sharedExplicit, sendOnly, undefined;
NSRailsSync(local -x, retrieveOnly -r, shared, sharedExplicit -rs, sendOnly -s)
@end

//////

@interface PickyCoderComponent : NSRailsModel
@property (nonatomic, strong) NSString *componentName;
@end

@implementation PickyCoderComponent
@synthesize componentName;
@end

@interface PickyCoder : NSRailsModel

@property (nonatomic) BOOL encodeNonJSON;
@property (nonatomic, strong) NSURL *locallyURL;
@property (nonatomic, strong) NSString *locallyLowercase, *remotelyUppercase, *codeToNil;
@property (nonatomic, strong) PickyCoderComponent *componentWithFlippingName;

@end

@implementation PickyCoder
@synthesize locallyURL, locallyLowercase, remotelyUppercase, componentWithFlippingName, codeToNil, encodeNonJSON;
NSRailsSync(locallyURL -ed, locallyLowercase -d, remotelyUppercase -e, remoteOnly -se, codeToNil -ed, componentWithFlippingName=component -de);

- (id) encodeRemoteOnly
{
	if (encodeNonJSON)
	{
		return [[NSScanner alloc] init];
	}
	return @"remote";
}

- (NSString *) decodeCodeToNil:(NSString *)str
{
	return nil;
}

- (NSString *) encodeCodeToNil
{
	return nil;
}

- (NSURL *) decodeLocallyURL:(NSString *)remoteUrl
{
	return [NSURL URLWithString:remoteUrl];
}

- (NSString *) decodeLocallyLowercase:(NSString *)remote
{
	return [remote lowercaseString];
}

- (PickyCoderComponent *) decodeComponentWithFlippingName:(NSDictionary *)remoteDict
{
	PickyCoderComponent *new = [[PickyCoderComponent alloc] initWithRemoteDictionary:remoteDict];
	new.componentName = [new.componentName lowercaseString];
	
	return new;
}

- (NSString *) encodeComponentWithFlippingName
{
	componentWithFlippingName.componentName = [componentWithFlippingName.componentName uppercaseString];
	return [componentWithFlippingName remoteJSONRepresentation];
}

- (NSString *) encodeLocallyURL
{
	NSString *ret = [locallyURL description];
	NSLog(@"returned %@",ret);
	return ret;
}

- (NSString *) encodeRemotelyUppercase
{
	return [remotelyUppercase uppercaseString];
}

@end

@implementation MockServer (pickys)

+ (NSString *) newPickyCoder
{
	//replacing ' with ", using \" every other char makes it unreadable
	return [@"{'locally_lowercase':'LoweRCasE?','remotely_uppercase':'upper','locally_url':'http://nsrails.com','remote_only':'invisible','code_to_nil':'something','component':{'component_name':'COMP LOWERCASE?'}}" stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
}

+ (NSString *) newPickySender
{
	//replacing ' with ", using \" every other char makes it unreadable
	return [@"{'retrieve_only':'retrieve','send_only':'send','shared':'shared','shared_explicit':'shared explicit','undefined':'x'}" stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
}

@end

@interface NoSyncStringTester : NSRailsModel
@property (nonatomic, strong) NSString *property1;
@end
@implementation NoSyncStringTester
@synthesize property1;
@end

@interface SyncStringTester : NSRailsModel
@property (nonatomic, strong) NSString *property1, *property2, *property3;
@end

@implementation SyncStringTester
@synthesize property1, property2, property3;
NSRailsSync(property1, property2, property3)
@end

@interface SyncStringTesterChild : NSRailsModel
@property (nonatomic, strong) NSString *childProperty1, *childProperty2;
@end

@implementation SyncStringTesterChild
@synthesize childProperty1, childProperty2;
NSRailsSync(childProperty1, childProperty2)
@end

@interface TNSRailsModel : GHTestCase
@end

@implementation TNSRailsModel

- (void) test_nsrailssync
{
	GHAssertEqualStrings([NoSyncStringTester masterNSRailsSync], @", property1, remoteID=id", @"failed default (no NSRS) being *");
	
	
	GHAssertEqualStrings([SyncStringTester masterNSRailsSync], @"property1, property2, property3, remoteID=id", @"default (no override) failed");
	GHAssertEqualStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"property1, property2, property3"], @"property1, property2, property3, remoteID=id", @"override failed");
	GHAssertEqualStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"*"], @", property3, property2, property1, remoteID=id", @"* failed");
	GHAssertEqualStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"*, property1 -x"], @", property1 -x, property3, property2, property1, remoteID=id", @"* with extraneous failed");
	GHAssertEqualStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"*, property1 -x, remoteID -x"], @", property1 -x, remoteID -x, property3, property2, property1, remoteID=id", @"* with extraneous failed");

	// Inheritance
	
	GHAssertEqualStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"NSRNoCarryFromSuper"], @", remoteID=id", @"should be blank if nothing declared and nothing inherited");
	GHAssertEqualStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"NSRNoCarryFromSuper *"], @" , property3, property2, property1, remoteID=id", @"should be only my properties if * declared and nothing inherited");
}

- (void) test_custom_requests
{
	// Root
	
	GHAssertEqualStrings([NSRailsModel routeForControllerMethod:nil], @"", @"Root route failed");	
	GHAssertEqualStrings([NSRailsModel routeForControllerMethod:@"action"], @"action", @"Root route failed");	
	
	// Controller (class)
	
	GHAssertEqualStrings([Post routeForControllerMethod:nil], @"posts", @"Nil controller route failed");	
	GHAssertEqualStrings([Post routeForControllerMethod:@"action"], @"posts/action", @"Controller route failed");
	
	// Instance
	
	Post *post = [[Post alloc] init];
	GHAssertThrows([post routeForInstanceMethod:nil], @"Should have been an exception getting instance route if nil remoteID");
	
	post.remoteID = [NSNumber numberWithInt:1];
	GHAssertEqualStrings([post routeForInstanceMethod:nil], @"posts/1", @"Nil instance route failed");
	GHAssertEqualStrings([post routeForInstanceMethod:@"action"], @"posts/1/action", @"Instance route failed");
}

- (void) test_encode_decode
{
	PickyCoder *p = [[PickyCoder alloc] initWithRemoteJSON:[MockServer newPickyCoder]];
	p.encodeNonJSON = NO;
	
	GHAssertTrue([p.locallyURL isKindOfClass:[NSURL class]], @"Should've decoded into a URL");
	GHAssertNil(p.codeToNil, @"Should've decoded codeToNil into nil");
	GHAssertEqualStrings([p.locallyURL description], @"http://nsrails.com", @"Should've decoded into URL & retain content");
	GHAssertEqualStrings(p.locallyLowercase, @"lowercase?", @"Should've decoded into lowercase");
	GHAssertEqualStrings(p.remotelyUppercase, @"upper", @"Should've kept the same");
	GHAssertEqualStrings(p.componentWithFlippingName.componentName, @"comp lowercase?", @"Should've decoded comp name into lowercase");
	
	p.codeToNil = @"Something";
	
	NSDictionary *sendDict = [p dictionaryOfRemoteProperties];
	GHAssertTrue([[sendDict objectForKey:@"locally_url"] isKindOfClass:[NSString class]],@"Should've encoded NSURL -> string");
	GHAssertTrue([[sendDict objectForKey:@"code_to_nil"] isKindOfClass:[NSNull class]], @"Should've encoded codeToNil into NSNull");
	GHAssertEqualStrings([sendDict objectForKey:@"locally_url"], @"http://nsrails.com", @"Should've encoded into string & retain content");
	GHAssertEqualStrings([sendDict objectForKey:@"locally_lowercase"], @"lowercase?", @"Should've kept as lowercase");
	GHAssertEqualStrings([sendDict objectForKey:@"remotely_uppercase"], @"UPPER", @"Should've encoded to uppercase");
	GHAssertEqualStrings(p.componentWithFlippingName.componentName, @"COMP LOWERCASE?", @"Should've encoded comp name into uppercase");
	
	GHAssertEqualStrings([sendDict objectForKey:@"remote_only"], @"remote", @"Should've captured remoteOnly!");
	
	p.encodeNonJSON = YES;
	
	GHAssertThrows([p dictionaryOfRemoteProperties], @"Encoding into non-JSON for sendable dict - where's the error?");
}

- (void) test_send_retrieve
{
	PickySender *p = [[PickySender alloc] init];
	p.local = @"local";
	p.sendOnly = @"send--local";
	p.undefined = @"local";
	[p setPropertiesUsingRemoteJSON:[MockServer newPickySender]];
	
	GHAssertEqualStrings(p.local, @"local", @"Should've kept local... -x");
	GHAssertEqualStrings(p.sendOnly, @"send--local", @"Should've kept send... -s");
	GHAssertEqualStrings(p.retrieveOnly, @"retrieve", @"Should've set retrieve... -r");
	GHAssertEqualStrings(p.shared, @"shared", @"Should've set shared... blank");
	GHAssertEqualStrings(p.sharedExplicit, @"shared explicit", @"Should've set sharedExplicit... -rs");
	GHAssertEqualStrings(p.undefined, @"local", @"Shouldn't have set undefined... not in NSRS");

	NSDictionary *sendDict = [p dictionaryOfRemoteProperties];
	GHAssertNil([sendDict objectForKey:@"retrieve_only"], @"Shouldn't send retrieve-only... -r");
	GHAssertNil([sendDict objectForKey:@"local"], @"Shouldn't send local-only... -x");
	GHAssertNil([sendDict objectForKey:@"undefined"], @"Shouldn't send undefined... not in NSRS");
	GHAssertEqualStrings([sendDict objectForKey:@"send_only"], @"send--local", @"Should've sent send... -s");
	GHAssertEqualStrings([sendDict objectForKey:@"shared"], @"shared", @"Should've sent shared... blank");
	GHAssertEqualStrings([sendDict objectForKey:@"shared_explicit"], @"shared explicit", @"Should've sent sharedExplicit... -rs");
}

- (void) test_no_rails_sync
{
	NSRAssertEqualArraysNoOrder([[ClassWithNoRailsSync alloc] init].propertyCollection.sendableProperties, @"remoteID", @"attribute");
}


- (void)setUpClass
{
	// Run at start of all tests in the class
}

- (void)tearDownClass {
	// Run at end of all tests in the class
}

- (void)setUp
{
	// Run before each test method
}

- (void)tearDown {
	// Run after each test method
}

@end