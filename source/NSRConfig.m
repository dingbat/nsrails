//
//  NSRConfig.m
//  NSRails
//
//  Created by Dan Hassin on 1/28/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRConfig.h"


//this small helper class is used to keep track of which config is contextually relevant
//a stack is used so that -[NSRConfig use] commands can be nested
//the problem with simply adding the NSRConfig to the stack is that the NSMutableArray will act funny if it's added multiple times (since an instance can only exist once in an array) and removing is even more of a nightmare
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

@implementation NSRConfig
@synthesize appURL, appUsername, appPassword;

static NSRConfig *defaultConfig = nil;
static NSMutableArray *overrideConfigStack = nil;

+ (NSRConfig *) defaultConfig
{
	//singleton
	
	if (!defaultConfig) defaultConfig = [[NSRConfig alloc] init];
	return defaultConfig;
}

- (id) initWithAppURL:(NSString *)url
{
	if ((self = [super init]))
	{
		[self setAppURL:url];
	}
	return self;
}

- (void) setAppURL:(NSString *)str
{
	//get rid of trailing /
	if ([[str substringFromIndex:str.length-1] isEqualToString:@"/"])
		str = [str substringToIndex:str.length-1];
	
	//add http:// if not included already
	NSString *http = (str.length < 7 ? nil : [str substringToIndex:7]);
	if (![http isEqualToString:@"http://"] && ![http isEqualToString:@"https:/"])
	{
		str = [@"http://" stringByAppendingString:str];
	}
	
	appURL = str;
}

#pragma mark Contextual stuff

+ (NSRConfig *) overrideConfig
{
	//return the last config on the stack
	//if stack is nil or empty, this will be nil, signifying that there's no overriding context
	
	return [[overrideConfigStack lastObject] config];
}

- (void) use
{
	//this will signal the beginning of a config context block
	//if the stack doesn't exist yet, create it.
	
	if (!overrideConfigStack)
		overrideConfigStack = [[NSMutableArray alloc] init];
	
	// make a new stack element for this config (explained above)
	NSRConfigStackElement *c = [NSRConfigStackElement elementForConfig:self];
	
	//push to the "stack"
	[overrideConfigStack addObject:c];
}

- (void) end
{
	//start at the end of the stack
	for (int i = overrideConfigStack.count-1; i >= 0; i--)
	{
		//see if any element matches this config
		NSRConfigStackElement *c = [overrideConfigStack objectAtIndex:i];
		if (c.config == self)
		{
			//remove it
			[overrideConfigStack removeObjectAtIndex:i];
			break;
		}
	}
}

- (void) useFor:(void (^)(void))block
{
	//self-explanatory
	
	[self use];
	block();
	[self end];
}

@end
