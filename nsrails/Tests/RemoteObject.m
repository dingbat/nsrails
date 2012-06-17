//
//  RemoteObject.m
//  NSRails
//
//  Created by Dan Hassin on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRAsserts.h"

@interface NSRRemoteObject (private)

+ (NSString *) typeForProperty:(NSString *)prop;

@end

@interface RemoteObject : SenTestCase
@end

@implementation RemoteObject

/*************
     UNIT
 *************/

- (void) test_introspection
{
	NSArray *props = [SubClass remoteProperties];
	
	NSRAssertEqualArraysNoOrder(props, NSRArray(@"remoteID", @"superString", @"subDate", @"anything"));
	
	
	STAssertNil([SubClass typeForProperty:@"unknown"], @"Introspection should not pick up non-existent properties");
	STAssertNil([SubClass typeForProperty:@"private"], @"Introspection should not pick up non-property ivars");
	STAssertEqualObjects([SubClass typeForProperty:@"superString"], @"@\"NSString\"", @"Introspection should pick up superclasses' props");
	STAssertEqualObjects([SubClass typeForProperty:@"subDate"], @"@\"NSDate\"", nil);
	STAssertEqualObjects([SubClass typeForProperty:@"primitiveInt"], @"i", nil);
	STAssertNil([SubClass typeForProperty:@"@\"@\""], nil);
}

- (void) test_dict_wrapping
{
	/** Generating wrap **/
	
	Post *p = [[Post alloc] init];
	p.author = @"hi";
	
	NSDictionary *sendDict = [p remoteDictionaryRepresentationWrapped:NO];
	STAssertNil([sendDict objectForKey:@"post"], @"Shouldn't include itself as a key for no wrap");
	STAssertEqualObjects([sendDict objectForKey:@"author"], @"hi", nil);
	
	NSDictionary *sendDictWrapped = [p remoteDictionaryRepresentationWrapped:YES];
	NSRAssertEqualArraysNoOrder(sendDictWrapped.allKeys, NSRArray(@"post"));
	STAssertTrue([[sendDictWrapped objectForKey:@"post"] isKindOfClass:[NSDictionary class]], @"Should include itself as a key for no wrap, and object should be a dict");
	STAssertEquals([[sendDictWrapped objectForKey:@"post"] count], [sendDict count], @"Inner dict should have same amount of keys as nowrap");
	
	
	/** Parsing wrap **/
	
	Tester *t = [[Tester alloc] init];
	STAssertNil(t.remoteAttributes, @"Shouldn't have any remoteAttributes on first init");
	
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:@"test", @"tester", nil];
	
	BOOL ch = [t setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(t.tester, @"test", @"");
	STAssertTrue(ch, @"Should've been changes first time around");
	STAssertNotNil(t.remoteAttributes, @"remoteAttributes should exist after setting props");
	
	BOOL ch2 = [t setPropertiesUsingRemoteDictionary:dict];
	STAssertFalse(ch2, @"Should've been no changes when setting to no dict");
	
	t.tester = nil;
	
	NSDictionary *dictEnveloped = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSDictionary alloc] initWithObjectsAndKeys:@"test",@"tester", nil], @"tester", nil];
	BOOL ch3 = [t setPropertiesUsingRemoteDictionary:dictEnveloped];
	STAssertEqualObjects(t.tester, @"test", @"");
	STAssertFalse(ch2, @"Should've been no changes when setting to inner dict");
}

