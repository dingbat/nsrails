//
//  Inheritance.m
//  NSRails
//
//  Created by Dan Hassin on 1/29/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRAsserts.h"

@interface Parent : NSRailsModel
@property (nonatomic, strong) id parentAttr;
@property (nonatomic, strong) id parentAttr2;
@end
@implementation Parent
@synthesize parentAttr, parentAttr2;
NSRailsSync (*, parentAttr2 -x)
NSRailsUseModelName(@"parent", @"parentS")
NSRailsUseConfig(@"parent")
@end

	@interface Child : Parent
	@property (nonatomic, strong) id childAttr1;
	@property (nonatomic, strong) id childAttr2;
	@end
	@implementation Child
	@synthesize childAttr1, childAttr2;
	NSRailsSync (childAttr1, parentAttr2) //absent NSRNoCarryFromSuper -> will inherit from parent
	//absent model name, config -> will inherit "parent"
	@end

		@interface Grandchild : Child
		@property (nonatomic, strong) id gchildAttr;
		@end
		@implementation Grandchild
		@synthesize gchildAttr;
		NSRailsSync(*, parentAttr2 -x) //absent NSRNoCarryFromSuper -> will inherit from parent, but ignored parentAttr2 as test
		//absent model name, config -> will inherit "parent"
		@end

		@interface RebelliousGrandchild : Child
		@property (nonatomic, strong) id r_gchildAttr;
		@end
		@implementation RebelliousGrandchild
		@synthesize r_gchildAttr;
		NSRailsSync(NSRNoCarryFromSuper *) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild") //will override Parent's modelname -> will use "r_grandchild"
		NSRailsUseConfig(@"r_gchild") //will override Parent's config -> will use "http://r_grandchild"
		@end

	@interface RebelliousChild : Parent
	@property (nonatomic, strong) id r_childAttr;
	@end
	@implementation RebelliousChild
	@synthesize r_childAttr;
	NSRailsSync(* NSRNoCarryFromSuper) //NSRNoCarryFromSuper present -> won't inherit anything
	NSRailsUseDefaultModelName //will override Parent's modelname in favor of default behavior
	NSRailsUseDefaultConfig //will override Parent's config in favor of default behavior (defaultConfig)
	@end

		@interface GrandchildOfRebellious : RebelliousChild
		@property (nonatomic, strong) id gchild_rAttr;
		@end
		@implementation GrandchildOfRebellious
		@synthesize gchild_rAttr;
		NSRailsSync(*) //absent NSRNoCarryFromSuper -> will inherit from r.child, BUT inheritance will stop @ R.Child 
		//absent model name + config BUT will inherit his parent's NSRailsUseDefault..., meaning default behavior will occur
		@end

		@interface RebelliousGrandchildOfRebellious : RebelliousChild
		@property (nonatomic, strong) id r_gchild_rAttr;
		@end
		@implementation RebelliousGrandchildOfRebellious
		@synthesize r_gchild_rAttr;
		NSRailsSync(NSRNoCarryFromSuper, *) //NSRNoCarryFromSuper present -> won't inherit anything
		NSRailsUseModelName(@"r_gchild_r", @"r_gchild_rS") //will override R.Child's modelname -> will use "r_r_gchild"
		NSRailsUseConfig(@"r_gchild_r") //will override R.Child's config -> will use "http://r_r_gchild"
		@end


#define NSRAssertClassConfig(class, teststring) NSRAssertEqualConfigs([class getRelevantConfig], teststring, @"%@ config failed", NSStringFromClass(class))

#define NSRAssertInstanceConfig(class, teststring) NSRAssertEqualConfigs([[[class alloc] init] getRelevantConfig], teststring, @"%@ config failed", NSStringFromClass(class))

#define NSRAssertClassAndInstanceConfig(class, teststring) NSRAssertInstanceConfig(class, teststring); NSRAssertClassConfig(class, teststring)


#define NSRAssertClassProperties(class, ...) NSRAssertEqualArraysNoOrderNoBlanks([[class propertyCollection] properties].allKeys, NSRArray(__VA_ARGS__))

#define NSRAssertInstanceProperties(class, ...) NSRAssertEqualArraysNoOrderNoBlanks([[[[class alloc] init] propertyCollection] properties].allKeys, NSRArray(__VA_ARGS__))

#define NSRAssertClassAndInstanceProperties(class, ...) NSRAssertClassProperties(class, __VA_ARGS__); NSRAssertInstanceProperties(class, __VA_ARGS__)

@interface TInheritance : GHTestCase
@end

@implementation TInheritance

