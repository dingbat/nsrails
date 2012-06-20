/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRRelationship.h
 
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

/**
 NSRRelationship is the class to describes relationships between objects in NSRails.
 
 See <NSRRemoteObject>'s `relationshipForProperty:` for usage.
 */

@interface NSRRelationship : NSObject

@property (nonatomic, readonly) Class nestedClass;
@property (nonatomic, readonly, getter = isToMany) BOOL toMany;
@property (nonatomic, readonly, getter = isBelongsTo) BOOL belongsTo;

/**
 Returns a relationship to describe a to-many relationship.
 
 @param class The class of which your class "has many".
 @return A relationship to describe a to-many relationship.
 */
+ (NSRRelationship *) hasMany:(Class)class;

/**
 Returns a relationship to describe a to-one relationship.
 
 Almost never used because this is the default relationship for properties with a type that's an NSRRemoteObject subclass.
 
 @param class The class of which your class "has one".
 @return A relationship to describe a to-one relationship.
 */
+ (NSRRelationship *) hasOne:(Class)class;

/**
 Returns a relationship to describe a belongs-to relationship.
 
 The difference between this and <hasOne:> is that when nesting that property, `<property>_id` would be sent (with just its `remoteID`), to correspond to the foreign key defined on the remote model. Has-one instead sends the `<property>_attributes` key with it, including the entire representation of the object.
 
 @param class The class of which your class "belongs to".
 @return A relationship to describe a belongs-to relationship.
 */
+ (NSRRelationship *) belongsTo:(Class)class;

@end
