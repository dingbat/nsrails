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
 # Setting up
 
 ### You can either:
 
 - Go into **`NSRails.h`** and uncomment this line:
 
        #define NSR_USE_COREDATA
 
 - OR, if you don't want to mess with NSRails source, you can also add **`NSR_USE_COREDATA`** to "Preprocessor Macros Not Used in Precompiled Headers" in your target's build settings:
 
 
 <div style="text-align:center"><a href="../docs/img/cd-flag.png"><img src="../docs/img/cd-flag.png" width=380></img></a></div>
 
 ### Why is this necessary?
 
 - By default, NSRRemoteObject inherits from NSObject. Because your managed, NSRails-enabled class need to inherit from NSManagedObject in order to function within CoreData, and because Objective-C does not allow multiple inheritance, NSRRemoteObject will modify its superclass to NSManagedObject during compile-time if `NSR_USE_COREDATA` is defined.
 
 # Setting a universal context
 
 - You must set your managed object context to your config's managedObjectContext property so that NSRails can automatically insert or search for CoreData objects when operations require it:
 
        [[NSRConfig defaultConfig] setManagedObjectContext:<#your MOC#>];
 
 # Remote ID
 
 - `remoteID` is used as a "primary key" that NSRails will use to find other instances, etc. This key also validates uniqueness, meaning saving a context with two records of the same type with the same remoteID will fail.
 
 - `remoteID` must be defined in your *.xcdatamodeld data model file. You should create an abstract entity that defines a `remoteID` attribute (Integer 16 is fine) and acts as a parent to your other entities:
 
 <div style="text-align:center; vertical-align:middle;"><a href="../docs/img/cd-abstract.png"><img src="../docs/img/cd-abstract.png"></img></a></div>
 
 ## Differences from NSRRemoteObject
 
 NSRRemoteManagedObject overrides some NSRRemoteObject behavior to make it more CoreData-friendly.
 
 # Remote requests
 
 ### Class
 
 **Remote All (index)**: Each object returned in the array may be an existing or newly inserted managed object. All managed objects will reflect properties set to those returned by your server. Does not save the context.

 **Object with ID**: If request is successful, will attempt to find an existing local object with *objectID*, and update its properties to the server's response. If it cannot find an existing local object with that remoteID, will insert a new object into the context, with those properties. Does not save the context.

 ### Instance
 
 **Fetch**: If successful and changes are present, will save its managed object context.

 **Create**: If successful, will save its managed object context to update changed properties in the server response (like remoteID).

 **Destroy**: If successful, will delete itself from its managed object context and save the context.

 **Update/Replace**: If successful, will save its managed object context. *Note:* Changes to the local object will remain even if the request was unsuccessful. It is recommended to implement an undo manager for your managed object context to rollback any changes in this case.

 # Others
 
 **objectWithRemoteDictionary**: Will attempt to retrieve the object in CoreData whose remoteID matches the object for key `id` in *dictionary*.
 
 - If this object is found, will set its properties using *dictionary*.
 - If this object is not found (or there's no `id` key), will create & insert a new object using *dictionary*.
 
 Does not save the context.
 
 **remoteDestroyOnNesting**: This property leaves your managed object **unaffected**. You will have to delete it from your context manually if your request was successful.
 
 **nestedClassForProperty:** Will search your CoreData entity relationships, and if one is found for that property, will return that relationship's destination class.
 */

@interface NSRRemoteManagedObject : NSRRemoteObject

/// =============================================================================================
/// @name CoreData Helpers
/// =============================================================================================

/**
 Finds the object in CoreData whose remoteID is equal to the value passed in.
  
 @param remoteID The remoteID to search for.
 
 @return The object from CoreData, if it exists. If it does not exist, returns `nil`.
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

/**
 Override this method only if you wish to disable `remoteID` uniqueness validation.
 
 Unfortunately CoreData does not offer a good way to validate on uniqueness (on the DB level). When enabled and an object is inserted, NSRails will make a fetch request for any other managed objects with the inserted object's `remoteID`. This may take time depending on the amount of records you have.
 
 @return `NO` if you do not wish to validate `remoteID` uniqueness. You should not override this method otherwise.
 */
- (BOOL) validatesRemoteIDUniqueness;


@end
