//
//  NSRConfig.h
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

//  OPTIONS
// for documentation on these, see https://github.com/dingbat/nsrails/wiki/Compile-config

#define NSRAutomaticallyUnderscoreAndCamelize
#define NSRAutomaticallyMakeURLsLowercase
#define NSRLog 3
#define NSRAppendNestedModelKeyOnSend	@"_attributes"
#define NSRCompileWithARC
#define NSRSuccinctErrorMessages

//#define NSRSendHasManyRelationAsHash
//#define NSRCrashOnError



//NSRConfig

@interface NSRConfig : NSObject

@property (nonatomic, strong) NSString *appURL;
@property (nonatomic, strong) NSString *appUsername;
@property (nonatomic, strong) NSString *appPassword;

+ (NSRConfig *) defaultConfig;

- (id) initWithAppURL:(NSString *)url;

@end
