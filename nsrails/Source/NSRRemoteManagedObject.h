/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRRemoteManagedObject.h
 
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

#import "NSRRemoteObject.h"

/**
 ### Setting up
 
 **You can either:**
 
 - Go into **`NSRails.h`** and uncomment this line:
 
 #define NSR_USE_COREDATA
 
 - OR, if you don't want to mess with NSRails source, you can also add **`NSR_USE_COREDATA`** to "Preprocessor Macros Not Used in Precompiled Headers" in your target's build settings:
 
 
 <div style="text-align:center"><a href="cd-flag.png"><img src="cd-flag.png" width=350></img></a></div>
 
 **Why is this necessary?**
 
 - By default, NSRRemoteObject inherits from NSObject. Because your managed, NSRails-enabled class need to inherit from NSManagedObject in order to function within CoreData, and because Objective-C does not allow multiple inheritance, NSRRemoteObject will modify its superclass to NSManagedObject during compile-time if `NSR_USE_COREDATA` is defined.
 
 ### Setting a universal context
 
 - You must set your managed object context to your config's managedObjectContext property so that NSRails can automatically insert or search for CoreData objects when operations require it:
 
 [[NSRConfig defaultConfig] setManagedObjectContext:<#your MOC#>];
 
 ### remoteID
 
 - `remoteID` is used as a "primary key" that NSRails will use to find other instances, etc. This key also validates uniqueness, meaning saving a context with two records of the same type with the same remoteID will fail.
 
 - `remoteID` must be defined in your *.xcdatamodeld data model file. You can either create an abstract entity that defines a `remoteID` attribute and acts as a parent to your other entities (preferred), **OR** declare `remoteID` for each entity that subclasses NSRRemoteManagedObject:
 
 <div style="text-align:center; max-height:100%; height:250px; vertical-align:middle;"><a href="cd-abstract.png"><img src="cd-abstract.png" height=250></img></a> **OR** <a href="cd-no-abstract.png"><img src="cd-no-abstract.png" height=220></img></a></div>
 
 - `remoteID` should be an Integer (16 is fine) and indexed.

 ## Differences from NSRRemoteObject
 
 NSRRemoteManagedObject overrides some NSRRemoteObject behavior to make it more CoreData-friendly.
 
 ### Class remote requests
 
 **All**: Each object returned in the array may be an existing or newly inserted managed object. All managed objects will reflect properties set to those returned by your server.

 **Object with ID**: If request is successful, will attempt to find an existing local object with *objectID*, and update its properties to the server's response. If it cannot find an existing local object with that remoteID, will insert a new object into the context, with those properties.

 ### Instance remote requests
 
 **Fetch**: If successful and changes are present, will save its managed object context.

 **Update/Replace**: If successful, will save its managed object context. 
 
 @warning Changes to the local object will remain even if the request was unsuccessful. It is recommended to implement an undo manager for your managed object context to rollback any changes in this case.

 **Create**: If successful, will save its managed object context to update changed properties in the server response (like remoteID).

 **Destroy**: If successful, will delete itself from its managed object context and save the context.

 ### Others
 
 **objectWithRemoteDictionary:**: Will attempt to retrieve the object in CoreData whose remoteID matches the object for key `id` in *dictionary*.
 
 - If this object is found, will set its properties using *dictionary* and save the context.
 - If this object is not found (or there's no `id` key), will create & insert a new object using *dictionary* and save the context.
 
 Will search for objects of entity named with the receiver's class name.

 **setPropertiesUsingRemoteDictionary:**: Saves the context.
 
 **remoteDestroyOnNesting**: This property leaves your managed object **unaffected**. You will have to delete it from your context manually if your request was successful.
 
 ### Overrides
 
 **relationshipForProperty:**
 
 */

@interface NSRRemoteManagedObject : NSRRemoteObject

/// =============================================================================================
/// @name CoreData Helpers
/// =============================================================================================

/**
 Finds the object in CoreData whose remoteID is equal to the value passed in.
  
 @param remoteID The remoteID to search for.
 
 @return The object from CoreData, if it exists. If it does not exist, returns `nil`.
 
 @see objectWithRemoteDictionary:
 */
+ (id) findObjectWithRemoteID:(NSNumber *)remoteID;

/**
 Instantiates a new instance, inserts it into the default CoreData context.
 
 Does not save the context.
 
 Uses the "global" context defined in the relevant config's `managedObjectContext` property. Throws an exception if this property is `nil`.
  
 @return The newly inserted object.
 */
- (id) initInserted;

/**
 Save the CoreData object context of the receiver.
  
 @return Whether or not the save was successful.
 */
- (BOOL) saveContext;


/// =============================================================================================
/// @name Methods to override
/// =============================================================================================

/**
 Override this method if the class entity name is different than the name of the class.
 
 Default behavior here is to return the name of the class.
 
 @return String (typically literal) to be used as entity name when inserting and fetching objects of this class.
 */
+ (NSString *) entityName;


@end