- (void) test_dict_setting
{
	Post *p = [[Post alloc] init];
	STAssertFalse([p setPropertiesUsingRemoteDictionary:[NSDictionary dictionary]], @"should be no changes");

	for (int i = 0; i < 2; i++)
	{
		NSDictionary *dict = NSRDictionary(@"dan",@"author", @"hi",@"content", NSRNumber(10),@"id");
		
		//should be identical with wrapped dict
		if (i == 1)
			dict = [NSDictionary dictionaryWithDictionary:dict];
		
		p.author = nil; p.content = nil; p.remoteID = nil;
		
		for (int i = 0; i < 2; i++)
		{
			STAssertTrue([p setPropertiesUsingRemoteDictionary:dict], @"should be changes");
			STAssertEqualObjects(p.author, @"dan", nil);
			STAssertEqualObjects(p.content, @"hi", nil);
			STAssertEqualObjects(p.remoteID, NSRNumber(10), nil);
			
			if (i == 0)
				p.author = @"CHANGE";
		}
		
		STAssertFalse([p setPropertiesUsingRemoteDictionary:dict], @"should be no changes");
		STAssertEqualObjects(p.author, @"dan", nil);
		STAssertEqualObjects(p.content, @"hi", nil);		
	}

	/** Dates **/
	
	NSDictionary *dict = NSRDictionary([MockServer datetime],@"updated_at");

	STAssertTrue([p setPropertiesUsingRemoteDictionary:dict], @"should be changes");
	STAssertEqualObjects(p.author, @"dan", nil);
	STAssertEqualObjects(p.content, @"hi", nil);
	STAssertTrue([p.updatedAt isKindOfClass:[NSDate class]], nil);

	STAssertFalse([p setPropertiesUsingRemoteDictionary:dict], @"should be no changes");
	STAssertEqualObjects(p.author, @"dan", nil);
	STAssertEqualObjects(p.content, @"hi", nil);
	STAssertTrue([p.updatedAt isKindOfClass:[NSDate class]], nil);
	
	/** Arrays **/
	
	Tester *t = [[Tester alloc] init];
	
	NSArray *array = NSRArray(@"hello", NSRNumber(15), NSRDictionary(@"hi",@"there"), NSRArray(@"hop"));
	dict = NSRDictionary(array,@"array");
	
	STAssertTrue([t setPropertiesUsingRemoteDictionary:dict], @"should be changes");
	STAssertEqualObjects(t.array, array, nil);
	
	STAssertFalse([t setPropertiesUsingRemoteDictionary:dict], @"should be no changes");
	STAssertEqualObjects(t.array, array, nil);

	array = NSRArray(@"hello", @"CHANGE", NSRDictionary(@"hi",@"there"), NSRArray(@"hop"));
	dict = NSRDictionary(array,@"array");

	STAssertTrue([t setPropertiesUsingRemoteDictionary:dict], @"should be changes");
	STAssertEqualObjects(t.array, array, nil);

	/** Dicts **/
	
	NSDictionary *dictionary = NSRDictionary(NSRNumber(34), @"key", NSRArray(array), @"array", @"xx", @"string");
	dict = NSRDictionary(dictionary,@"dictionary");
	
	STAssertTrue([t setPropertiesUsingRemoteDictionary:dict], @"should be changes");
	STAssertEqualObjects(t.dictionary, dictionary, nil);
	
	STAssertFalse([t setPropertiesUsingRemoteDictionary:dict], @"should be no changes");
	STAssertEqualObjects(t.dictionary, dictionary, nil);
	
	dictionary = NSRDictionary(NSRNumber(34), @"key", NSRArray(array), @"array", @"xx", @"CHANGE");
	dict = NSRDictionary(dictionary,@"dictionary");

	STAssertTrue([t setPropertiesUsingRemoteDictionary:dict], @"should be changes");
	STAssertEqualObjects(t.dictionary, dictionary, nil);

	/** Nulls and stuff **/
		
	BOOL b;
	STAssertNoThrow(b = [t setPropertiesUsingRemoteDictionary:nil], @"Shouldn't blow up on setting to nil dictionary");
	STAssertFalse(b, @"Shouldn't be a change if nil JSON");
	
	[t setPropertiesUsingRemoteDictionary:NSRDictionary([NSNull null], @"tester")];
	STAssertNil(t.tester, @"tester should be nil after setting from JSON");
	
	[t setPropertiesUsingRemoteDictionary:NSRDictionary(NSRDictionary([NSNull null], @"tester"), @"tester")];
	STAssertNil(t.tester, @"tester should be nil after setting from JSON");
	
	t.tester = (id)[[NSScanner alloc] init];
	STAssertThrows([t remoteDictionaryRepresentationWrapped:NO], @"Should blow up on making a dict with scanner");
	STAssertThrows([t remoteCreate:nil], @"Should blow up on making bad JSON");	
	
	
	//TODO
	//For each one, test if the specific elements are of right type? ([dict objectForKey:@"array"] isKindOfClass:array)
}

