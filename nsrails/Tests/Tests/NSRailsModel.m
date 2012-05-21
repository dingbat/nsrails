//
//  NSRailsModel.m
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

@interface PropertyTester : NSRailsModel
@property (nonatomic, strong) id property1;
@end 

@implementation PropertyTester
@synthesize property1;
@end

@interface BadCoder : NSRailsModel
@end

@implementation BadCoder
NSRailsSync(thing -e)
@end

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
@property (nonatomic, strong) NSDate *dateOverrideSend, *dateOverrideRet;

@end

@implementation PickyCoder
@synthesize locallyURL, locallyLowercase, remotelyUppercase, componentWithFlippingName, codeToNil, encodeNonJSON, dateOverrideSend, dateOverrideRet;
NSRailsSync(locallyURL=locally_url -ed, locallyLowercase -d, remotelyUppercase -e, remoteOnly -se, codeToNil -ed, componentWithFlippingName=component -de, dateOverrideSend -e, dateOverrideRet -d);

- (id) encodeRemoteOnly
{
	if (encodeNonJSON)
	{
		return [[NSScanner alloc] init];
	}
	return @"remote";
}

- (id) encodeDateOverrideSend
{
	return @"override!";
}

- (id) decodeDateOverrideRet:(NSString *)json
{
	return [NSDate dateWithTimeIntervalSince1970:0];
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
	return ret;
}

- (NSString *) encodeRemotelyUppercase
{
	return [remotelyUppercase uppercaseString];
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

@interface Empty : NSRailsModel
@end

@implementation Empty
@end

@interface DictionaryNester : NSRailsModel
@property (nonatomic, strong) NSArray *dictionaries;
@end

@implementation DictionaryNester
@synthesize dictionaries;
NSRailsSync(dictionaries -m);
@end

@interface LadiesMan : NSRailsModel
@property (nonatomic, strong) NSArray *lotsOfDates;
@end

@implementation LadiesMan
@synthesize lotsOfDates;
NSRailsSync(lotsOfDates:NSDate);

@end

@interface CustomGuy : NSRailsModel
@end

@implementation CustomGuy
NSRailsUseConfig(@"url", @"user", @"pass");
NSRailsSync(something);
@end

@implementation MockServer (pickys)

+ (NSString *) newPickyCoder
{
	//replacing ' with ", using \" every other char makes it unreadable
	return [@"{'locally_lowercase':'LoweRCasE?','remotely_uppercase':'upper','locally_url':'http://nsrails.com','remote_only':'invisible','code_to_nil':'something','date_override_send':'2012-05-07T04:41:52Z','date_override_ret':'afsofauh','component':{'component_name':'COMP LOWERCASE?'}}" stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
}

+ (NSString *) newPickySender
{
	//replacing ' with ", using \" every other char makes it unreadable
	return [@"{'retrieve_only':'retrieve','send_only':'send','shared':'shared','shared_explicit':'shared explicit','undefined':'x'}" stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
}

+ (NSString *) newDictionaryNester
{
	return [@"{'dictionaries':[{'im':'so','hip':'!'}, {}]}" stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
}

+ (NSString *) newLadiesMan
{
	return [@"{'lots_of_dates':['2012-05-07T04:41:52Z','2012-05-07T04:41:52Z','2012-05-07T04:41:52Z']}" stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
}

@end

@interface TNSRailsModel : GHTestCase
@end

#define NSRAssertEqualSyncStrings(a,b,reason) \
NSRAssertEqualArraysNoOrderNoBlanks([a componentsSeparatedByString:@","],[b componentsSeparatedByString:@","])

@implementation TNSRailsModel

- (void) test_nsrailssync
{
	NSRAssertEqualSyncStrings([Empty masterNSRailsSync], @"remoteID=id", @"failed default (no NSRS) being * AND empty");
	
	NSRAssertEqualSyncStrings([NoSyncStringTester masterNSRailsSync], @"property1, remoteID=id", @"failed default (no NSRS) being *");
	
	NSRAssertEqualSyncStrings([SyncStringTester masterNSRailsSync], @"property1, property2, property3, remoteID=id", @"default (no override) failed");
	NSRAssertEqualSyncStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"property1, property2, property3"], @"property1, property2, property3, remoteID=id", @"override failed");
	NSRAssertEqualSyncStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"*"], @"property3, property2, property1, remoteID=id", @"* failed");
	NSRAssertEqualSyncStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"*, property1 -x"], @"property1 -x, property3, property2, property1, remoteID=id", @"* with extraneous failed");
	NSRAssertEqualSyncStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"*, property1 -x, remoteID -x"], @"property1 -x, remoteID -x, property3, property2, property1, remoteID=id", @"* with extraneous failed");
	
	// Inheritance
	
	NSRAssertEqualSyncStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"NSRNoCarryFromSuper"], @"remoteID=id", @"should be blank if nothing declared and nothing inherited");
	NSRAssertEqualSyncStrings([SyncStringTester masterNSRailsSyncWithOverrideString:@"NSRNoCarryFromSuper *"], @"property3, property2, property1, remoteID=id", @"should be only my properties if * declared and nothing inherited");
}

