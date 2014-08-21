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

@interface RemoteObject : XCTestCase
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
    
    
    XCTAssertNil([SubClass typeForProperty:@"unknown"], @"Introspection should not pick up non-existent properties");
    XCTAssertNil([SubClass typeForProperty:@"private"], @"Introspection should not pick up non-property ivars");
    XCTAssertEqualObjects([SubClass typeForProperty:@"superString"], @"@\"NSString\"", @"Introspection should pick up superclasses' props");
    XCTAssertEqualObjects([SubClass typeForProperty:@"subDate"], @"@\"NSDate\"");
    XCTAssertEqualObjects([SubClass typeForProperty:@"primitiveInt"], @"i");
    XCTAssertNil([SubClass typeForProperty:@"@\"@\""]);
}

- (void) test_dict_wrapping
{
    /** Generating wrap **/
    
    Post *p = [[Post alloc] init];
    p.author = @"hi";
    
    NSDictionary *sendDict = [p remoteDictionaryRepresentationWrapped:NO];
    XCTAssertNil(sendDict[@"post"], @"Shouldn't include itself as a key for no wrap");
    XCTAssertEqualObjects(sendDict[@"author"], @"hi");
    
    NSDictionary *sendDictWrapped = [p remoteDictionaryRepresentationWrapped:YES];
    NSRAssertEqualArraysNoOrder(sendDictWrapped.allKeys, @[@"post"]);
    XCTAssertTrue([sendDictWrapped[@"post"] isKindOfClass:[NSDictionary class]], @"Should include itself as a key for no wrap, and object should be a dict");
    XCTAssertEqual([sendDictWrapped[@"post"] count], [sendDict count], @"Inner dict should have same amount of keys as nowrap");
    
    
    /** Parsing wrap **/
    
    Tester *t = [[Tester alloc] init];
    XCTAssertNil(t.remoteAttributes, @"Shouldn't have any remoteAttributes on first init");
    
    NSDictionary *dict = @{@"tester": @"test"};
    
    [t setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(t.tester, @"test", @"");
    XCTAssertNotNil(t.remoteAttributes, @"remoteAttributes should exist after setting props");
    
    [t setPropertiesUsingRemoteDictionary:dict];
    
    t.tester = nil;
    
    NSDictionary *dictEnveloped = @{@"tester": @{@"tester": @"test"}};
    [t setPropertiesUsingRemoteDictionary:dictEnveloped];
    XCTAssertEqualObjects(t.tester, @"test", @"");
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
            XCTAssertEqualObjects(p.author, @"dan");
            XCTAssertEqualObjects(p.content, @"hi");
            XCTAssertEqualObjects(p.remoteID, @(10));
            
            if (i == 0) {
                p.author = @"CHANGE";
            }
        }
        
        [p setPropertiesUsingRemoteDictionary:dict];
        XCTAssertEqualObjects(p.author, @"dan");
        XCTAssertEqualObjects(p.content, @"hi");        
    }

    /** Dates **/
    
    NSDictionary *dict = @{@"updated_at":[MockServer datetime]};

    [p setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(p.author, @"dan");
    XCTAssertEqualObjects(p.content, @"hi");
    XCTAssertTrue([p.updatedAt isKindOfClass:[NSDate class]]);

    [p setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(p.author, @"dan");
    XCTAssertEqualObjects(p.content, @"hi");
    XCTAssertTrue([p.updatedAt isKindOfClass:[NSDate class]]);
    
    /** Arrays **/
    
    Tester *t = [[Tester alloc] init];
    
    NSArray *array = @[@"hello", @15, @{@"there":@"hi"}, @[@"hop"]];
    dict = @{@"array":array};
    
    [t setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(t.array, array);
    
    [t setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(t.array, array);

    array = @[@"hello", @"CHANGE", @{@"there":@"hi"}, @[@"hop"]];
    dict = @{@"array":array};

    [t setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(t.array, array);

    /** Dicts **/
    
    NSDictionary *dictionary = @{@"key":@34, @"array":@[array], @"string":@"xx"};
    dict = @{@"dictionary":dictionary};
    
    [t setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(t.dictionary, dictionary);
    
    [t setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(t.dictionary, dictionary);
    
    [t setPropertiesUsingRemoteDictionary:dict];
    dict = @{@"dictionary":dictionary};

    [t setPropertiesUsingRemoteDictionary:dict];
    XCTAssertEqualObjects(t.dictionary, dictionary);

    /** Nulls and stuff **/
        
    XCTAssertNoThrow([t setPropertiesUsingRemoteDictionary:nil], @"Shouldn't blow up on setting to nil dictionary");
    
    [t setPropertiesUsingRemoteDictionary:@{@"tester":[NSNull null]}];
    XCTAssertNil(t.tester, @"tester should be nil after setting from JSON");
    
    [t setPropertiesUsingRemoteDictionary:@{@"tester":@{@"tester":[NSNull null]}}];
    XCTAssertNil(t.tester, @"tester should be nil after setting from JSON");
    
    t.tester = (id)[[NSScanner alloc] init];
    XCTAssertThrows([t remoteDictionaryRepresentationWrapped:NO], @"Should blow up on making a dict with scanner");
    XCTAssertThrows([t remoteCreate:nil], @"Should blow up on making bad JSON");    
    
    
    //TODO
    //For each one, test if the specific elements are of right type? ([dict objectForKey:@"array"] isKindOfClass:array)
}

- (void) test_serialization
{
    NSString *file = [NSHomeDirectory() stringByAppendingPathComponent:@"test.dat"];
    
    Tester *e = [[Tester alloc] init];
    e.remoteID = @5;
    BOOL s = [NSKeyedArchiver archiveRootObject:e toFile:file];
    
    XCTAssertTrue(s, @"Archiving should've worked (serialize)");
    
    Tester *eRetrieve = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
    XCTAssertEqualObjects(e.remoteID, eRetrieve.remoteID, @"Should've carried over remoteID");    
}

- (void) test_index_json_into_array
{
    id remoteJSON = @[@{@"author":@"dan"}, @{@"author":@"michael"}];
    NSArray *array = [Post objectsWithRemoteDictionaries:remoteJSON];
    
    XCTAssertNotNil(array);
    XCTAssertEqual(array.count, [remoteJSON count]);
    XCTAssertTrue([array[0] isKindOfClass:[Post class]]);
    XCTAssertEqualObjects([array[0] author], @"dan");
}

- (void) test_index_json_into_array_with_root
{
    id remoteJSON = @{@"posts":@[@{@"author":@"dan"}, @{@"author":@"michael"}]};
    NSArray *array = [Post objectsWithRemoteDictionaries:remoteJSON];
    
    XCTAssertNotNil(array);
    XCTAssertEqual(array.count, (NSUInteger)2);
    XCTAssertTrue([array[0] isKindOfClass:[Post class]]);
    XCTAssertEqualObjects([array[0] author], @"dan");
}

/*************
   OVERRIDES
 *************/

- (void) test_encode_decode
{
    CustomCoder *p = [CustomCoder objectWithRemoteDictionary:[MockServer newCustomCoder]];
    
    XCTAssertTrue([p.csvArray isKindOfClass:[NSArray class]], @"Should've decoded into an array");
    XCTAssertTrue([p.locallyURL isKindOfClass:[NSURL class]], @"Should've decoded into a URL");
    XCTAssertTrue([p.dateOverrideSend isKindOfClass:[NSDate class]], @"Should've decoded into an NSDate");
    XCTAssertTrue([p.dateOverrideRet isEqualToDate:[p customDate]], @"Should've used custom decode");
    XCTAssertNil(p.codeToNil, @"Should've decoded codeToNil into nil");
    XCTAssertEqualObjects([p.locallyURL description], @"http://nsrails.com", @"Should've decoded into URL & retain content");
    NSArray *a = @[@"one", @"two", @"three"];
    XCTAssertEqualObjects(p.csvArray, a, @"Should've decoded into an array & retain content");
    XCTAssertEqualObjects(p.locallyLowercase, @"lowercase?", @"Should've decoded into lowercase");
    XCTAssertEqualObjects(p.remotelyUppercase, @"upper", @"Should've kept the same");
    XCTAssertEqualObjects(p.componentWithFlippingName.componentName, @"comp lowercase?", @"Should've decoded comp name into lowercase");
    XCTAssertEqualObjects(p.objc, @"renamed", @"Should've renamed from 'rails'");
    
    p.codeToNil = @"Something";
    
    NSDictionary *sendDict = [p remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([sendDict[@"csv_array"] isKindOfClass:[NSString class]],@"Should've encoded NSArray -> string");
    XCTAssertTrue([sendDict[@"locally_url"] isKindOfClass:[NSString class]],@"Should've encoded NSURL -> string");
    XCTAssertTrue([sendDict[@"code_to_nil"] isKindOfClass:[NSNull class]], @"Should be nsnull");
    XCTAssertEqualObjects(sendDict[@"csv_array"], @"one,two,three", @"Should've encoded into string & retain content");
    XCTAssertEqualObjects(sendDict[@"locally_url"], @"http://nsrails.com", @"Should've encoded into string & retain content");
    XCTAssertEqualObjects(sendDict[@"locally_lowercase"], @"lowercase?", @"Should've kept as lowercase");
    XCTAssertEqualObjects(sendDict[@"remotely_uppercase"], @"UPPER", @"Should've encoded to uppercase");
    XCTAssertEqualObjects(sendDict[@"date_override_send"], @"override!", @"Should've overriden NSDate encode");
    NSString *dateStr = [[NSRConfig defaultConfig] stringFromDate:[p customDate]];
    XCTAssertEqualObjects(sendDict[@"date_override_ret"], dateStr, @"Should've overriden NSDate decode");
    XCTAssertEqualObjects(p.componentWithFlippingName.componentName, @"COMP LOWERCASE?", @"Should've encoded comp name into uppercase");
    
    XCTAssertEqualObjects(sendDict[@"remote_only"], @"remote", @"Should've captured remoteOnly!");
    XCTAssertEqualObjects(sendDict[@"objc"], @"renamed", @"Should've kept objc because was not set");
    
    p.encodeNonJSON = YES;
    
    XCTAssertThrows([p remoteDictionaryRepresentationWrapped:NO], @"Encoding into non-JSON for sendable dict - where's the error?");
}

- (void) test_send_retrieve
{
    CustomSender *p = [[CustomSender alloc] init];
    p.local = @"local";
    p.sendOnly = @"send--local";
    p.undefined = @"local";
    [p setPropertiesUsingRemoteDictionary:[MockServer newCustomSender]];
    
    XCTAssertEqualObjects(p.local, @"local", @"Should've kept local... -x");
    XCTAssertEqualObjects(p.sendOnly, @"send--local", @"Should've kept send... -s");
    XCTAssertEqualObjects(p.retrieveOnly, @"retrieve", @"Should've set retrieve... -r");
    XCTAssertEqualObjects(p.shared, @"shared", @"Should've set shared... blank");
    XCTAssertEqualObjects(p.sharedExplicit, @"shared explicit", @"Should've set sharedExplicit... -rs");
    XCTAssertEqualObjects(p.undefined, @"local", @"Shouldn't have set undefined...");
    
    NSDictionary *sendDict = [p remoteDictionaryRepresentationWrapped:NO];
    XCTAssertNil(sendDict[@"retrieve_only"], @"Shouldn't send retrieve-only... -r");
    XCTAssertNil(sendDict[@"local"], @"Shouldn't send local-only... -x");
    XCTAssertNil(sendDict[@"undefined"], @"Shouldn't send undefined...");
    XCTAssertEqualObjects(sendDict[@"send_only"], @"send--local", @"Should've sent send... -s");
    XCTAssertEqualObjects(sendDict[@"shared"], @"shared", @"Should've sent shared... blank");
    XCTAssertEqualObjects(sendDict[@"shared_explicit"], @"shared explicit", @"Should've sent sharedExplicit... -rs");
}

/***************
    NESTING
 **************/

- (void) test_destroy_on_nesting
{
    Bird *bird = [[Bird alloc] init];
    
    NSDictionary *dict = [bird remoteDictionaryRepresentationWrapped:NO];
    XCTAssertNil(dict[@"_destroy"],@"No _destroy key if no remoteDestroyOnNesting");
    
    bird.remoteDestroyOnNesting = YES;
    
    dict = [bird remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([dict[@"_destroy"] boolValue],@"remoteDestroyOnNesting should add _destroy key");
    
    Egg *e = [[Egg alloc] init];
    e.remoteDestroyOnNesting = YES;
    
    bird.eggs = [[NSMutableArray alloc] initWithObjects:e, nil];
    
    bird.remoteDestroyOnNesting = NO;
    dict = [bird remoteDictionaryRepresentationWrapped:NO];
    
    XCTAssertNil(dict[@"_destroy"],@"No _destroy key if no remoteDestroyOnNesting");
    XCTAssertTrue([dict[@"eggs_attributes"] isKindOfClass:[NSArray class]],@"Eggs should exist & be an array");
    XCTAssertTrue([[dict[@"eggs_attributes"] lastObject][@"_destroy"] boolValue],@"_destroy key should exist on egg if remoteDestroyOnNesting");    
}

/** Has-many **/

- (void) test_has_many
{
    Bird *nn = [[Bird alloc] init];
    
    NSDictionary *sendDict = [nn remoteDictionaryRepresentationWrapped:NO];

    XCTAssertNil(sendDict[@"eggs"]);
    XCTAssertNil(sendDict[@"eggs_attributes"]);
    
    nn.eggs = [[NSMutableArray alloc] init];
    
    sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
    
    XCTAssertNil(sendDict[@"eggs"]);
    XCTAssertNil(sendDict[@"eggs_attributes"]);

    Egg *egg = [[Egg alloc] init];
    egg.remoteID = @999;
    [nn.eggs addObject:egg];
        
    sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
    XCTAssertNil(sendDict[@"eggs"]);
    XCTAssertTrue([[sendDict[@"eggs_attributes"] lastObject] isKindOfClass:[NSDictionary class]]);
    
    ////
    ////
    
    nn.eggs = nil;
    
    sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
    XCTAssertNil(sendDict[@"eggs_attributes"], @"'array' key shouldn't exist if empty");
    XCTAssertNil(sendDict[@"eggs"], @"'array' key shouldn't exist if empty");
    
    nn.eggs = [[NSMutableArray alloc] initWithObjects:egg, nil];
    
    sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([[sendDict[@"eggs_attributes"] lastObject] isKindOfClass:[NSDictionary class]], @"'array' key should exist & be a dict (egg representation)");
    XCTAssertTrue([sendDict[@"eggs_attributes"] count] == 1, @"'array' key should have one element");
    
    NSMutableDictionary *inDict = [NSMutableDictionary dictionaryWithDictionary:sendDict];
    
    //right now it's array_attributes - change to just "array" as if it was coming from rails
    inDict[@"eggs"] = inDict[@"eggs_attributes"];
    [inDict removeObjectForKey:@"eggs_attributes"];
    
    [nn setPropertiesUsingRemoteDictionary:inDict];
    XCTAssertNotNil(nn.eggs, @"Array shouldn't be nil");
    XCTAssertTrue([nn.eggs isKindOfClass:[NSArray class]], @"plain.array should be set to array");
    XCTAssertTrue(nn.eggs.count == 1, @"plain.array should have one element");
    XCTAssertTrue([[nn.eggs lastObject] isKindOfClass:[Egg class]], @"plain.array should be filled w/Egg");
    
    //"wrap" an element of the has-many
    inDict[@"eggs"] = @[@{@"egg":inDict[@"eggs"][0]}];
    [nn setPropertiesUsingRemoteDictionary:inDict];
    XCTAssertTrue(nn.eggs.count == 1, @"plain.array should have one element");
    XCTAssertTrue(nn.eggs[0] == egg, @"should be the same egg");
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
    XCTAssertTrue(bird.eggs.count == 1, @"Should be destructive");
    XCTAssertTrue([bird.eggs[0] remoteID].intValue == 3, @"Should be the third egg");
    
    bird.nondestructiveEggs = YES;
    
    railsDict = @{@"eggs":@[@{@"id":@4}]};
    [bird setPropertiesUsingRemoteDictionary:railsDict];
    XCTAssertTrue(bird.eggs.count == 2, @"Should be additive");
    XCTAssertTrue([[bird.eggs lastObject] remoteID].intValue == 4, @"Should be the fourth egg");
    
    [bird setPropertiesUsingRemoteDictionary:railsDict];
    XCTAssertTrue(bird.eggs.count == 2, @"Should be additive, but unique");
    XCTAssertTrue([[bird.eggs lastObject] remoteID].intValue == 4, @"Should be the fourth egg");
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
    
    XCTAssertNil(dict[@"responses"]);
    XCTAssertNil(dict[@"response_ids"]);
    XCTAssertEqualObjects(dict[@"only_id_response_ids"], ids);
}

/** Belongs-to **/

- (void) test_belongs_to
{
    Egg *nn = [[Egg alloc] init];
    
    NSDictionary *sendDict = [nn remoteDictionaryRepresentationWrapped:NO];

    XCTAssertNil(sendDict[@"bird"]);
    XCTAssertTrue([sendDict[@"bird_id"] isKindOfClass:[NSNull class]]);
    
    nn.bird = [[Bird alloc] init];
    
    sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
    
    XCTAssertNil(sendDict[@"bird"]);
    XCTAssertTrue([sendDict[@"bird_id"] isKindOfClass:[NSNull class]]);
    
    nn.bird.remoteID = @(15);
    
    sendDict = [nn remoteDictionaryRepresentationWrapped:NO];

    XCTAssertNil(sendDict[@"bird"]);
    XCTAssertEqualObjects(sendDict[@"bird_id"], @(15));
}

/** Has-one **/

- (void) test_has_one
{
    Egg *nn = [[Egg alloc] init];
    
    NSDictionary *sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
    
    XCTAssertNil(sendDict[@"nest"]);
    XCTAssertNil(sendDict[@"nest_attributes"]);
    
    nn.nest = [[Nest alloc] init];
    
    sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
    
    XCTAssertNil(sendDict[@"nest"]);
    XCTAssertTrue([sendDict[@"nest_attributes"] isKindOfClass:[NSDictionary class]]);
    
    nn.nest.remoteID = @(20);
    
    sendDict = [nn remoteDictionaryRepresentationWrapped:NO];
    
    XCTAssertNil(sendDict[@"nest"]);
    XCTAssertEqualObjects(sendDict[@"nest_attributes"][@"id"], @(20));
}

- (void) test_nesting_dictionaries
{
    DictionaryNester *plainNester = [DictionaryNester objectWithRemoteDictionary:[MockServer newDictionaryNester]];
    XCTAssertNotNil(plainNester.dictionaries, @"Dictionaries shouldn't be nil after JSON set");
    XCTAssertTrue(plainNester.dictionaries.count == 2, @"Dictionaries should have 2 elements");
    XCTAssertTrue([(plainNester.dictionaries)[0] isKindOfClass:[NSDictionary class]], @"Dictionaries obj should be of type NSDictionary");
    XCTAssertEqualObjects((plainNester.dictionaries)[0][@"so"], @"im", @"Dict elements should've been set");
    
    plainNester.dictionaries = @[@{@"key": @"obj"}, @{@"key2": @"obj2"}];
    
    NSDictionary *send = [plainNester remoteDictionaryRepresentationWrapped:NO];
    XCTAssertNotNil(send, @"Dictionaries shouldn't be nil after trying to make it");
    XCTAssertTrue([send[@"dictionaries"] count] == 2, @"Dictionaries should have 2 elements");
    XCTAssertTrue([send[@"dictionaries"][0] isKindOfClass:[NSDictionary class]], @"Dictionaries obj should be of type NSDictionary");
    XCTAssertEqualObjects(send[@"dictionaries"][0][@"key"], @"obj", @"Dict elements should've been set");
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
    XCTAssertTrue([pDict[BooksKey] isKindOfClass:[NSArray class]], @"Books should be an array");
    XCTAssertTrue([[pDict[BooksKey] lastObject] isKindOfClass:[NSDictionary class]], @"Book should be a dict");
    XCTAssertNil([pDict[BooksKey] lastObject][OwnersKey], @"Shouldn't include books's owners since it's not included in nesting");
    
    
    NSDictionary *bDict = [book remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([bDict[OwnersKey] isKindOfClass:[NSArray class]], @"Owners should be an array");
    XCTAssertTrue([[bDict[OwnersKey] lastObject] isKindOfClass:[NSDictionary class]], @"Owner (person) should be a dict");
    XCTAssertNil([bDict[OwnersKey] lastObject][BooksKey], @"Shouldn't include owner's books since it's not included in nesting");
    
    
    Book *book2 = [[Book alloc] init];
    book2.owners = [[NSMutableArray alloc] init];
    book2.nestPerson = YES;
    [book2.owners addObject:guy];
    
    [guy.books removeAllObjects];
    [guy.books addObject:book2];
    
    pDict = [guy remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([pDict[BooksKey] isKindOfClass:[NSArray class]], @"Books should be an array");
    XCTAssertTrue([[pDict[BooksKey] lastObject] isKindOfClass:[NSDictionary class]], @"Book should be a dict");
    XCTAssertTrue([[pDict[BooksKey] lastObject][OwnersKey] isKindOfClass:[NSArray class]], @"Book should include owners and it should be an array");
    XCTAssertTrue([[[pDict[BooksKey] lastObject][OwnersKey] lastObject] isKindOfClass:[NSDictionary class]], @"Owner in owner's book's owners should be a dictionary");
    
    
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
    XCTAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
    XCTAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
    XCTAssertNil([birdDict[EggsKey] lastObject][MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
    
    e.bird = b;
    
    birdDict = [b remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
    XCTAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
    XCTAssertNil([birdDict[EggsKey] lastObject][MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
    
    NSDictionary *eggDict = [e remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([eggDict[MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
    XCTAssertNil(eggDict[MotherKey][EggsKey],@"Mother should not include eggs (since no -n)");
    
    [b.eggs removeAllObjects];
    
    Egg *motherExposingEgg = [[Egg alloc] init];
    motherExposingEgg.nestBird = YES;
    motherExposingEgg.bird = b;
    motherExposingEgg.hasOneBird = YES;
    
    [b.eggs addObject:motherExposingEgg];
    
    birdDict = [b remoteDictionaryRepresentationWrapped:NO];

    XCTAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
    XCTAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
    XCTAssertTrue([[birdDict[EggsKey] lastObject][MotherKey] isKindOfClass:[NSDictionary class]], @"Egg's mother should be a dict, since it was included in -n");
    XCTAssertNil([birdDict[EggsKey] lastObject][MotherKey][EggsKey], @"Egg's mother's eggs shouldn't be included, since mother doesn't define -n on eggs");
    
    eggDict = [motherExposingEgg remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([eggDict[MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
    XCTAssertNil(eggDict[MotherKey][EggsKey],@"Mother should not include eggs (since no -n)");
    
    
    Bird *nesterBird = [[Bird alloc] init];
    nesterBird.eggs = [[NSMutableArray alloc] init];
    nesterBird.remoteID = @1;
    nesterBird.nestEggs = YES;
    
    Egg *e2 = [[Egg alloc] init];
    e2.bird = nesterBird;
    e2.hasOneBird = YES;
    [nesterBird.eggs addObject:e2];
    
    birdDict = [nesterBird remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
    XCTAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
    XCTAssertNil([birdDict[EggsKey] lastObject][MotherKey], @"Shouldn't include egg's mother since it's not included in nesting");
    
    eggDict = [e2 remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([eggDict[MotherKey] isKindOfClass:[NSDictionary class]],@"Should include mother on top-level nesting");
    XCTAssertTrue([eggDict[MotherKey][EggsKey] isKindOfClass:[NSArray class]],@"Should include eggs in mother because of the -n (and should be array)");
    XCTAssertTrue([[eggDict[MotherKey][EggsKey] lastObject] isKindOfClass:[NSDictionary class]],@"Should include an egg (as a dict) in mother's eggs");
    XCTAssertNil([eggDict[MotherKey][EggsKey] lastObject][MotherKey], @"Egg's mother's egg should not have a mother (since no -n)");
    
    e2.bird = nil;
    eggDict = [e2 remoteDictionaryRepresentationWrapped:NO];
    XCTAssertNil(eggDict[MotherKey],@"Shouldn't send the mother if nil + associated");
    
    [nesterBird.eggs removeAllObjects];
    
    //"belongs-to"
    Egg *attachedEgg = [[Egg alloc] init];
    attachedEgg.bird = nesterBird;
    [nesterBird.eggs addObject:attachedEgg];
    
    birdDict = [nesterBird remoteDictionaryRepresentationWrapped:NO];
    XCTAssertTrue([birdDict[EggsKey] isKindOfClass:[NSArray class]], @"Eggs should be an array");
    XCTAssertTrue([[birdDict[EggsKey] lastObject] isKindOfClass:[NSDictionary class]], @"Egg should be a dict");
    XCTAssertNil([birdDict[EggsKey] lastObject][MotherKey], @"Shouldn't have 'mother' -- 'mother_id' since b-t");
    XCTAssertTrue([[birdDict[EggsKey] lastObject][@"bird_id"] isKindOfClass:[NSNumber class]], @"Egg's mother (self)'s id should be present & be a number");
    
    //should be fine here because even though eggs is marked for nesting, mother is belongs-to, so no recursion should occur
    eggDict = [attachedEgg remoteDictionaryRepresentationWrapped:NO];
    XCTAssertNil(eggDict[MotherKey], @"'mother' key shouldn't exist - belongs-to, so should be bird_id");
    XCTAssertTrue([eggDict[@"bird_id"] isKindOfClass:[NSNumber class]], @"mother ID should be exist and be a number");
    
    attachedEgg.bird = nil;
    eggDict = [attachedEgg remoteDictionaryRepresentationWrapped:NO];
    
    XCTAssertNotNil(eggDict[@"bird_id"], @"'mother_id' key should exist - belongs-to but NULL");
    XCTAssertTrue([eggDict[@"bird_id"] isKindOfClass:[NSNull class]], @"bird_id should be exist but be null");
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
    
    XCTAssertEqualObjects(b.name, @"tweety");
}


@end