- (void) test_date_diff_detection
{
	//single NSDate
	SubClass *p = [[SubClass alloc] init];
	p.subDate = [NSDate date];
	
	NSDictionary *manDict = [p remoteDictionaryRepresentationWrapped:NO];
	
	p.subDate = [p.subDate dateByAddingTimeInterval:0.1];
	
	BOOL changes = [p setPropertiesUsingRemoteDictionary:manDict];
	STAssertFalse(changes, @"Should be no changes - too minute");
	
	p.subDate = [p.subDate dateByAddingTimeInterval:1.5];
	
	changes = [p setPropertiesUsingRemoteDictionary:manDict];
	STAssertTrue(changes, @"Should be changes - modified significantly");
}


- (void) test_serialization
{
	NSString *file = [NSHomeDirectory() stringByAppendingPathComponent:@"test.dat"];
	
	Tester *e = [[Tester alloc] init];
	e.remoteID = [NSNumber numberWithInt:5];
	BOOL s = [NSKeyedArchiver archiveRootObject:e toFile:file];
	
	STAssertTrue(s, @"Archiving should've worked (serialize)");
	
	Tester *eRetrieve = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
	STAssertEqualObjects(e.remoteID, eRetrieve.remoteID, @"Should've carried over remoteID");	
}


/*************
   OVERRIDES
 *************/

- (void) test_encode_decode
{
	CustomCoder *p = [CustomCoder objectWithRemoteDictionary:[MockServer newCustomCoder]];
	
	STAssertTrue([p.csvArray isKindOfClass:[NSArray class]], @"Should've decoded into an array");
	STAssertTrue([p.locallyURL isKindOfClass:[NSURL class]], @"Should've decoded into a URL");
	STAssertTrue([p.dateOverrideSend isKindOfClass:[NSDate class]], @"Should've decoded into an NSDate");
	STAssertTrue([p.dateOverrideRet isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]], @"Should've used custom decode");
	STAssertNil(p.codeToNil, @"Should've decoded codeToNil into nil");
	STAssertEqualObjects([p.locallyURL description], @"http://nsrails.com", @"Should've decoded into URL & retain content");
	STAssertEqualObjects(p.csvArray, NSRArray(@"one", @"two", @"three"), @"Should've decoded into an array & retain content");
	STAssertEqualObjects(p.locallyLowercase, @"lowercase?", @"Should've decoded into lowercase");
	STAssertEqualObjects(p.remotelyUppercase, @"upper", @"Should've kept the same");
	STAssertEqualObjects(p.componentWithFlippingName.componentName, @"comp lowercase?", @"Should've decoded comp name into lowercase");
	
	p.codeToNil = @"Something";
	
	NSDictionary *sendDict = [p remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[sendDict objectForKey:@"csv_array"] isKindOfClass:[NSString class]],@"Should've encoded NSArray -> string");
	STAssertTrue([[sendDict objectForKey:@"locally_url"] isKindOfClass:[NSString class]],@"Should've encoded NSURL -> string");
	STAssertTrue([[sendDict objectForKey:@"code_to_nil"] isKindOfClass:[NSNull class]], @"Should be nsnull");
	STAssertEqualObjects([sendDict objectForKey:@"csv_array"], @"one,two,three", @"Should've encoded into string & retain content");
	STAssertEqualObjects([sendDict objectForKey:@"locally_url"], @"http://nsrails.com", @"Should've encoded into string & retain content");
	STAssertEqualObjects([sendDict objectForKey:@"locally_lowercase"], @"lowercase?", @"Should've kept as lowercase");
	STAssertEqualObjects([sendDict objectForKey:@"remotely_uppercase"], @"UPPER", @"Should've encoded to uppercase");
	STAssertEqualObjects([sendDict objectForKey:@"date_override_send"], @"override!", @"Should've overriden NSDate encode");
	STAssertEqualObjects([sendDict objectForKey:@"date_override_ret"], @"1969-12-31T19:00:00Z", @"Should've overriden NSDate decode");
	STAssertEqualObjects(p.componentWithFlippingName.componentName, @"COMP LOWERCASE?", @"Should've encoded comp name into uppercase");
	
	STAssertEqualObjects([sendDict objectForKey:@"remote_only"], @"remote", @"Should've captured remoteOnly!");
	
	p.encodeNonJSON = YES;
	
	STAssertThrowsSpecificNamed([p remoteDictionaryRepresentationWrapped:NO], NSException, NSRJSONParsingException, @"Encoding into non-JSON for sendable dict - where's the error?");
}

