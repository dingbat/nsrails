/*
 
 _|_|_|    _|_|_|  _|_|    _|_|  _|  _|    _|_|           
 _|  _|  _|_|_|    _|  _|  _|_|  _|  _|  _|_|_| 
 
 NSObject+Properties.h
 
 Copyright (c) 2012 Dan Hassin.
 
 Permission is hereby granted, free of charge, to any person obtaining
 a copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import <Foundation/Foundation.h>

@interface NSObject (NSRPropertySupport)

//returns an array of all properties declared in class
+ (NSMutableArray *) classPropertyNames;

//returns type of the given property for that instance variable (ie, NSString)
+ (NSString *) getPropertyType:(NSString *)property;

//returns SEL for the setter of given property
+ (SEL) getPropertySetter:(NSString *)property;

//returns SEL for the getter of given property
+ (SEL) getPropertyGetter:(NSString *)property;

//returns nil if property is not primitive
//otherwise, returns property type (int, double, float, etc)
+ (NSString *) propertyIsPrimitive:(NSString *)property;

@end
