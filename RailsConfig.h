//
//  RailsConfig.h
//  RailsTest
//
//  Created by Dan Hassin on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


//  OPTIONS


#define RMAppendRelatedModelKeyOnSend	@"_attributes"
#define RMAutomaticallyUnderscoreAndCamelize
#define RMAutomaticallyMakeURLsLowercase
#define RMLog 2
#define RMSendNilValues
//#define RMSendHasManyRelationAsHash


// RMAppendRelatedModelKeyOnSend
// eg, if a user has_many classes, will send "user"=>{"key":"val","classes_attributes"=>[...]}
// typically not changed; "_attributes" is default in rails

// RMAutomaticallyUnderscoreAndCamelize
// when defined: eg, "myProperty" as obj-c ivar will change to "my_property" when sending/receiving from server
//					what this really means is that by default all properties will have equivalencies with their underscored version
// when undefined: both properties (defined in MakeRails) and class names are expected to be identically formatted on server-side.

// RMAutomaticallyMakeURLsLowercase
// when defined: before making a request, downcases entire URL
// when undefined: URL will keep any uppercase things (note: underscoring automatically downcases, so this will only be relevent without automatic underscoring)

// RMLog
// when undefined: RM will only log internal errors
// when defined as 1: RM will log HTTP verbs with URLs and any server errors
// when defined as 2: RM will also log any request body going out and data coming in.

// RMSendNilValues
// when defined: if a property is nil, will send 'null' in request bodies. (does not include null id's)
// when undefined: the key will simply be absent from request body

// RMSendHasManyRelationAsHash
// when defined: an object with a has_many will send those objects in a hash following: {"0"=>{"key":"val"}, "1"=>{"key":"val"}} 
// when undefined: an object with a has_many will send those objects in an array [{"key":"val"}, {"key":"val"}]
// irrelevant for rails.

