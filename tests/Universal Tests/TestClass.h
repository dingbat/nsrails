//
//  TestClass.h
//  NSRails
//
//  Created by Dan Hassin on 2/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRails.h"

@interface TestClass : NSRailsModel

@property (nonatomic) int primitiveAttr;
@property (nonatomic, strong) NSString *myID;
@property (nonatomic, strong) NSString *attr1;
@property (nonatomic, strong) NSString *attr2;

@end