//
//  InheritanceTestClasses.m
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InheritanceTestClasses.h"

@implementation STParent
@synthesize parentAttr;
NSRailsify (*)
NSRailsUseModelName(@"parent")
@end

	@implementation STChild
	@synthesize childAttr1, childAttr2;
	NSRailsify (childAttr1) //absent NSRNoCarryFromSuper -> will inherit from parent
	//absent model name -> will inherit "parent"
	@end

		@implementation STGrandchild
		@synthesize gchildAttr;
		NSRailsify(*) //absent NSRNoCarryFromSuper -> will inherit from parent
		//absent model name -> will inherit "parent"
		@end

		@implementation STRebelliousGrandchild
		@synthesize r_gchildAttr;
		NSRailsify(NSRNoCarryFromSuper *) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild") //will override Parent's modelname -> will use "r_grandchild"
		@end


	@implementation STRebelliousChild
	@synthesize r_childAttr;
	NSRailsify(* NSRNoCarryFromSuper) //NSRNoCarryFromSuper present -> won't inherit anything
	NSRailsUseDefaultModelName //will override Parent's modelname in favor of default behavior -> will use default behavior
	@end

		@implementation STGrandchildOfRebellious
		@synthesize gchild_rAttr;
		NSRailsify(*) //absent NSRNoCarryFromSuper -> will inherit from r.child, BUT inheritance will stop @ R.Child 
		//absent model name BUT will inherit his parent's NSRailsUseDefaultModelName, meaning default behavior will occur
		@end

		@implementation STRebelliousGrandchildOfRebellious
		@synthesize r_gchild_rAttr;
		NSRailsify(NSRNoCarryFromSuper, *) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild_r") //will override R.Child's modelname -> will use "r_r_gchild"
		@end

