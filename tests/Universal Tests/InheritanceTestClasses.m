//
//  InheritanceTestClasses.m
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InheritanceTestClasses.h"

@implementation Parent
@synthesize parentAttr, parentAttr2;
NSRailsify (parentAttr)
NSRailsUseModelName(@"parent")
@end

	@implementation Child
	@synthesize childAttr1, childAttr2;
	NSRailsify (childAttr1, parentAttr2) //absent NSRNoCarryFromSuper -> will inherit from parent
	//absent model name -> will inherit "parent"
	@end

		@implementation Grandchild
		@synthesize gchildAttr;
		NSRailsify(*, parentAttr2 -x) //absent NSRNoCarryFromSuper -> will inherit from parent, but ignored parentAttr2 as test
		//absent model name -> will inherit "parent"
		@end

		@implementation RebelliousGrandchild
		@synthesize r_gchildAttr;
		NSRailsify(NSRNoCarryFromSuper *) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild") //will override Parent's modelname -> will use "r_grandchild"
		@end


	@implementation RebelliousChild
	@synthesize r_childAttr;
	NSRailsify(* NSRNoCarryFromSuper) //NSRNoCarryFromSuper present -> won't inherit anything
	NSRailsUseDefaultModelName //will override Parent's modelname in favor of default behavior -> will use default behavior
	@end

		@implementation GrandchildOfRebellious
		@synthesize gchild_rAttr;
		NSRailsify(*) //absent NSRNoCarryFromSuper -> will inherit from r.child, BUT inheritance will stop @ R.Child 
		//absent model name BUT will inherit his parent's NSRailsUseDefaultModelName, meaning default behavior will occur
		@end

		@implementation RebelliousGrandchildOfRebellious
		@synthesize r_gchild_rAttr;
		NSRailsify(NSRNoCarryFromSuper, *) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild_r") //will override R.Child's modelname -> will use "r_r_gchild"
		@end