- (void) test_custom_requests
{
	// Root
	
	GHAssertEqualStrings([NSRailsModel routeForControllerMethod:nil], @"", @"Root route failed");	
	GHAssertEqualStrings([NSRailsModel routeForControllerMethod:@"action"], @"action", @"Root route failed");	
	
	// Controller (class)
	
	GHAssertEqualStrings([Empty routeForControllerMethod:nil], @"empties", @"Nil controller route failed");	
	GHAssertEqualStrings([Empty routeForControllerMethod:@"action"], @"empties/action", @"Controller route failed");
	
	// Instance
	
	Empty *smth = [[Empty alloc] init];
	GHAssertThrowsSpecificNamed([smth routeForInstanceMethod:nil], NSException, NSRailsNullRemoteIDException, @"Should have been an exception getting instance route if nil remoteID");
	
	smth.remoteID = [NSNumber numberWithInt:1];
	GHAssertEqualStrings([smth routeForInstanceMethod:nil], @"empties/1", @"Nil instance route failed");
	GHAssertEqualStrings([smth routeForInstanceMethod:@"action"], @"empties/1/action", @"Instance route failed");
}

- (void) test_encode_decode
{
	BadCoder *b = [[BadCoder alloc] init];
	GHAssertThrows([b dictionaryOfRemoteProperties], @"Should throw unrecognized selector for encode:");
	
	PickyCoder *p = [[PickyCoder alloc] initWithRemoteJSON:[MockServer newPickyCoder]];
	p.encodeNonJSON = NO;
	
	GHAssertTrue([p.locallyURL isKindOfClass:[NSURL class]], @"Should've decoded into a URL");
	GHAssertTrue([p.dateOverrideSend isKindOfClass:[NSDate class]], @"Should've decoded into an NSDate");
	GHAssertTrue([p.dateOverrideRet isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]], @"Should've used custom decode");
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
	GHAssertEqualStrings([sendDict objectForKey:@"date_override_send"], @"override!", @"Should've overriden NSDate encode");
	GHAssertEqualStrings([sendDict objectForKey:@"date_override_ret"], @"1969-12-31T19:00:00Z", @"Should've overriden NSDate decode");
	GHAssertEqualStrings(p.componentWithFlippingName.componentName, @"COMP LOWERCASE?", @"Should've encoded comp name into uppercase");
	
	GHAssertEqualStrings([sendDict objectForKey:@"remote_only"], @"remote", @"Should've captured remoteOnly!");
	
	p.encodeNonJSON = YES;
	
	GHAssertThrowsSpecificNamed([p dictionaryOfRemoteProperties], NSException, NSRailsJSONParsingException, @"Encoding into non-JSON for sendable dict - where's the error?");
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

