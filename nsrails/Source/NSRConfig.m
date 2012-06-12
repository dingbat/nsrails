/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRConfig.m
 
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

#import "NSRails.h"
#import "NSRConfig.h"

//NSRConfigStackElement implementation

//this small helper class is used to keep track of which config is contextually relevant
//a stack is used so that -[NSRConfig use] commands can be nested
//the problem with simply adding the NSRConfig to an NSMutableArray stack is that it will act funny if it's added multiple times (since an instance can only exist once in an array) and removing is even more of a nightmare

//the stack will be comprised of this element, whose sole purpose is to point to a config, meaning it can be pushed to the stack multiple times if needed be

@interface NSRConfigStackElement : NSObject

@property (nonatomic, assign) NSRConfig *config;

@end

@implementation NSRConfigStackElement
@synthesize config;

+ (NSRConfigStackElement *) elementForConfig:(NSRConfig *)c
{
	NSRConfigStackElement *element = [[NSRConfigStackElement alloc] init];
	element.config = c;
	return element;
}

@end


@interface NSRRemoteObject (internal)

+ (NSRPropertyCollection *) propertyCollection;

@end


//Environments
NSString * const NSRConfigEnvironmentDevelopment		= @"com.nsrails.NSRConfigEnvironmentDevelopment";
NSString * const NSRConfigEnvironmentProduction			= @"com.nsrails.NSRConfigEnvironmentProduction";


NSString * const NSRValidationErrorsKey					= @"NSRValidationErrorsKey";

NSString * const NSRRemoteErrorDomain				= @"NSRRemoteErrorDomain";
NSString * const NSRMapException					= @"NSRMapException";
NSString * const NSRJSONParsingException			= @"NSRJSONParsingException";
NSString * const NSRInternalError					= @"NSRInternalError";
NSString * const NSRMissingURLException				= @"NSRMissingURLException";
NSString * const NSRNullRemoteIDException			= @"NSRNullRemoteIDException";
NSString * const NSRCoreDataException				= @"NSRCoreDataException";


@implementation NSRConfig
@synthesize appURL, appUsername, appPassword, appOAuthToken;
@synthesize autoinflectsClassNames, autoinflectsPropertyNames, managesNetworkActivityIndicator, timeoutInterval, ignoresClassPrefixes, succinctErrorMessages, performsCompletionBlocksOnMainThread, managedObjectContext, updateMethod;
@dynamic dateFormat;

#pragma mark -
#pragma mark Config inits

static NSMutableDictionary *configEnvironments = nil;
static NSMutableArray *overrideConfigStack = nil;
static NSString *currentEnvironment = nil;

//purely for test purposes
+ (void) resetConfigs
{
	[configEnvironments removeAllObjects];
	[overrideConfigStack removeAllObjects];
	currentEnvironment = NSRConfigEnvironmentDevelopment;
}

+ (NSRConfig *) configForEnvironment:(NSString *)environment
{
	NSRConfig *config = [configEnvironments objectForKey:environment];
	if (!config)
	{
		config = [[NSRConfig alloc] init];
		[config useAsDefaultForEnvironment:environment];
	}
	return config;
}

+ (NSString *) environmentKeyForClass:(Class)class
{
	return [NSString stringWithFormat:@"com.nsrails.class.%@",class];
}

+ (NSRConfig *) relevantConfigForClass:(Class)class
{
	if ([self overrideConfig])
		return [self overrideConfig];
	
	if ([configEnvironments objectForKey:[self environmentKeyForClass:class]])
		return [self configForEnvironment:[self environmentKeyForClass:class]];

	return [self defaultConfig];
}

+ (NSRConfig *) defaultConfig
{
	return [self configForEnvironment:[self currentEnvironment]];
}

- (void) useAsDefaultForEnvironment:(NSString *)environment
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		configEnvironments = [[NSMutableDictionary alloc] init];
	});
	
	[configEnvironments setObject:self forKey:environment];
}

- (void) useAsDefault
{
	[self useAsDefaultForEnvironment:[[self class] currentEnvironment]];
}

- (void) useForClass:(Class)class
{
	[self useAsDefaultForEnvironment:[self.class environmentKeyForClass:class]];
}

+ (void) setCurrentEnvironment:(NSString *)environment
{
	if (!environment)
		return;
	currentEnvironment = environment;
}

+ (NSString *) currentEnvironment
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		currentEnvironment = NSRConfigEnvironmentDevelopment;
	});
	return currentEnvironment;
}

