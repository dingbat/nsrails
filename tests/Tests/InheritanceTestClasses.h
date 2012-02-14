//
//  InheritanceTestClasses.h
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRails.h"

@interface STParent : NSRailsModel
@end

	@interface STChild : STParent
	@end

		@interface STGrandchild : STChild
		@end

		@interface STRebelliousGrandchild : STChild
		@end


	@interface STRebelliousChild : STParent
	@end

		@interface STGrandchildOfRebellious : STRebelliousChild
		@end

		@interface STRebelliousGrandchildOfRebellious : STRebelliousChild
		@end