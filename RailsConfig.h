//
//  RailsConfig.h
//  RailsTest
//
//  Created by Dan Hassin on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//TODO
// 1. on update/create, if no ID, send back error with "nil ID" instead of simply logging
// 2. synchronous HTTP calls (see how ASIHTTP does blocks - must be done in blocks
// 3. documentation+screencast
// 4. tests


//  OPTIONS


#define RMAppendRelatedModelKeyOnSend	@"_attributes"
#define RMAutomaticallyUnderscoreAndCamelize
#define RMAutomaticallyMakeURLsLowercase
#define RMLog 3
//#define RMSendHasManyRelationAsHash
//#define RMCrashOnError
#define RMSuccinctErrorMessages

#define RMCompileWithARC


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
// when defined as 3: RM will also log internal tips/warnings.

// RMSendHasManyRelationAsHash
// when defined: an object with a has_many will send those objects in a hash following: {"0"=>{"key":"val"}, "1"=>{"key":"val"}} 
// when undefined: an object with a has_many will send those objects in an array [{"key":"val"}, {"key":"val"}]
// irrelevant for rails.