- (id) init
{
	if ((self = [super init]))
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		
		//by default, set to accept datestring like "2012-02-01T00:56:24Z"
		//this format (ISO 8601) is default in rails
		self.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
		
		self.autoinflectsClassNames = YES;
		self.autoinflectsPropertyNames = YES;
		self.ignoresClassPrefixes = YES;
		
		self.succinctErrorMessages = YES;
		self.timeoutInterval = 60.0f;
		self.performsCompletionBlocksOnMainThread = YES;
		
		//by default, use PUT for updates
		self.updateMethod = @"PUT";
		
		asyncOperationQueue = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (id) initWithAppURL:(NSString *)url
{
	if ((self = [self init]))
	{		
		[self setAppURL:url];
	}
	return self;
}


#pragma mark - Date Formatting

- (void) setDateFormat:(NSString *)dateFormat
{
	[dateFormatter setDateFormat:dateFormat];
}

- (NSString *) dateFormat
{
	return dateFormatter.dateFormat;
}

- (NSString *) stringFromDate:(NSDate *)date
{
	return [dateFormatter stringFromDate:date];
}

- (NSDate *) dateFromString:(NSString *)string
{
	NSDate *date = [dateFormatter dateFromString:string];
	
	if (!date && string)
	{
		[NSException raise:NSRInternalError format:@"Attempted to convert remote date string (\"%@\") into an NSDate object, but conversion failed. Please check your config's dateFormat (used format \"%@\" for this operation).",string,dateFormatter.dateFormat];
		return nil;
	}
	
	return date;
}

#pragma mark -
#pragma mark Contextual stuff

+ (NSRConfig *) overrideConfig
{
	//return the last config on the stack (last in first out)
	//if stack is nil or empty, this will be nil, signifying that there's no overriding context
	
	return [[overrideConfigStack lastObject] config];
}

- (void) use
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		overrideConfigStack = [[NSMutableArray alloc] init];
	});
	
	// make a new stack element for this config (explained at top of the file) and push it to the stack

	NSRConfigStackElement *c = [NSRConfigStackElement elementForConfig:self];
	[overrideConfigStack addObject:c];
}

- (void) end
{
	//start at the end of the stack
	for (NSInteger i = overrideConfigStack.count-1; i >= 0; i--)
	{
		NSRConfigStackElement *c = [overrideConfigStack objectAtIndex:i];
		if (c.config == self)
		{
			[overrideConfigStack removeObjectAtIndex:i];
			break;
		}
	}
}

- (void) useIn:(void (^)(void))block
{
	[self use];
	block();
	[self end];
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		asyncOperationQueue = [[NSOperationQueue alloc] init];
		
		self.dateFormat = [aDecoder decodeObjectForKey:@"dateFormat"];
		
		self.autoinflectsClassNames = [aDecoder decodeBoolForKey:@"autoinflectsClassNames"];
		self.autoinflectsPropertyNames = [aDecoder decodeBoolForKey:@"autoinflectsPropertyNames"];
		self.ignoresClassPrefixes = [aDecoder decodeBoolForKey:@"ignoresClassPrefixes"];

		self.succinctErrorMessages = [aDecoder decodeBoolForKey:@"succinctErrorMessages"];
		self.performsCompletionBlocksOnMainThread = [aDecoder decodeBoolForKey:@"performsCompletionBlocksOnMainThread"];
		self.timeoutInterval = [aDecoder decodeDoubleForKey:@"timeoutInterval"];

		self.managesNetworkActivityIndicator = [aDecoder decodeBoolForKey:@"managesNetworkActivityIndicator"];

		self.appURL = [aDecoder decodeObjectForKey:@"appURL"];
		self.appUsername = [aDecoder decodeObjectForKey:@"appUsername"];
		self.appPassword = [aDecoder decodeObjectForKey:@"appPassword"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.dateFormat forKey:@"dateFormat"];

	[aCoder encodeBool:autoinflectsClassNames forKey:@"autoinflectsClassNames"];
	[aCoder encodeBool:autoinflectsPropertyNames forKey:@"autoinflectsPropertyNames"];
	[aCoder encodeBool:ignoresClassPrefixes forKey:@"ignoresClassPrefixes"];
	
	[aCoder encodeBool:succinctErrorMessages forKey:@"succinctErrorMessages"];
	[aCoder encodeBool:performsCompletionBlocksOnMainThread forKey:@"performsCompletionBlocksOnMainThread"];
	[aCoder encodeDouble:timeoutInterval forKey:@"timeoutInterval"];
	
	[aCoder encodeBool:managesNetworkActivityIndicator forKey:@"managesNetworkActivityIndicator"];
	
	[aCoder encodeObject:self.appURL forKey:@"appURL"];
	[aCoder encodeObject:self.appUsername forKey:@"appUsername"];
	[aCoder encodeObject:self.appPassword forKey:@"appPassword"];
}


@end