- (void) test_nesting_dictionaries
{
	DictionaryNester *nester = [[DictionaryNester alloc] initWithRemoteJSON:[MockServer newDictionaryNester]];
	GHAssertNotNil(nester.dictionaries, @"Dictionaries shouldn't be nil after JSON set");
	GHAssertTrue(nester.dictionaries.count == 2, @"Dictionaries should have 2 elements");
	GHAssertTrue([[nester.dictionaries objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Dictionaries obj should be of type NSDictionary");
	GHAssertEqualStrings([[nester.dictionaries objectAtIndex:0] objectForKey:@"im"], @"so", @"Dict elements should've been set");
	
	nester.dictionaries = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObject:@"obj" forKey:@"key"], [NSDictionary dictionaryWithObject:@"obj2" forKey:@"key2"], nil];
	
	NSDictionary *send = [nester dictionaryOfRemoteProperties];
	
	GHAssertNotNil(send, @"Dictionaries shouldn't be nil after trying to make it");
	GHAssertTrue([[send objectForKey:@"dictionaries_attributes"] count] == 2, @"Dictionaries should have 2 elements");
	GHAssertTrue([[[send objectForKey:@"dictionaries_attributes"] objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Dictionaries obj should be of type NSDictionary");
	GHAssertEqualStrings([[[send objectForKey:@"dictionaries_attributes"] objectAtIndex:0] objectForKey:@"key"], @"obj", @"Dict elements should've been set");
}

- (void) test_array_of_dates
{
	LadiesMan *guy = [[LadiesMan alloc] initWithRemoteJSON:[MockServer newLadiesMan]];
	GHAssertNotNil(guy.lotsOfDates, @"Dates shouldn't be nil after JSON set");
	GHAssertTrue(guy.lotsOfDates.count == 3, @"Should have 3 dates");
	GHAssertTrue([[guy.lotsOfDates objectAtIndex:0] isKindOfClass:[NSDate class]], @"Date obj should be of type NSDate");
	
	NSDictionary *send = [guy dictionaryOfRemoteProperties];
	
	GHAssertNotNil([send objectForKey:@"lots_of_dates_attributes"], @"Dates shouldn't be nil after remote dict");
	GHAssertTrue([[send objectForKey:@"lots_of_dates_attributes"] count] == 3, @"Send should have 3 dates");
	GHAssertTrue([[[send objectForKey:@"lots_of_dates_attributes"] lastObject] isKindOfClass:[NSString class]], @"Date obj should be of type NSString on send");
	GHAssertEqualStrings([[send objectForKey:@"lots_of_dates_attributes"] lastObject], @"2012-05-07T04:41:52Z", @"Converted date should be equal to original val");
}

- (void) test_set_properties
{
	PropertyTester *t = [[PropertyTester alloc] init];
	
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"test", @"property1", nil];
	
	BOOL ch = [t setPropertiesUsingRemoteDictionary:dict];
	GHAssertEqualStrings(t.property1, @"test", @"");
	GHAssertTrue(ch, @"Should've been changes first time around");
	
	BOOL ch2 = [t setPropertiesUsingRemoteDictionary:dict];
	GHAssertFalse(ch2, @"Should've been no changes when setting to no dict");
	
	t.property1 = nil;
	
	NSDictionary *dictEnveloped = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSDictionary alloc] initWithObjectsAndKeys:@"test",@"property1", nil], @"property_tester", nil];
	BOOL ch3 = [t setPropertiesUsingRemoteDictionary:dictEnveloped];
	GHAssertEqualStrings(t.property1, @"test", @"");
	GHAssertFalse(ch2, @"Should've been no changes when setting to inner dict");
	
	BOOL b;
	GHAssertNoThrow(b = [t setPropertiesUsingRemoteJSON:nil], @"Shouldn't blow up on setting to nil JSON");
	GHAssertFalse(b, @"Shouldn't be a change if nil JSON");

	BOOL b2;
	GHAssertNoThrow(b2 = [t setPropertiesUsingRemoteDictionary:nil], @"Shouldn't blow up on setting to nil dict");
	GHAssertFalse(b2, @"Shouldn't be a change if nil dict");

	GHAssertThrowsSpecificNamed([t setPropertiesUsingRemoteJSON:@"null"], NSException, NSRailsJSONParsingException, @"Should blow up on bad JSON");
	GHAssertNoThrow([t setPropertiesUsingRemoteJSON:@"{\"property_tester\":null}"], @"Shouldn't blow up, just issue a warning");
	GHAssertNoThrow([t setPropertiesUsingRemoteJSON:@"{\"property_tester\":{\"property1\":null}}"], @"Shouldn't blow up on setting to a null JSON value");
	
	GHAssertNil(t.property1, @"property1 should be nil after setting from JSON");

	GHAssertThrowsSpecificNamed([t setPropertiesUsingRemoteJSON:@"fiauj"], NSException, NSRailsJSONParsingException, @"Should blow up on bad JSON");
	t.property1 = [[NSScanner alloc] init];
	GHAssertNoThrow([t dictionaryOfRemoteProperties], @"Shouldn't blow up on making a DICT");
	GHAssertThrowsSpecificNamed([t remoteJSONRepresentation], NSException, NSRailsJSONParsingException, @"Should blow up on making bad JSON");
	GHAssertThrowsSpecificNamed([t remoteCreate:nil], NSException, NSRailsJSONParsingException, @"Should blow up on making bad JSON");
}


