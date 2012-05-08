//
//  TestClasses.h
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

@interface TestClassParent : NSRailsModel
@end

@interface TestClass : NSRailsModel

@property (nonatomic) int primitiveAttr;
@property (nonatomic, strong) NSString *myID;
@property (nonatomic, strong) NSString *attr1;
@property (nonatomic, strong) NSString *attr2;
@property (nonatomic, strong, readonly) NSString *badRetrieve;

@property (nonatomic, strong) NSString *send, *retrieve, *encode, *decode, *local;
@property (nonatomic, strong) TestClassParent *parent;

@property (nonatomic, strong) NSArray *array;

@end

@interface ClassWithNoRailsSync : NSRailsModel

@property (nonatomic, strong) NSString *attribute;

@end


/*
 
 Nesting

 */

@interface Post : NSRailsModel

@property (nonatomic, strong) NSString *author, *content;
@property (nonatomic, strong) NSMutableArray *responses;
@property (nonatomic, strong) NSDate *updatedAt, *createdAt;

@end


@interface NSRResponse : NSRailsModel   //prefix to test ignore-prefix feature

@property (nonatomic, strong) NSString *content, *author;
@property (nonatomic, strong) Post *post;

@end


//bad because doesn't inherit from NSRailsModel
@interface BadResponse : NSObject

@property (nonatomic, strong) NSString *content, *author;
@property (nonatomic, strong) Post *post;

@end


/*
 
 Inheritance
 
 */

@interface Parent : NSRailsModel
@property (nonatomic, strong) id parentAttr;
@property (nonatomic, strong) id parentAttr2;
@end

	@interface Child : Parent
	@property (nonatomic, strong) id childAttr1;
	@property (nonatomic, strong) id childAttr2;
	@end

		@interface Grandchild : Child
		@property (nonatomic, strong) id gchildAttr;
		@end

		@interface RebelliousGrandchild : Child
		@property (nonatomic, strong) id r_gchildAttr;
		@end


	@interface RebelliousChild : Parent
	@property (nonatomic, strong) id r_childAttr;
	@end

		@interface GrandchildOfRebellious : RebelliousChild
		@property (nonatomic, strong) id gchild_rAttr;
		@end

		@interface RebelliousGrandchildOfRebellious : RebelliousChild
		@property (nonatomic, strong) id r_gchild_rAttr;
		@end


