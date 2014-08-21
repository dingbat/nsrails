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

#import "NSRConfig.h"

//NSRConfigStackElement implementation

//this small helper class is used to keep track of which config is contextually relevant
//a stack is used so that -[NSRConfig use] commands can be nested
//the problem with simply adding the NSRConfig to an NSMutableArray stack is that it will act funny if it's added multiple times (since an instance can only exist once in an array) and removing is even more of a nightmare

//the stack will be comprised of this element, whose sole purpose is to point to a config, meaning it can be pushed to the stack multiple times if needed be

@interface NSRConfigStackElement : NSObject

@property (nonatomic, weak) NSRConfig *config;

@end

@implementation NSRConfigStackElement

+ (NSRConfigStackElement *) elementForConfig:(NSRConfig *)c
{
    NSRConfigStackElement *element = [[NSRConfigStackElement alloc] init];
    element.config = c;
    return element;
}

@end

NSString * const NSRRails3DateFormat =  @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
NSString * const NSRRails4DateFormat =  @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";

@interface NSRConfig ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation NSRConfig

#pragma mark -
#pragma mark Config inits

static NSRConfig *defaultConfig = nil;
static NSMutableArray *overrideConfigStack = nil;

//purely for testing purposes
+ (void) resetConfigs
{
    [overrideConfigStack removeAllObjects];
    defaultConfig = [[NSRConfig alloc] init];
}

- (void) useAsDefault
{
    defaultConfig = self;
}

+ (instancetype) defaultConfig
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        NSRConfig *newConfig = [[NSRConfig alloc] init];
        [newConfig useAsDefault];
    });

    return defaultConfig;
}

- (id) init
{
    if ((self = [super init]))
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        
        self.autoinflectsClassNames = YES;
        self.autoinflectsPropertyNames = YES;
        self.ignoresClassPrefixes = YES;
        self.networkLogging = YES;
        
        self.succinctErrorMessages = YES;
        self.timeoutInterval = 60.0f;
        self.performsCompletionBlocksOnMainThread = YES;
        
        [self configureToRailsVersion:NSRRailsVersion4];
    }
    return self;
}

- (void) configureToRailsVersion:(NSRRailsVersion)railsVersion
{
    if (railsVersion == NSRRailsVersion3)
    {
        self.dateFormat = NSRRails3DateFormat;
        self.updateMethod = @"PUT";
    }
    else if (railsVersion == NSRRailsVersion4)
    {
        self.dateFormat = NSRRails4DateFormat;
        self.updateMethod = @"PATCH";
    }
}


#pragma mark - Date Formatting

- (void) setDateFormat:(NSString *)dateFormat
{
    [self.dateFormatter setDateFormat:dateFormat];
}

- (NSString *) dateFormat
{
    return self.dateFormatter.dateFormat;
}

- (NSString *) stringFromDate:(NSDate *)date
{
    return [self.dateFormatter stringFromDate:date];
}

- (NSDate *) dateFromString:(NSString *)string
{
    NSDate *date = [self.dateFormatter dateFromString:string];
    
    if (!date && string)
    {
        NSDateFormatter *rails3Checker = [[NSDateFormatter alloc] init];
        rails3Checker.dateFormat = NSRRails3DateFormat;
        if ([rails3Checker dateFromString:string])
        {
            NSLog(@"NSR Warning: Date conversion failed. Looks like your server is running Rails version 3, but NSRConfig is not configured for this (Rails 4 is default). Try using -[NSRConfig configureToRailsVersion:] with NSRRailsVersion3.");
        }
        else
        {
            NSLog(@"NSR Warning: Attempted to convert remote date string (\"%@\") into an NSDate object, but conversion failed. Please check your config's dateFormat (used format \"%@\" for this operation). Setting to nil",string,self.dateFormat);
        }
    }
    
    return date;
}

#pragma mark -
#pragma mark Contextual stuff

+ (instancetype) contextuallyRelevantConfig
{
    //get the last config on the stack (last in first out)
    NSRConfig *override = [[overrideConfigStack lastObject] config];
    
    //if stack is nil or empty, this will be nil, signifying that there's no overriding context, so return default
    if (override) {
        return override;
    }
    
    return [self defaultConfig];
}

- (void) use
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        overrideConfigStack = [[NSMutableArray alloc] init];
    });
    
    // make a new stack element for this config (explained at top of the file) and push it to the stack
    [overrideConfigStack addObject:[NSRConfigStackElement elementForConfig:self]];
}

- (void) end
{
    //start at the end of the stack
    for (NSInteger i = overrideConfigStack.count-1; i >= 0; i--)
    {
        NSRConfigStackElement *c = overrideConfigStack[i];
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
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormat = [aDecoder decodeObjectForKey:@"dateFormat"];
        
        self.autoinflectsClassNames = [aDecoder decodeBoolForKey:@"autoinflectsClassNames"];
        self.autoinflectsPropertyNames = [aDecoder decodeBoolForKey:@"autoinflectsPropertyNames"];
        self.ignoresClassPrefixes = [aDecoder decodeBoolForKey:@"ignoresClassPrefixes"];

        self.succinctErrorMessages = [aDecoder decodeBoolForKey:@"succinctErrorMessages"];
        self.performsCompletionBlocksOnMainThread = [aDecoder decodeBoolForKey:@"performsCompletionBlocksOnMainThread"];
        self.timeoutInterval = [aDecoder decodeDoubleForKey:@"timeoutInterval"];

        self.managesNetworkActivityIndicator = [aDecoder decodeBoolForKey:@"managesNetworkActivityIndicator"];

        self.rootURL = [aDecoder decodeObjectForKey:@"rootURL"];
        self.basicAuthUsername = [aDecoder decodeObjectForKey:@"basicAuthUsername"];
        self.basicAuthPassword = [aDecoder decodeObjectForKey:@"basicAuthPassword"];
        
        self.additionalHTTPHeaders = [aDecoder decodeObjectForKey:@"additionalHTTPHeaders"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.dateFormat forKey:@"dateFormat"];

    [aCoder encodeBool:self.autoinflectsClassNames forKey:@"autoinflectsClassNames"];
    [aCoder encodeBool:self.autoinflectsPropertyNames forKey:@"autoinflectsPropertyNames"];
    [aCoder encodeBool:self.ignoresClassPrefixes forKey:@"ignoresClassPrefixes"];
    
    [aCoder encodeBool:self.succinctErrorMessages forKey:@"succinctErrorMessages"];
    [aCoder encodeBool:self.performsCompletionBlocksOnMainThread forKey:@"performsCompletionBlocksOnMainThread"];
    [aCoder encodeDouble:self.timeoutInterval forKey:@"timeoutInterval"];
    
    [aCoder encodeBool:self.managesNetworkActivityIndicator forKey:@"managesNetworkActivityIndicator"];

    [aCoder encodeObject:self.rootURL forKey:@"rootURL"];
    [aCoder encodeObject:self.basicAuthUsername forKey:@"basicAuthUsername"];
    [aCoder encodeObject:self.basicAuthPassword forKey:@"basicAuthPassword"];

    [aCoder encodeObject:self.additionalHTTPHeaders forKey:@"additionalHTTPHeaders"];
}


@end