- (void) test_send_retrieve
{
	CustomSender *p = [[CustomSender alloc] init];
	p.local = @"local";
	p.sendOnly = @"send--local";
	p.undefined = @"local";
	[p setPropertiesUsingRemoteDictionary:[MockServer newCustomSender]];
	
	STAssertEqualObjects(p.local, @"local", @"Should've kept local... -x");
	STAssertEqualObjects(p.sendOnly, @"send--local", @"Should've kept send... -s");
	STAssertEqualObjects(p.retrieveOnly, @"retrieve", @"Should've set retrieve... -r");
	STAssertEqualObjects(p.shared, @"shared", @"Should've set shared... blank");
	STAssertEqualObjects(p.sharedExplicit, @"shared explicit", @"Should've set sharedExplicit... -rs");
	STAssertEqualObjects(p.undefined, @"local", @"Shouldn't have set undefined... not in NSRMap");
	
	NSDictionary *sendDict = [p remoteDictionaryRepresentationWrapped:NO];
	STAssertNil([sendDict objectForKey:@"retrieve_only"], @"Shouldn't send retrieve-only... -r");
	STAssertNil([sendDict objectForKey:@"local"], @"Shouldn't send local-only... -x");
	STAssertNil([sendDict objectForKey:@"undefined"], @"Shouldn't send undefined... not in NSRMap");
	STAssertEqualObjects([sendDict objectForKey:@"send_only"], @"send--local", @"Should've sent send... -s");
	STAssertEqualObjects([sendDict objectForKey:@"shared"], @"shared", @"Should've sent shared... blank");
	STAssertEqualObjects([sendDict objectForKey:@"shared_explicit"], @"shared explicit", @"Should've sent sharedExplicit... -rs");
}

/***************
    NESTING
 **************/

- (void) test_destroy_on_nesting
{
	Bird *bird = [[Bird alloc] init];
	
	NSDictionary *dict = [bird remoteDictionaryRepresentationWrapped:NO];
	STAssertNil([dict objectForKey:@"_destroy"],@"No _destroy key if no remoteDestroyOnNesting");
	
	bird.remoteDestroyOnNesting = YES;
	
	dict = [bird remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[dict objectForKey:@"_destroy"] boolValue],@"remoteDestroyOnNesting should add _destroy key");
	
	Egg *e = [[Egg alloc] init];
	e.remoteDestroyOnNesting = YES;
	
	bird.eggs = [[NSMutableArray alloc] initWithObjects:e, nil];
	
	bird.remoteDestroyOnNesting = NO;
	dict = [bird remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil([dict objectForKey:@"_destroy"],@"No _destroy key if no remoteDestroyOnNesting");
	STAssertTrue([[dict objectForKey:@"eggs_attributes"] isKindOfClass:[NSArray class]],@"Eggs should exist & be an array");
	STAssertTrue([[[[dict objectForKey:@"eggs_attributes"] lastObject] objectForKey:@"_destroy"] boolValue],@"_destroy key should exist on egg if remoteDestroyOnNesting");	
}

/** Has-many **/

