//
//  RemoteObject.m
//  NSRails
//
//  Created by Dan Hassin on 6/11/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
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
	NSArray *props = [[[SubClass alloc] init] remoteProperties];
	NSArray *a = @[@"remoteID", @"superString", @"subDate", @"anything"];
    
	NSRAssertEqualArraysNoOrder(props, a);
	
	
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
	STAssertNil(sendDict[@"post"], @"Shouldn't include itself as a key for no wrap");
	STAssertEqualObjects(sendDict[@"author"], @"hi", nil);
	
	NSDictionary *sendDictWrapped = [p remoteDictionaryRepresentationWrapped:YES];
	NSRAssertEqualArraysNoOrder(sendDictWrapped.allKeys, @[@"post"]);
	STAssertTrue([sendDictWrapped[@"post"] isKindOfClass:[NSDictionary class]], @"Should include itself as a key for no wrap, and object should be a dict");
	STAssertEquals([sendDictWrapped[@"post"] count], [sendDict count], @"Inner dict should have same amount of keys as nowrap");
	
	
	/** Parsing wrap **/
	
	Tester *t = [[Tester alloc] init];
	STAssertNil(t.remoteAttributes, @"Shouldn't have any remoteAttributes on first init");
	
	NSDictionary *dict = @{@"tester": @"test"};
	
	[t setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(t.tester, @"test", @"");
	STAssertNotNil(t.remoteAttributes, @"remoteAttributes should exist after setting props");
	
	[t setPropertiesUsingRemoteDictionary:dict];
	
	t.tester = nil;
	
	NSDictionary *dictEnveloped = @{@"tester": @{@"tester": @"test"}};
	[t setPropertiesUsingRemoteDictionary:dictEnveloped];
	STAssertEqualObjects(t.tester, @"test", @"");
}