- (void) test_serialization
{
	NSString *file = [NSHomeDirectory() stringByAppendingPathComponent:@"test.dat"];
	
	Empty *e = [[Empty alloc] init];
	e.remoteID = [NSNumber numberWithInt:5];
	BOOL s = [NSKeyedArchiver archiveRootObject:e toFile:file];
	
	GHAssertTrue(s, @"Archiving should've worked (serialize)");
	
	Empty *eRetrieve = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
	GHAssertEqualObjects(e.remoteID, eRetrieve.remoteID, @"Should've carried over remoteID");
	

	Empty *eCustomSync = [[Empty alloc] initWithCustomSyncProperties:@"custom"];
	s = [NSKeyedArchiver archiveRootObject:eCustomSync toFile:file];
	
	GHAssertTrue(s, @"Archiving should've worked (serialize)");
	
// decoding ivars on custompropertycollection requires retaining, so ignore on mac os (ghunit doesn't support ARC)
#if TARGET_OS_IPHONE
	Empty *eCustomSyncRetrieve = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
	NSRAssertEqualArraysNoOrder(eCustomSyncRetrieve.propertyCollection.properties.allKeys, NSRArray(@"custom", @"remoteID"));

	Empty *eCustomSyncConfig = [[Empty alloc] initWithCustomSyncProperties:@"custom" customConfig:[[NSRConfig alloc] initWithAppURL:@"URL"]];
	s = [NSKeyedArchiver archiveRootObject:eCustomSyncConfig toFile:file];
	
	GHAssertTrue(s, @"Archiving should've worked (serialize)");
	
	Empty *eCustomSyncConfigRetrieve = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
	GHAssertEqualStrings(eCustomSyncConfigRetrieve.propertyCollection.customConfig.appURL, @"URL", @"Config should carry over");

	
	CustomGuy *guy = [[CustomGuy alloc] init];
	s = [NSKeyedArchiver archiveRootObject:guy toFile:file];
	
	GHAssertTrue(s, @"Archiving should've worked (serialize)");
	
	CustomGuy *guyRetrieve = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
	NSRAssertEqualArraysNoOrder(guyRetrieve.propertyCollection.properties.allKeys, NSRArray(@"something", @"remoteID"));
	GHAssertEqualStrings(guyRetrieve.propertyCollection.customConfig.appURL, @"url", @"Config should carry over");
	GHAssertEqualStrings(guyRetrieve.propertyCollection.customConfig.appUsername, @"user", @"Config should carry over");
	GHAssertEqualStrings(guyRetrieve.propertyCollection.customConfig.appPassword, @"pass", @"Config should carry over");
#endif
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