- (void) test_has_many
{
	Bird *nn = [[Bird alloc] init];
	
	NSMutableDictionary *sendDict = (NSMutableDictionary *)[nn remoteDictionaryRepresentationWrapped:NO];

	STAssertNil([sendDict objectForKey:@"eggs"], nil);
	STAssertNil([sendDict objectForKey:@"eggs_attributes"], nil);
	
	nn.eggs = [[NSMutableArray alloc] init];
	
	sendDict = (NSMutableDictionary *)[nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil([sendDict objectForKey:@"eggs"], nil);
	STAssertNil([sendDict objectForKey:@"eggs_attributes"], nil);

	[nn.eggs addObject:[[Egg alloc] init]];
		
	sendDict = (NSMutableDictionary *)[nn remoteDictionaryRepresentationWrapped:NO];
	STAssertNil([sendDict objectForKey:@"eggs"], nil);
	STAssertTrue([[[sendDict objectForKey:@"eggs_attributes"] lastObject] isKindOfClass:[NSDictionary class]], nil);
	
	////
	////
	
	nn.eggs = nil;
	
	sendDict = (NSMutableDictionary *)[nn remoteDictionaryRepresentationWrapped:NO];
	STAssertNil([sendDict objectForKey:@"eggs_attributes"], @"'array' key shouldn't exist if empty");
	STAssertNil([sendDict objectForKey:@"eggs"], @"'array' key shouldn't exist if empty");
	
	nn.eggs = [[NSMutableArray alloc] initWithObjects:[[Egg alloc] init], nil];
	
	sendDict = (NSMutableDictionary *)[nn remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[[sendDict objectForKey:@"eggs_attributes"] lastObject] isKindOfClass:[NSDictionary class]], @"'array' key should exist & be a dict (egg representation)");
	STAssertTrue([[sendDict objectForKey:@"eggs_attributes"] count] == 1, @"'array' key should have one element");
	
	//right now it's array_attributes - change to just "array" as if it was coming from rails
	[sendDict setObject:[sendDict objectForKey:@"eggs_attributes"] forKey:@"eggs"];
	[sendDict removeObjectForKey:@"eggs_attributes"];
	
	BOOL changes = [nn setPropertiesUsingRemoteDictionary:sendDict];
	STAssertTrue(changes, @"Should be changes - egg never had an ID so it doesn't know to persist");
	STAssertNotNil(nn.eggs, @"Array shouldn't be nil");
	STAssertTrue([nn.eggs isKindOfClass:[NSArray class]], @"plain.array should be set to array");
	STAssertTrue(nn.eggs.count == 1, @"plain.array should have one element");
	STAssertTrue([[nn.eggs lastObject] isKindOfClass:[Egg class]], @"plain.array should be filled w/Egg");
	
	[[nn.eggs lastObject] setRemoteID:[NSNumber numberWithInt:5]];
	sendDict = (NSMutableDictionary *)[nn remoteDictionaryRepresentationWrapped:NO];
	
	//right now it's array_attributes - change to just "array" as if it was coming from rails
	[sendDict setObject:[sendDict objectForKey:@"eggs_attributes"] forKey:@"eggs"];
	[sendDict removeObjectForKey:@"eggs_attributes"];
	
	changes = [nn setPropertiesUsingRemoteDictionary:sendDict];
	STAssertFalse(changes, @"Should be no changes - should've detected same egg ID");
}

/** Belongs-to **/

- (void) test_belongs_to
{
	Egg *nn = [[Egg alloc] init];
	
	NSDictionary *sendDict = [nn remoteDictionaryRepresentationWrapped:NO];

	STAssertNil([sendDict objectForKey:@"bird"], nil);
	STAssertTrue([[sendDict objectForKey:@"bird_id"] isKindOfClass:[NSNull class]], nil);
	
	nn.bird = [[Bird alloc] init];
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil([sendDict objectForKey:@"bird"], nil);
	STAssertTrue([[sendDict objectForKey:@"bird_id"] isKindOfClass:[NSNull class]], nil);
	
	nn.bird.remoteID = NSRNumber(15);
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];

	STAssertNil([sendDict objectForKey:@"bird"], nil);
	STAssertEqualObjects([sendDict objectForKey:@"bird_id"], NSRNumber(15), nil);
}

/** Has-one **/

- (void) test_has_one
{
	Egg *nn = [[Egg alloc] init];
	
	NSDictionary *sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil([sendDict objectForKey:@"nest"], nil);
	STAssertNil([sendDict objectForKey:@"nest_attributes"], nil);
	
	nn.nest = [[Nest alloc] init];
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil([sendDict objectForKey:@"nest"], nil);
	STAssertTrue([[sendDict objectForKey:@"nest_attributes"] isKindOfClass:[NSDictionary class]], nil);
	
	nn.nest.remoteID = NSRNumber(20);
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil([sendDict objectForKey:@"nest"], nil);
	STAssertEqualObjects([[sendDict objectForKey:@"nest_attributes"] objectForKey:@"id"], NSRNumber(20), nil);
}

