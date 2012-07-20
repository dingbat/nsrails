//
//  MockClasses.h
//  NSRails
//
//  Created by Dan Hassin on 6/12/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

@interface SuperClass : NSRRemoteObject
@property (nonatomic, strong) NSString *superString;
@end

@interface SubClass : SuperClass
{
	NSString *private;
}
@property (nonatomic, strong) NSDate *subDate;
@property (nonatomic, strong) id anything;
@property (nonatomic) int primitiveInt;
@property (nonatomic) CGRect rect;
@end

@interface Post : NSRRemoteObject
@property (nonatomic) BOOL noResponseRelationship;
@property (nonatomic, strong) NSString *author, *content;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSMutableArray *responses;
@end

@interface Response : NSRRemoteObject
@property (nonatomic) BOOL belongsToPost;
@property (nonatomic, strong) NSString *content, *author;
@property (nonatomic, strong) Post *post;
@end

@interface Tester : NSRRemoteObject
@property (nonatomic, strong) NSString *tester;
@property (nonatomic, strong) NSArray *array;
@property (nonatomic, strong) NSDictionary *dictionary;
@end

/** Nesting **/

@interface NestParent : NSRRemoteObject
@end

@interface NestChild : NSRRemoteObject
@property (nonatomic, strong) NestParent *parent;
@end

@interface NestChildPrefixed : NestChild
@end

@interface NestChildPrefixedChild : NestChildPrefixed
@property (nonatomic, strong) NestChildPrefixed *childParent;
@end

@interface Nest : NSRRemoteObject
@end

@interface DictionaryNester : NSRRemoteObject
@property (nonatomic, strong) NSArray *dictionaries;
@end

@interface Bird : NSRRemoteObject
@property (nonatomic) BOOL nestEggs;
@property (nonatomic, strong) NSMutableArray *eggs;
@end

@interface Egg : NSRRemoteObject
@property (nonatomic) BOOL nestBird, hasOneBird;
@property (nonatomic, strong) Bird *bird;
@property (nonatomic, strong) Nest *nest;
@end


@interface Book : NSRRemoteObject
@property (nonatomic, strong) NSMutableArray *owners;
@property (nonatomic) BOOL nestPerson;
@end

@interface Person : NSRRemoteObject
@property (nonatomic, strong) NSMutableArray *books;
@end


/** Overriding **/

@interface CustomCoderComponent : NSRRemoteObject
@property (nonatomic, strong) NSString *componentName;
@end

@interface CustomCoder : NSRRemoteObject
@property (nonatomic) BOOL encodeNonJSON;
@property (nonatomic, strong) NSURL *locallyURL;
@property (nonatomic, strong) NSArray *csvArray;
@property (nonatomic, strong) NSString *locallyLowercase, *remotelyUppercase, *codeToNil, *remoteOnly, *objc;
@property (nonatomic, strong) CustomCoderComponent *componentWithFlippingName;
@property (nonatomic, strong) NSDate *dateOverrideSend, *dateOverrideRet;

- (NSDate *) customDate;

@end

@interface CustomSender : NSRRemoteObject
@property (nonatomic, strong) NSString *local, *retrieveOnly, *sendOnly, *shared, *sharedExplicit, *undefined;
@end

@interface CustomClass : NSRRemoteObject
@end

@interface CustomConfigClass : NSRRemoteObject
@end
