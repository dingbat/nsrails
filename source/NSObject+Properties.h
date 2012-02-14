//
//  NSObject+Properties.h
//  NSRails
//
//  Created by Dan Hassin on 2/13/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (NSRPropertySupport)

//returns an array of all properties declared in class
+ (NSMutableArray *) classPropertyNames;

//returns type of the given property for that instance variable (ie, NSString)
- (NSString *) getPropertyType:(NSString *)property;

//returns SEL for the setter of given property
- (SEL) getPropertySetter:(NSString *)property;

//returns SEL for the getter of given property
- (SEL) getPropertyGetter:(NSString *)property;

//returns nil if property is not primitive
//otherwise, returns property type (int, double, float, etc)
- (NSString *) propertyIsPrimitive:(NSString *)property;

@end
