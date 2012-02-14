//
//  InheritanceTestClasses.h
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRails.h"

@interface STParent : NSRailsModel
@property (nonatomic, strong) id parentAttr;
@end

	@interface STChild : STParent
	@property (nonatomic, strong) id childAttr1;
	@property (nonatomic, strong) id childAttr2;
	@end

		@interface STGrandchild : STChild
		@property (nonatomic, strong) id gchildAttr;
		@end

		@interface STRebelliousGrandchild : STChild
		@property (nonatomic, strong) id r_gchildAttr;
		@end


	@interface STRebelliousChild : STParent
	@property (nonatomic, strong) id r_childAttr;
	@end

		@interface STGrandchildOfRebellious : STRebelliousChild
		@property (nonatomic, strong) id gchild_rAttr;
		@end

		@interface STRebelliousGrandchildOfRebellious : STRebelliousChild
		@property (nonatomic, strong) id r_gchild_rAttr;
		@end