- (void) test_dict_setting
{
	Post *p = [[Post alloc] init];
	[p setPropertiesUsingRemoteDictionary:@{}];
	
	for (int i = 0; i < 2; i++)
	{
		NSDictionary *dict = @{@"author":@"dan", @"content":@"hi", @"id":@10};
		
		//should be identical with wrapped dict
		if (i == 1) {
			dict = @{@"post":dict};
		}
		
		p.author = nil; p.content = nil; p.remoteID = nil;
		
		for (int i = 0; i < 2; i++)
		{
			[p setPropertiesUsingRemoteDictionary:dict];
			STAssertEqualObjects(p.author, @"dan", nil);
			STAssertEqualObjects(p.content, @"hi", nil);
			STAssertEqualObjects(p.remoteID, @(10), nil);
			
			if (i == 0) {
				p.author = @"CHANGE";
			}
		}
		
		[p setPropertiesUsingRemoteDictionary:dict];
		STAssertEqualObjects(p.author, @"dan", nil);
		STAssertEqualObjects(p.content, @"hi", nil);		
	}

	/** Dates **/
	
	NSDictionary *dict = @{@"updated_at":[MockServer datetime]};

	[p setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(p.author, @"dan", nil);
	STAssertEqualObjects(p.content, @"hi", nil);
	STAssertTrue([p.updatedAt isKindOfClass:[NSDate class]], nil);

	[p setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(p.author, @"dan", nil);
	STAssertEqualObjects(p.content, @"hi", nil);
	STAssertTrue([p.updatedAt isKindOfClass:[NSDate class]], nil);
	
	/** Arrays **/
	
	Tester *t = [[Tester alloc] init];
	
	NSArray *array = @[@"hello", @15, @{@"there":@"hi"}, @[@"hop"]];
	dict = @{@"array":array};
	
	[t setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(t.array, array, nil);
	
	[t setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(t.array, array, nil);

	array = @[@"hello", @"CHANGE", @{@"there":@"hi"}, @[@"hop"]];
	dict = @{@"array":array};

	[t setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(t.array, array, nil);

	/** Dicts **/
	
	NSDictionary *dictionary = @{@"key":@34, @"array":@[array], @"string":@"xx"};
	dict = @{@"dictionary":dictionary};
	
	[t setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(t.dictionary, dictionary, nil);
	
	[t setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(t.dictionary, dictionary, nil);
	
	[t setPropertiesUsingRemoteDictionary:dict];
	dict = @{@"dictionary":dictionary};

	[t setPropertiesUsingRemoteDictionary:dict];
	STAssertEqualObjects(t.dictionary, dictionary, nil);

	/** Nulls and stuff **/
		
	STAssertNoThrow([t setPropertiesUsingRemoteDictionary:nil], @"Shouldn't blow up on setting to nil dictionary");
	
	[t setPropertiesUsingRemoteDictionary:@{@"tester":[NSNull null]}];
	STAssertNil(t.tester, @"tester should be nil after setting from JSON");
	
	[t setPropertiesUsingRemoteDictionary:@{@"tester":@{@"tester":[NSNull null]}}];
	STAssertNil(t.tester, @"tester should be nil after setting from JSON");
	
	t.tester = (id)[[NSScanner alloc] init];
	STAssertThrows([t remoteDictionaryRepresentationWrapped:NO], @"Should blow up on making a dict with scanner");
	STAssertThrows([t remoteCreate:nil], @"Should blow up on making bad JSON");	
	
	
	//TODO
	//For each one, test if the specific elements are of right type? ([dict objectForKey:@"array"] isKindOfClass:array)
}

- (void) test_serialization
{
	NSString *file = [NSHomeDirectory() stringByAppendingPathComponent:@"test.dat"];
	
	Tester *e = [[Tester alloc] init];
	e.remoteID = @5;
	BOOL s = [NSKeyedArchiver archiveRootObject:e toFile:file];
	
	STAssertTrue(s, @"Archiving should've worked (serialize)");
	
	Tester *eRetrieve = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
	STAssertEqualObjects(e.remoteID, eRetrieve.remoteID, @"Should've carried over remoteID");	
}

- (void) test_index_json_into_array
{
	id remoteJSON = @[@{@"author":@"dan"}, @{@"author":@"michael"}];
	NSArray *array = [Post objectsWithRemoteDictionaries:remoteJSON];
	
	STAssertNotNil(array, nil);
	STAssertEquals(array.count, [remoteJSON count], nil);
	STAssertTrue([array[0] isKindOfClass:[Post class]], nil);
	STAssertEqualObjects([array[0] author], @"dan", nil);
}

- (void) test_index_json_into_array_with_root
{
	id remoteJSON = @{@"posts":@[@{@"author":@"dan"}, @{@"author":@"michael"}]};
	NSArray *array = [Post objectsWithRemoteDictionaries:remoteJSON];
	
	STAssertNotNil(array, nil);
	STAssertEquals(array.count, (NSUInteger)2, nil);
	STAssertTrue([array[0] isKindOfClass:[Post class]], nil);
	STAssertEqualObjects([array[0] author], @"dan", nil);
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
	STAssertTrue([p.dateOverrideRet isEqualToDate:[p customDate]], @"Should've used custom decode");
	STAssertNil(p.codeToNil, @"Should've decoded codeToNil into nil");
	STAssertEqualObjects([p.locallyURL description], @"http://nsrails.com", @"Should've decoded into URL & retain content");
    NSArray *a = @[@"one", @"two", @"three"];
	STAssertEqualObjects(p.csvArray, a, @"Should've decoded into an array & retain content");
	STAssertEqualObjects(p.locallyLowercase, @"lowercase?", @"Should've decoded into lowercase");
	STAssertEqualObjects(p.remotelyUppercase, @"upper", @"Should've kept the same");
	STAssertEqualObjects(p.componentWithFlippingName.componentName, @"comp lowercase?", @"Should've decoded comp name into lowercase");
	STAssertEqualObjects(p.objc, @"renamed", @"Should've renamed from 'rails'");
	
	p.codeToNil = @"Something";
	
	NSDictionary *sendDict = [p remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([sendDict[@"csv_array"] isKindOfClass:[NSString class]],@"Should've encoded NSArray -> string");
	STAssertTrue([sendDict[@"locally_url"] isKindOfClass:[NSString class]],@"Should've encoded NSURL -> string");
	STAssertTrue([sendDict[@"code_to_nil"] isKindOfClass:[NSNull class]], @"Should be nsnull");
	STAssertEqualObjects(sendDict[@"csv_array"], @"one,two,three", @"Should've encoded into string & retain content");
	STAssertEqualObjects(sendDict[@"locally_url"], @"http://nsrails.com", @"Should've encoded into string & retain content");
	STAssertEqualObjects(sendDict[@"locally_lowercase"], @"lowercase?", @"Should've kept as lowercase");
	STAssertEqualObjects(sendDict[@"remotely_uppercase"], @"UPPER", @"Should've encoded to uppercase");
	STAssertEqualObjects(sendDict[@"date_override_send"], @"override!", @"Should've overriden NSDate encode");
	NSString *dateStr = [[NSRConfig defaultConfig] stringFromDate:[p customDate]];
	STAssertEqualObjects(sendDict[@"date_override_ret"], dateStr, @"Should've overriden NSDate decode");
	STAssertEqualObjects(p.componentWithFlippingName.componentName, @"COMP LOWERCASE?", @"Should've encoded comp name into uppercase");
	
	STAssertEqualObjects(sendDict[@"remote_only"], @"remote", @"Should've captured remoteOnly!");
	STAssertEqualObjects(sendDict[@"objc"], @"renamed", @"Should've kept objc because was not set");
	
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
	STAssertEqualObjects(p.undefined, @"local", @"Shouldn't have set undefined...");
	
	NSDictionary *sendDict = [p remoteDictionaryRepresentationWrapped:NO];
	STAssertNil(sendDict[@"retrieve_only"], @"Shouldn't send retrieve-only... -r");
	STAssertNil(sendDict[@"local"], @"Shouldn't send local-only... -x");
	STAssertNil(sendDict[@"undefined"], @"Shouldn't send undefined...");
	STAssertEqualObjects(sendDict[@"send_only"], @"send--local", @"Should've sent send... -s");
	STAssertEqualObjects(sendDict[@"shared"], @"shared", @"Should've sent shared... blank");
	STAssertEqualObjects(sendDict[@"shared_explicit"], @"shared explicit", @"Should've sent sharedExplicit... -rs");
}

/***************
    NESTING
 **************/

- (void) test_destroy_on_nesting
{
	Bird *bird = [[Bird alloc] init];
	
	NSDictionary *dict = [bird remoteDictionaryRepresentationWrapped:NO];
	STAssertNil(dict[@"_destroy"],@"No _destroy key if no remoteDestroyOnNesting");
	
	bird.remoteDestroyOnNesting = YES;
	
	dict = [bird remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([dict[@"_destroy"] boolValue],@"remoteDestroyOnNesting should add _destroy key");
	
	Egg *e = [[Egg alloc] init];
	e.remoteDestroyOnNesting = YES;
	
	bird.eggs = [[NSMutableArray alloc] initWithObjects:e, nil];
	
	bird.remoteDestroyOnNesting = NO;
	dict = [bird remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil(dict[@"_destroy"],@"No _destroy key if no remoteDestroyOnNesting");
	STAssertTrue([dict[@"eggs_attributes"] isKindOfClass:[NSArray class]],@"Eggs should exist & be an array");
	STAssertTrue([[dict[@"eggs_attributes"] lastObject][@"_destroy"] boolValue],@"_destroy key should exist on egg if remoteDestroyOnNesting");	
}

/** Has-many **/

- (void) test_has_many
{
	Bird *nn = [[Bird alloc] init];
	
	NSDictionary *sendDict = [nn remoteDictionaryRepresentationWrapped:NO];

	STAssertNil(sendDict[@"eggs"], nil);
	STAssertNil(sendDict[@"eggs_attributes"], nil);
	
	nn.eggs = [[NSMutableArray alloc] init];
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil(sendDict[@"eggs"], nil);
	STAssertNil(sendDict[@"eggs_attributes"], nil);

    Egg *egg = [[Egg alloc] init];
    egg.remoteID = @999;
	[nn.eggs addObject:egg];
		
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	STAssertNil(sendDict[@"eggs"], nil);
	STAssertTrue([[sendDict[@"eggs_attributes"] lastObject] isKindOfClass:[NSDictionary class]], nil);
	
	////
	////
	
	nn.eggs = nil;
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	STAssertNil(sendDict[@"eggs_attributes"], @"'array' key shouldn't exist if empty");
	STAssertNil(sendDict[@"eggs"], @"'array' key shouldn't exist if empty");
	
	nn.eggs = [[NSMutableArray alloc] initWithObjects:egg, nil];
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([[sendDict[@"eggs_attributes"] lastObject] isKindOfClass:[NSDictionary class]], @"'array' key should exist & be a dict (egg representation)");
	STAssertTrue([sendDict[@"eggs_attributes"] count] == 1, @"'array' key should have one element");
	
    NSMutableDictionary *inDict = [NSMutableDictionary dictionaryWithDictionary:sendDict];
    
	//right now it's array_attributes - change to just "array" as if it was coming from rails
	inDict[@"eggs"] = inDict[@"eggs_attributes"];
	[inDict removeObjectForKey:@"eggs_attributes"];
	
	[nn setPropertiesUsingRemoteDictionary:inDict];
	STAssertNotNil(nn.eggs, @"Array shouldn't be nil");
	STAssertTrue([nn.eggs isKindOfClass:[NSArray class]], @"plain.array should be set to array");
	STAssertTrue(nn.eggs.count == 1, @"plain.array should have one element");
	STAssertTrue([[nn.eggs lastObject] isKindOfClass:[Egg class]], @"plain.array should be filled w/Egg");
    
    //"wrap" an element of the has-many
    inDict[@"eggs"] = @[@{@"egg":inDict[@"eggs"][0]}];
	[nn setPropertiesUsingRemoteDictionary:inDict];
	STAssertTrue(nn.eggs.count == 1, @"plain.array should have one element");
	STAssertTrue(nn.eggs[0] == egg, @"should be the same egg");
}

- (void) test_nondestructive_hasmany
{
    Bird *bird = [[Bird alloc] init];
    
    Egg *e1 = [[Egg alloc] init];
    e1.remoteID = @1;
    Egg *e2 = [[Egg alloc] init];
    e2.remoteID = @2;
    
    bird.eggs = [NSMutableArray arrayWithArray:@[e1,e2]];
    
    NSDictionary *railsDict = @{@"eggs":@[@{@"id":@3}]};
    [bird setPropertiesUsingRemoteDictionary:railsDict];
    STAssertTrue(bird.eggs.count == 1, @"Should be destructive");
    STAssertTrue([bird.eggs[0] remoteID].intValue == 3, @"Should be the third egg");
    
    bird.nondestructiveEggs = YES;
    
    railsDict = @{@"eggs":@[@{@"id":@4}]};
    [bird setPropertiesUsingRemoteDictionary:railsDict];
    STAssertTrue(bird.eggs.count == 2, @"Should be additive");
    STAssertTrue([[bird.eggs lastObject] remoteID].intValue == 4, @"Should be the fourth egg");
    
    [bird setPropertiesUsingRemoteDictionary:railsDict];
    STAssertTrue(bird.eggs.count == 2, @"Should be additive, but unique");
    STAssertTrue([[bird.eggs lastObject] remoteID].intValue == 4, @"Should be the fourth egg");
}

/** Multiple belongs-to (array of ID's) **/

- (void) test_array_ids_only
{
    Response *r1 = [[Response alloc] init];
    r1.remoteID = @1;
    
    Response *r2 = [[Response alloc] init];
    r2.remoteID = @2;
    
    Post *post = [[Post alloc] init];
    post.onlyIDResponses = [NSMutableArray arrayWithArray:@[r1,r2]];
    
    NSDictionary *dict = [post remoteDictionaryRepresentationWrapped:NO];
    NSArray *ids = @[@1,@2];
    
    STAssertNil(dict[@"responses"], nil);
    STAssertNil(dict[@"response_ids"], nil);
    STAssertEqualObjects(dict[@"only_id_response_ids"], ids, nil);
}

/** Belongs-to **/

- (void) test_belongs_to
{
	Egg *nn = [[Egg alloc] init];
	
	NSDictionary *sendDict = [nn remoteDictionaryRepresentationWrapped:NO];

	STAssertNil(sendDict[@"bird"], nil);
	STAssertTrue([sendDict[@"bird_id"] isKindOfClass:[NSNull class]], nil);
	
	nn.bird = [[Bird alloc] init];
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil(sendDict[@"bird"], nil);
	STAssertTrue([sendDict[@"bird_id"] isKindOfClass:[NSNull class]], nil);
	
	nn.bird.remoteID = @(15);
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];

	STAssertNil(sendDict[@"bird"], nil);
	STAssertEqualObjects(sendDict[@"bird_id"], @(15), nil);
}

/** Has-one **/

- (void) test_has_one
{
	Egg *nn = [[Egg alloc] init];
	
	NSDictionary *sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil(sendDict[@"nest"], nil);
	STAssertNil(sendDict[@"nest_attributes"], nil);
	
	nn.nest = [[Nest alloc] init];
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil(sendDict[@"nest"], nil);
	STAssertTrue([sendDict[@"nest_attributes"] isKindOfClass:[NSDictionary class]], nil);
	
	nn.nest.remoteID = @(20);
	
	sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNil(sendDict[@"nest"], nil);
	STAssertEqualObjects(sendDict[@"nest_attributes"][@"id"], @(20), nil);
}

- (void) test_nesting_dictionaries
{
	DictionaryNester *plainNester = [DictionaryNester objectWithRemoteDictionary:[MockServer newDictionaryNester]];
	STAssertNotNil(plainNester.dictionaries, @"Dictionaries shouldn't be nil after JSON set");
	STAssertTrue(plainNester.dictionaries.count == 2, @"Dictionaries should have 2 elements");
	STAssertTrue([(plainNester.dictionaries)[0] isKindOfClass:[NSDictionary class]], @"Dictionaries obj should be of type NSDictionary");
	STAssertEqualObjects((plainNester.dictionaries)[0][@"so"], @"im", @"Dict elements should've been set");
	
	plainNester.dictionaries = @[@{@"key": @"obj"}, @{@"key2": @"obj2"}];
	
	NSDictionary *send = [plainNester remoteDictionaryRepresentationWrapped:NO];
	STAssertNotNil(send, @"Dictionaries shouldn't be nil after trying to make it");
	STAssertTrue([send[@"dictionaries"] count] == 2, @"Dictionaries should have 2 elements");
	STAssertTrue([send[@"dictionaries"][0] isKindOfClass:[NSDictionary class]], @"Dictionaries obj should be of type NSDictionary");
	STAssertEqualObjects(send[@"dictionaries"][0][@"key"], @"obj", @"Dict elements should've been set");
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
	STAssertTrue([pDict[BooksKey] isKindOfClass:[NSArray class]], @"Books should be an array");
	STAssertTrue([[pDict[BooksKey] lastObject] isKindOfClass:[NSDictionary class]], @"Book should be a dict");
	STAssertNil([pDict[BooksKey] lastObject][OwnersKey], @"Shouldn't include books's owners since it's not included in nesting");
	
	
	NSDictionary *bDict = [book remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([bDict[OwnersKey] isKindOfClass:[NSArray class]], @"Owners should be an array");
	STAssertTrue([[bDict[OwnersKey] lastObject] isKindOfClass:[NSDictionary class]], @"Owner (person) should be a dict");
	STAssertNil([bDict[OwnersKey] lastObject][BooksKey], @"Shouldn't include owner's books since it's not included in nesting");
	
	
	Book *book2 = [[Book alloc] init];
	book2.owners = [[NSMutableArray alloc] init];
	book2.nestPerson = YES;
	[book2.owners addObject:guy];
	
	[guy.books removeAllObjects];
	[guy.books addObject:book2];
	
	pDict = [guy remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([pDict[BooksKey] isKindOfClass:[NSArray class]], @"Books should be an array");
	STAssertTrue([[pDict[BooksKey] lastObject] isKindOfClass:[NSDictionary class]], @"Book should be a dict");
	STAssertTrue([[pDict[BooksKey] lastObject][OwnersKey] isKindOfClass:[NSArray class]], @"Book should include owners and it should be an array");
	STAssertTrue([[[pDict[BooksKey] lastObject][OwnersKey] lastObject] isKindOfClass:[NSDictionary class]], @"Owner in owner's book's owners should be a dictionary");
	
	
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
	STAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertNil([birdDict[EggsKey] lastObject][MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
	
	e.bird = b;
	
	birdDict = [b remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertNil([birdDict[EggsKey] lastObject][MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
	
	NSDictionary *eggDict = [e remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([eggDict[MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
	STAssertNil(eggDict[MotherKey][EggsKey],@"Mother should not include eggs (since no -n)");
	
	[b.eggs removeAllObjects];
	
	Egg *motherExposingEgg = [[Egg alloc] init];
	motherExposingEgg.nestBird = YES;
	motherExposingEgg.bird = b;
	motherExposingEgg.hasOneBird = YES;
	
	[b.eggs addObject:motherExposingEgg];
	
	birdDict = [b remoteDictionaryRepresentationWrapped:NO];

	STAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertTrue([[birdDict[EggsKey] lastObject][MotherKey] isKindOfClass:[NSDictionary class]], @"Egg's mother should be a dict, since it was included in -n");
	STAssertNil([birdDict[EggsKey] lastObject][MotherKey][EggsKey], @"Egg's mother's eggs shouldn't be included, since mother doesn't define -n on eggs");
	
	eggDict = [motherExposingEgg remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([eggDict[MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
	STAssertNil(eggDict[MotherKey][EggsKey],@"Mother should not include eggs (since no -n)");
	
	
	Bird *nesterBird = [[Bird alloc] init];
	nesterBird.eggs = [[NSMutableArray alloc] init];
	nesterBird.remoteID = @1;
	nesterBird.nestEggs = YES;
	
	Egg *e2 = [[Egg alloc] init];
	e2.bird = nesterBird;
	e2.hasOneBird = YES;
	[nesterBird.eggs addObject:e2];
	
	birdDict = [nesterBird remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertNil([birdDict[EggsKey] lastObject][MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
	
	eggDict = [e2 remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([eggDict[MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
	STAssertTrue([eggDict[MotherKey][EggsKey] isKindOfClass:[NSArray class]],@"Should include eggs in mother because of the -n (and should be array)");
	STAssertTrue([[eggDict[MotherKey][EggsKey] lastObject] isKindOfClass:[NSDictionary class]],@"Should include an egg (as a dict) in mother's eggs");
	STAssertNil([eggDict[MotherKey][EggsKey] lastObject][MotherKey], @"Egg's mother's egg should not have a mother (since no -n)");
	
	e2.bird = nil;
	eggDict = [e2 remoteDictionaryRepresentationWrapped:NO];
	STAssertNil(eggDict[MotherKey],@"Shouldn't send the mother if nil + associated");
	
	[nesterBird.eggs removeAllObjects];
	
	//"belongs-to"
	Egg *attachedEgg = [[Egg alloc] init];
	attachedEgg.bird = nesterBird;
	[nesterBird.eggs addObject:attachedEgg];
	
	birdDict = [nesterBird remoteDictionaryRepresentationWrapped:NO];
	STAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
	STAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
	STAssertNil([birdDict[EggsKey] lastObject][MotherKey], @"Shouldn't have 'mother' -- 'mother_id' since b-t");
	STAssertTrue([[birdDict[EggsKey] lastObject][@"bird_id"] isKindOfClass:[NSNumber class]], @"Egg's mother (self)'s id should be present & be a number");
	
	//should be fine here because even though eggs is marked for nesting, mother is belongs-to, so no recursion should occur
	eggDict = [attachedEgg remoteDictionaryRepresentationWrapped:NO];
	STAssertNil(eggDict[MotherKey], @"'mother' key shouldn't exist - belongs-to, so should be bird_id");
	STAssertTrue([eggDict[@"bird_id"] isKindOfClass:[NSNumber class]], @"mother ID should be exist and be a number");
	
	attachedEgg.bird = nil;
	eggDict = [attachedEgg remoteDictionaryRepresentationWrapped:NO];
	
	STAssertNotNil(eggDict[@"bird_id"], @"'mother_id' key should exist - belongs-to but NULL");
	STAssertTrue([eggDict[@"bird_id"] isKindOfClass:[NSNull class]], @"bird_id should be exist but be null");
}

- (void) test_update_nested_object
{
	Bird *b = [[Bird alloc] init];
	b.eggs = [[NSMutableArray alloc] init];
	b.remoteID = @(1);
	
	Egg *e = [[Egg alloc] init];
	e.bird = b;
	[b.eggs addObject:e];

	NSDictionary *updateDict = @{@"remoteID":@2,@"bird":@{@"remoteID":@1, @"name":@"tweety"}};
	[e setPropertiesUsingRemoteDictionary:updateDict];
	
	STAssertEqualObjects(b.name, @"tweety", nil);
}


@end
