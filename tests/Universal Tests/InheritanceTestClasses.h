//
//  InheritanceTestClasses.h
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

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