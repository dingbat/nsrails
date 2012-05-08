//
//  TestClasses.m
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "TestClasses.h"

@implementation TestClassParent

@end


@implementation TestClass
@synthesize primitiveAttr, myID, attr1, attr2, array;
@synthesize retrieve, send, local, decode, encode, parent, badRetrieve;

- (NSString *) encodeEncode
{
	return [encode uppercaseString];
}

- (NSString *) decodeDecode:(NSString *)_decode
{
	return [_decode lowercaseString];
}


@end

@implementation ClassWithNoRailsSync
@synthesize attribute;

@end


/*
 
 Nesting

 */

@implementation Post
@synthesize author, content, responses, updatedAt, createdAt;
NSRailsSync(*, responses:NSRResponse, updatedAt -r)

@end

@implementation NSRResponse
@synthesize post, content, author;
NSRailsSync(*)

@end

@implementation BadResponse
@synthesize post, content, author;
NSRailsSync(*)

@end


/*
 
 Inheritance
 
 */

@implementation Parent
@synthesize parentAttr, parentAttr2;
NSRailsSync (*, parentAttr2 -x)
NSRailsUseModelName(@"parent", @"parentS")
NSRailsUseConfig(@"http://parent")
@end

	@implementation Child
	@synthesize childAttr1, childAttr2;
	NSRailsSync (childAttr1, parentAttr2) //absent NSRNoCarryFromSuper -> will inherit from parent
	//absent model name, config -> will inherit "parent"
	@end

		@implementation Grandchild
		@synthesize gchildAttr;
		NSRailsSync(*, parentAttr2 -x) //absent NSRNoCarryFromSuper -> will inherit from parent, but ignored parentAttr2 as test
		//absent model name, config -> will inherit "parent"
		@end

		@implementation RebelliousGrandchild
		@synthesize r_gchildAttr;
		NSRailsSync(NSRNoCarryFromSuper *) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild") //will override Parent's modelname -> will use "r_grandchild"
		NSRailsUseConfig(@"http://r_gchild") //will override Parent's config -> will use "http://r_grandchild"
		@end


	@implementation RebelliousChild
	@synthesize r_childAttr;
	NSRailsSync(* NSRNoCarryFromSuper) //NSRNoCarryFromSuper present -> won't inherit anything
	NSRailsUseDefaultModelName //will override Parent's modelname in favor of default behavior
	NSRailsUseDefaultConfig //will override Parent's config in favor of default behavior (defaultConfig)
	@end

		@implementation GrandchildOfRebellious
		@synthesize gchild_rAttr;
		NSRailsSync(*) //absent NSRNoCarryFromSuper -> will inherit from r.child, BUT inheritance will stop @ R.Child 
		//absent model name + config BUT will inherit his parent's NSRailsUseDefault..., meaning default behavior will occur
		@end

		@implementation RebelliousGrandchildOfRebellious
		@synthesize r_gchild_rAttr;
		NSRailsSync(NSRNoCarryFromSuper, *) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild_r", @"r_gchild_rS") //will override R.Child's modelname -> will use "r_r_gchild"
		NSRailsUseConfig(@"http://r_gchild_r") //will override R.Child's config -> will use "http://r_r_gchild"
		@end


