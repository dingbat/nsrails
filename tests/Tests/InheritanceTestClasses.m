//
//  InheritanceTestClasses.m
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InheritanceTestClasses.h"

@implementation STParent
NSRailsify (parent attributes)
NSRailsUseModelName(@"parent")
@end

	@implementation STChild
	NSRailsify (child attributes) //absent NSRNoCarryFromSuper -> will inherit from parent
	//absent model name -> will inherit "parent"
	@end

		@implementation STGrandchild
		NSRailsify(gchild attributes) //absent NSRNoCarryFromSuper -> will inherit from parent
		//absent model name -> will inherit "parent"
		@end

		@implementation STRebelliousGrandchild
		NSRailsify(NSRNoCarryFromSuper, r_gchild attributes) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild") //will override Parent's modelname -> will use "r_grandchild"
		@end


	@implementation STRebelliousChild
	NSRailsify(NSRNoCarryFromSuper, r_child attributes) //NSRNoCarryFromSuper present -> won't inherit anything
	NSRailsUseDefaultModelName //will override Parent's modelname in favor of default behavior -> will use default behavior
	@end

		@implementation STGrandchildOfRebellious
		NSRailsify(gchild_r attributes) //absent NSRNoCarryFromSuper -> will inherit from r.child, BUT inheritance will stop @ R.Child 
		//absent model name BUT will inherit his parent's NSRailsUseDefaultModelName, meaning default behavior will occur
		@end

		@implementation STRebelliousGrandchildOfRebellious
		NSRailsify(NSRNoCarryFromSuper, r_gchild_r attributes) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild_r") //will override R.Child's modelname -> will use "r_r_gchild"
		@end