- (void) test_model_name_inheritance
{
	//was explicitly set to "parent"
	NSRAssertClassModelName(@"parent", [Parent class]);
	NSRAssertClassPluralName(@"parentS", [Parent class]);
	
	//complacent child
	//is complacent (doesn't explicitly set NSRailsUseModelName or NSRailsUseDefaultModelName), so will inherit the "parent" from Parent
	NSRAssertClassModelName(@"parent", [Child class]);
	NSRAssertClassPluralName(@"parentS", [Child class]); //explicit plural set
	
	//is complacent (doesn't explicitly set NSRailsUseModelName or NSRailsUseDefaultModelName), so will inherit the "parent" from Child
	NSRAssertClassModelName(@"parent", [Grandchild class]);
	NSRAssertClassPluralName(@"parentS", [Grandchild class]);
	
	//is not complacent (defines NSRailsUseModelName), as set to "r_grandchild"
	NSRAssertClassModelName(@"r_gchild", [RebelliousGrandchild class]);
	NSRAssertClassPluralName(@"r_gchilds", [RebelliousGrandchild class]); //no explicit plural set
	
	
	//rebellious child
	//is rebellious (explicitly defines NSRailsUseDefaultModelName for itself, so should be default behavior)
	NSRAssertClassModelName(@"rebellious_child", [RebelliousChild class]);
	NSRAssertClassPluralName(@"rebellious_childs", [RebelliousChild class]); //default plural set
	
	//is complacent (doesn't explicitly set), BUT will inherit default behavior from R.Child, so default behavior
	NSRAssertClassModelName(@"grandchild_of_rebellious", [GrandchildOfRebellious class]);
	NSRAssertClassPluralName(@"grandchild_of_rebelliouses", [GrandchildOfRebellious class]); //inherits default
	
	//is rebellious (defines NSRailsUseModelName as "r_gchild_r"), so it'll use that name
	NSRAssertClassModelName(@"r_gchild_r", [RebelliousGrandchildOfRebellious class]);
	NSRAssertClassPluralName(@"r_gchild_rS", [RebelliousGrandchildOfRebellious class]); //explicitly set
}

- (void) test_config_inheritance
{
	[[NSRConfig defaultConfig] setAppURL:@"Default"];
	
	//was explicitly set to "parent"
	NSRAssertClassAndInstanceConfig([Parent class], @"parent");
	
	//complacent child
	//is complacent (doesn't explicitly set NSRailsUseConfig or NSRailsUseDefaultConfig), so will inherit the "parent" from Parent
	NSRAssertClassAndInstanceConfig([Child class], @"parent");
	
	//is complacent (doesn't explicitly set NSRailsUseConfig or NSRailsUseDefaultConfig), so will inherit the "parent" from Child
	NSRAssertClassAndInstanceConfig([Grandchild class], @"parent");
	
	//is not complacent (defines NSRailsUseConfig), as set to "r_grandchild"
	NSRAssertClassAndInstanceConfig([RebelliousGrandchild class], @"r_gchild");
	
	
	//rebellious child
	//is rebellious (explicitly defines NSRailsUseDefaultConfig for itself, so should be defaultConfig returned)
	NSRAssertClassAndInstanceConfig([RebelliousChild class], @"Default");
	
	//is complacent (doesn't explicitly set), BUT will inherit default behavior from R.Child, so default behavior
	NSRAssertClassAndInstanceConfig([GrandchildOfRebellious class], @"Default");
	
	//is rebellious (defines NSRailsUseConfig as "r_gchild_r"), so it'll use that name
	NSRAssertClassAndInstanceConfig([RebelliousGrandchildOfRebellious class], @"r_gchild_r");
}

- (void) test_property_inheritance
{
	//this is just normal
	NSRAssertClassAndInstanceProperties([Parent class], @"parentAttr", @"remoteID");
	
	//complacent child
	//is complacent (doesn't explicitly define NSRNoCarryFromSuper), so will inherit parent's attributes too
	//this is simultaneously a test that the "*" from Parent isn't carried over - child has 2 properties and only one is defined
	//this will also test to see if syncing "parentAttr2" is allowed (attribute in parent class not synced by parent class)
	NSRAssertClassAndInstanceProperties([Child class], @"remoteID", @"childAttr1", @"parentAttr2", @"parentAttr");
	
	//is complacent, so should inherit everything! (parent+child), as well as its own
	//however, excludes parentAttr2 as a test
	NSRAssertClassAndInstanceProperties([Grandchild class], @"remoteID", @"childAttr1", @"gchildAttr", @"parentAttr");
	
	//is rebellious, so should inherit nothing! (only its own)
	NSRAssertClassAndInstanceProperties([RebelliousGrandchild class], @"remoteID", @"r_gchildAttr");
	
	
	//rebellious child
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	NSRAssertClassAndInstanceProperties([RebelliousChild class], @"remoteID", @"r_childAttr");
	
	//is complacent, so should inherit everything until it sees the _NSR_NO_SUPER_ (which it omits), meaning won't inherit Parent
	NSRAssertClassAndInstanceProperties([GrandchildOfRebellious class], @"remoteID", @"gchild_rAttr", @"r_childAttr");
	
	//is rebellious, so should inherit nothing (only be using whatever attributes defined by itself)
	NSRAssertClassAndInstanceProperties([RebelliousGrandchildOfRebellious class], @"remoteID", @"r_gchild_rAttr");
}

@end
