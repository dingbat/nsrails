//
//  NSRConfig.h
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

//TODO
// 1. documentation+screencast
// 2. tests


//  OPTIONS

#define NSRAppendNestedModelKeyOnSend	@"_attributes"
#define NSRAutomaticallyUnderscoreAndCamelize
#define NSRAutomaticallyMakeURLsLowercase
#define NSRLog 3
#define NSRSuccinctErrorMessages
//#define NSRSendHasManyRelationAsHash
//#define NSRCrashOnError

#define NSRCompileWithARC

@interface NSRConfig : NSObject

@property (nonatomic, strong) NSString *appURL;
@property (nonatomic, strong) NSString *appUsername;
@property (nonatomic, strong) NSString *appPassword;

+ (NSRConfig *) defaultConfig;

@end


// NSRAppendRelatedModelKeyOnSend
// eg, if a user has_many classes, will send "user"=>{"key":"val","classes_attributes"=>[...]}
// typically not changed; "_attributes" is default in rails

// NSRAutomaticallyUnderscoreAndCamelize
// when defined: eg, "myProperty" as obj-c ivar will change to "my_property" when sending/receiving from server
//					what this really means is that by default all properties will have equivalencies with their underscored version
// when undefined: both properties (defined in NSRailsUse) and class names are expected to be identically formatted on server-side.

// NSRAutomaticallyMakeURLsLowercase
// when defined: before making a request, downcases entire URL
// when undefined: URL will keep any uppercase things (note: underscoring automatically downcases, so this will only be relevent without automatic underscoring)

// NSRLog
// when undefined: NSR will only log internal errors
// when defined as 1: NSR will log HTTP verbs with URLs and any server errors
// when defined as 2: NSR will also log any request body going out and data coming in.
// when defined as 3: NSR will also log internal tips/warnings.

// NSRSendHasManyRelationAsHash
// when defined: an object with a has_many will send those objects in a hash following: {"0"=>{"key":"val"}, "1"=>{"key":"val"}} 
// when undefined: an object with a has_many will send those objects in an array [{"key":"val"}, {"key":"val"}]
// irrelevant for rails.

