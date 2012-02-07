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



#define NSRValidationErrorsKey	@"validation errors"

//NSRConfig

@interface NSRConfig : NSObject
{
	NSOperationQueue *asyncOperationQueue; //used for async requests
}

@property (nonatomic, strong) NSString *appURL;
@property (nonatomic, strong) NSString *appUsername;
@property (nonatomic, strong) NSString *appPassword;

+ (NSRConfig *) defaultConfig;
+ (void) setDefaultConfig:(NSRConfig *)config;

- (id) initWithAppURL:(NSString *)url;

- (void) use;
- (void) end;

- (void) useIn:(void(^)(void))block;

//HTTP stuff

- (NSString *) makeRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(void(^)(NSString *result, NSError *error))completionBlock;
+ (void) crashWithError:(NSError *)error;

@end