- (void) test_nesting_dictionaries
{
	DictionaryNester *plainNester = [DictionaryNester objectWithRemoteDictionary:[MockServer newDictionaryNester]];
	STAssertNotNil(plainNester.dictionaries, @"Dictionaries shouldn't be nil after JSON set");
	STAssertTrue(plainNester.dictionaries.count == 2, @"Dictionaries should have 2 elements");
	STAssertTrue([[plainNester.dictionaries objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Dictionaries obj should be of type NSDictionary");
	STAssertEqualObjects([[plainNester.dictionaries objectAtIndex:0] objectForKey:@"so"], @"im", @"Dict elements should've been set");
	
	plainNester.dictionaries = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObject:@"obj" forKey:@"key"], [NSDictionary dictionaryWithObject:@"obj2" forKey:@"key2"], nil];
	
	NSDictionary *send = [plainNester remoteDictionaryRepresentationWrapped:NO];
	STAssertNotNil(send, @"Dictionaries shouldn't be nil after trying to make it");
	STAssertTrue([[send objectForKey:@"dictionaries"] count] == 2, @"Dictionaries should have 2 elements");
	STAssertTrue([[[send objectForKey:@"dictionaries"] objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Dictionaries obj should be of type NSDictionary");
	STAssertEqualObjects([[[send objectForKey:@"dictionaries"] objectAtIndex:0] objectForKey:@"key"], @"obj", @"Dict elements should've been set");
}

- (void) test_recursive_nesting
{
	/*
	 Many-to-many
	 */
	
	NSString *BooksKey = @"books_attributes";
	NSString *OwnersKey = @"owners_attributes";
	
	Person *guy = [[Person alloc] init];
	guy.books = [[NSMutableArray alloc] init];
	
	Book *book = [[Book alloc] init];
	book.owners = [[NSMutableArray alloc] init];
	
	[book.owners addObject:guy];
	[guy.books addObject:book];
	
	NSDictionary *pDict = [guy remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[pDict objectForKey:BooksKey] isKindOfClass:[NSArray class]], @"Books should be an array");
	STAssertTrue([[[pDict objectForKey:BooksKey] lastObject] isKindOfClass:[NSDictionary class]], @"Book should be a dict");
	STAssertNil([[[pDict objectForKey:BooksKey] lastObject] objectForKey:OwnersKey], @"Shouldn't include books's owners since it's not included in nesting");
	
	
	NSDictionary *bDict = [book remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[bDict objectForKey:OwnersKey] isKindOfClass:[NSArray class]], @"Owners should be an array");
	STAssertTrue([[[bDict objectForKey:OwnersKey] lastObject] isKindOfClass:[NSDictionary class]], @"Owner (person) should be a dict");
	STAssertNil([[[bDict objectForKey:OwnersKey] lastObject] objectForKey:BooksKey], @"Shouldn't include owner's books since it's not included in nesting");
	
	
	Book *book2 = [[Book alloc] init];
	book2.owners = [[NSMutableArray alloc] init];
	book2.nestPerson = YES;
	[book2.owners addObject:guy];
	
	[guy.books removeAllObjects];
	[guy.books addObject:book2];
	
	pDict = [guy remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[pDict objectForKey:BooksKey] isKindOfClass:[NSArray class]], @"Books should be an array");
	STAssertTrue([[[pDict objectForKey:BooksKey] lastObject] isKindOfClass:[NSDictionary class]], @"Book should be a dict");
	STAssertTrue([[[[pDict objectForKey:BooksKey] lastObject] objectForKey:OwnersKey] isKindOfClass:[NSArray class]], @"Book should include owners and it should be an array");
	STAssertTrue([[[[[pDict objectForKey:BooksKey] lastObject] objectForKey:OwnersKey] lastObject] isKindOfClass:[NSDictionary class]], @"Owner in owner's book's owners should be a dictionary");
	
	
	/*
	 One-to-many
	 */
	
	NSString *EggsKey = @"eggs_attributes";
	NSString *MotherKey = @"bird_attributes";
	
	Bird *b = [[Bird alloc] init];
	b.eggs = [[NSMutableArray alloc] init];
	
	Egg *e = [[Egg alloc] init];
	e.hasOneBird = YES;
	[b.eggs addObject:e];
	
	NSDictionary *birdDict = [b remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[birdDict objectForKey:EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[[birdDict objectForKey:EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertNil([[[birdDict objectForKey:EggsKey] lastObject] objectForKey:MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
	
	e.bird = b;
	
	birdDict = [b remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[birdDict objectForKey:EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[[birdDict objectForKey:EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertNil([[[birdDict objectForKey:EggsKey] lastObject] objectForKey:MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
	
	NSDictionary *eggDict = [e remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[eggDict objectForKey:MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
	STAssertNil([[eggDict objectForKey:MotherKey] objectForKey:EggsKey],@"Mother should not include eggs (since no -n)");
	
	[b.eggs removeAllObjects];
	
	Egg *motherExposingEgg = [[Egg alloc] init];
	motherExposingEgg.nestBird = YES;
	motherExposingEgg.bird = b;
	motherExposingEgg.hasOneBird = YES;
	
	[b.eggs addObject:motherExposingEgg];
	
	birdDict = [b remoteDictionaryRepresentationWrapped:NO];

	STAssertTrue([[birdDict objectForKey:EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[[birdDict objectForKey:EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertTrue([[[[birdDict objectForKey:EggsKey] lastObject] objectForKey:MotherKey] isKindOfClass:[NSDictionary class]], @"Egg's mother should be a dict, since it was included in -n");
	STAssertNil([[[[birdDict objectForKey:EggsKey] lastObject] objectForKey:MotherKey] objectForKey:EggsKey], @"Egg's mother's eggs shouldn't be included, since mother doesn't define -n on eggs");
	
	eggDict = [motherExposingEgg remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[eggDict objectForKey:MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
	STAssertNil([[eggDict objectForKey:MotherKey] objectForKey:EggsKey],@"Mother should not include eggs (since no -n)");
	
	
	Bird *nesterBird = [[Bird alloc] init];
	nesterBird.eggs = [[NSMutableArray alloc] init];
	nesterBird.remoteID = [NSNumber numberWithInt:1];
	nesterBird.nestEggs = YES;
	
	Egg *e2 = [[Egg alloc] init];
	e2.bird = nesterBird;
	e2.hasOneBird = YES;
	[nesterBird.eggs addObject:e2];
	
	birdDict = [nesterBird remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[birdDict objectForKey:EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[[birdDict objectForKey:EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertNil([[[birdDict objectForKey:EggsKey] lastObject] objectForKey:MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
	
	eggDict = [e2 remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[eggDict objectForKey:MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
	STAssertTrue([[[eggDict objectForKey:MotherKey] objectForKey:EggsKey] isKindOfClass:[NSArray class]],@"Should include eggs in mother because of the -n (and should be array)");
	STAssertTrue([[[[eggDict objectForKey:MotherKey] objectForKey:EggsKey] lastObject] isKindOfClass:[NSDictionary class]],@"Should include an egg (as a dict) in mother's eggs");
	STAssertNil([[[[eggDict objectForKey:MotherKey] objectForKey:EggsKey] lastObject] objectForKey:MotherKey], @"Egg's mother's egg should not have a mother (since no -n)");
	
	e2.bird = nil;
	eggDict = [e2 remoteDictionaryRepresentationWrapped:NO];
	STAssertNil([eggDict objectForKey:MotherKey],@"Shouldn't send the mother if nil + associated");
	
	[nesterBird.eggs removeAllObjects];
	
	//"belongs-to"
	Egg *attachedEgg = [[Egg alloc] init];
	attachedEgg.bird = nesterBird;
	[nesterBird.eggs addObject:attachedEgg];
	
	birdDict = [nesterBird remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[birdDict objectForKey:EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[[birdDict objectForKey:EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertNil([[[birdDict objectForKey:EggsKey] lastObject] objectForKey:MotherKey], @"Shouldn't have 'mother' -- 'mother_id' since b-t");
	STAssertTrue([[[[birdDict objectForKey:EggsKey] lastObject] objectForKey:@"bird_id"] isKindOfClass:[NSNumber class]], @"Egg's mother (self)'s id should be present & be a number");
	
	//should be fine here because even though eggs is marked for nesting, mother is belongs-to, so no recursion should occur
	eggDict = [attachedEgg remoteDictionaryRepresentationWrapped:NO];
	STAssertNil([eggDict objectForKey:MotherKey], @"'mother' key shouldn't exist - belongs-to, so should be bird_id");
	STAssertTrue([[eggDict objectForKey:@"bird_id"] isKindOfClass:[NSNumber class]], @"mother ID should be exist and be a number");
	
	attachedEgg.bird = nil;
	eggDict = [attachedEgg remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNotNil([eggDict objectForKey:@"bird_id"], @"'mother_id' key should exist - belongs-to but NULL");
	STAssertTrue([[eggDict objectForKey:@"bird_id"] isKindOfClass:[NSNull class]], @"bird_id should be exist but be null");
}


@end
