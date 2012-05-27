/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRails.m
 
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

#import "NSRPropertyCollection.h"
#import "NSRConfig.h"

#import "NSString+Inflection.h"
#import "NSData+Additions.h"
#import "NSObject+Properties.h"

/* 
    If this file is too intimidating, 
 remember that you can navigate it
 quickly in Xcode using #pragma marks.
								    	*/

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface NSRRemoteObject (internal)

+ (NSRConfig *) getRelevantConfig;
- (NSRConfig *) getRelevantConfig;

+ (NSRPropertyCollection *) propertyCollection;
- (NSRPropertyCollection *) propertyCollection;

- (NSManagedObjectContext *) managedObjectContext;

@end

@interface NSRConfig (override)

+ (NSRConfig *) overrideConfig;

@end

///////////////////////////////////

//Quick NSDate category

@implementation NSDate (NSRApproximation)

- (BOOL) significantChangeSinceDate:(NSDate *)date
{
	if (!date) return YES;
	
	NSTimeInterval diff = [self timeIntervalSinceDate:date];
	return (fabs(diff) > 1.25);
}

@end

///////////////////////////////////

//Quick NSObject category to "pose" as NSManagedObject

@interface NSObject (NSRCoreData)

- (id) managedObjectContext;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

#define CD_SELF	(id)self

@implementation NSRRemoteObject
@synthesize remoteID, remoteDestroyOnNesting, remoteAttributes;

- (NSManagedObjectContext *) managedObjectContext
{
	if ([self isKindOfClass:[NSManagedObject class]])
		return [super managedObjectContext];
	
	return nil;
}


#pragma mark - Meta-NSR stuff

//this will suppress the compiler warnings that come with ARC when doing performSelector
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


// Use default config + model name by default
NSRUseDefaultModelName;
NSRUseDefaultConfig;

// If NSRMap isn't overriden (ie, if NSRMap() macro is not declared in subclass), default to *
NSRMap(*);

//returns the sync string expanded (* => all properties) & inherited (adds NSRMaps from superclasses)
//override string is in case there's a custom sync string defined
+ (NSString *) masterNSRMapWithOverrideString:(NSString *)override
{
	//base case
	if (self == [NSRRemoteObject class])
		return @"remoteID=id";
	
	NSString *syncStr = (override ? override : [self NSRMap]);	
	if ([syncStr rangeOfString:@"*"].location != NSNotFound)
	{
		syncStr = [syncStr stringByReplacingOccurrencesOfString:@"*" withString:@""];

		//expand the star to everything in the class
		NSString *expanded = [self.allProperties componentsJoinedByString:@", "];
		if (expanded)
		{
			//properties need to be appended to existing sync string since they can be overridden like with -x (and stripped of *)
			syncStr = [syncStr stringByAppendingFormat:@", %@", expanded];
		}
	}
	
	if ([syncStr rangeOfString:_NSRNoCarryFromSuper_STR].location != NSNotFound)
	{
		syncStr = [syncStr stringByReplacingOccurrencesOfString:_NSRNoCarryFromSuper_STR withString:@""];

		//skip right up the hierarchy to NSRRemoteObject
		return [syncStr stringByAppendingFormat:@", %@", [NSRRemoteObject masterNSRMapWithOverrideString:nil]];
	}
	
	//traverse up the hierarchy (always getting the default NSRMap)
	return [syncStr stringByAppendingFormat:@", %@", [self.superclass masterNSRMapWithOverrideString:nil]];
}

+ (NSString *) masterNSRMap
{
	return [self masterNSRMapWithOverrideString:nil];
}

+ (NSRConfig *) masterClassConfig
{
	//check for a custom config for the class
	
	NSString *url = [self NSRUseConfigURL];
	if (url)
	{
		NSRConfig *custom = [[NSRConfig alloc] initWithAppURL:url];
		custom.appUsername = [self NSRUseConfigUsername];
		custom.appPassword = [self NSRUseConfigPassword];
		
		return custom;
	}
	
	return nil;
}

+ (NSString *) masterModelName
{
	if (self == [NSRRemoteObject class])
		return nil;
	
	NSString *defined = [self NSRUseModelName];
	if (defined)
		return defined;
	
	//otherwise, return name of the class
	NSString *class = NSStringFromClass(self);
	
	if ([self getRelevantConfig].autoinflectsClassNames)
	{
		return [class underscoreIgnorePrefix:[self getRelevantConfig].ignoresClassPrefixes];
	}
	else
	{
		return class;
	}
}

+ (NSString *) masterPluralName
{
	NSString *defined = [self NSRUsePluralName];
	if (defined)
		return defined;

	//otherwise, pluralize ModelName
	return [[self masterModelName] pluralize];
}

+ (NSRPropertyCollection *) propertyCollection
{
	static NSMutableDictionary *propertyCollections = nil;
	static dispatch_once_t onceToken;
	
	//singleton initializer
    dispatch_once(&onceToken, ^{
		propertyCollections = [[NSMutableDictionary alloc] init];
    });
		
	NSString *class = NSStringFromClass(self);
	NSRPropertyCollection *collection = [propertyCollections objectForKey:class];
	if (!collection)
	{
		collection = [[NSRPropertyCollection alloc] initWithClass:self 
													   syncString:[self masterNSRMap] 
													 customConfig:[self masterClassConfig]];
		
		[propertyCollections setObject:collection forKey:class];
	}
	
	return collection;
}

- (NSRPropertyCollection *) propertyCollection
{
	if (customProperties)
		return customProperties;
	
	return [[self class] propertyCollection];
}

+ (NSRConfig *) getRelevantConfigFromPropertyCollection:(NSRPropertyCollection *)propertyCollection
{	
	//if there's an overriding config in this context (an -[NSRConfig use] was called (explicitly or implicity via a block))
	if ([NSRConfig overrideConfig])
	{
		return [NSRConfig overrideConfig];
	}
	
	//if this class/instance defines NSRUseConfig, use it over the default
	else if (propertyCollection.customConfig)
	{
		return propertyCollection.customConfig;
	}
	
	//otherwise, use the default config
	else
	{
		return [NSRConfig defaultConfig];
	}
}

+ (NSRConfig *) getRelevantConfig
{
	return [self getRelevantConfigFromPropertyCollection:[self propertyCollection]];
}

- (NSRConfig *) getRelevantConfig
{
	if (!customProperties)
		return [[self class] getRelevantConfig];
	
	return [[self class] getRelevantConfigFromPropertyCollection:customProperties];
}


- (id) initWithCustomMap:(NSString *)str customConfig:(NSRConfig *)config
{
	NSRConfig *relevantConfig;
	if (config)
		relevantConfig = config;
	else
		relevantConfig = [[self class] getRelevantConfig];
	
	if (relevantConfig.managedObjectContext)
	{
		NSEntityDescription *desc = [NSEntityDescription entityForName:[[self class] description] 
												inManagedObjectContext:relevantConfig.managedObjectContext];
		
		self = [CD_SELF initWithEntity:desc insertIntoManagedObjectContext:relevantConfig.managedObjectContext];
	}
	else
	{
		self = [super init];
	}
	
	if (self)
	{
		//apply inheritance rules etc to the given string
		str = [[self class] masterNSRMapWithOverrideString:str];
		
		customProperties = [[NSRPropertyCollection alloc] initWithClass:[self class] 
															 syncString:str 
														   customConfig:config];
	}
	return self;
}

- (id) initWithCustomMap:(NSString *)str
{
	self = [self initWithCustomMap:str customConfig:nil];
	return self;
}



#pragma mark - Internal NSR stuff

// Encode/decode date objects by default (will be used as en/de coders if they aren't declared)
- (NSString *) nsrails_encodeDate:(NSDate *)date
{
	return [[self getRelevantConfig] stringFromDate:date];
}

- (NSDate *) nsrails_decodeDate:(NSString *)dateRep
{
	return [[self getRelevantConfig] dateFromString:dateRep];
}

// Helper method used when mapping nested properties to JSON
- (NSRRemoteObject *) makeRelevantModelFromClass:(NSString *)classN basedOn:(NSDictionary *)dict
{
	Class objClass = NSClassFromString(classN);
	NSRRemoteObject *obj = [objClass findAndUpdateExistingObjectOrCreateObjectUsingRemoteDictionary:dict];
	
	//see if we can assign an association to its parent (self)
	NSString *parentModelName = [[self class] masterModelName];
	NSArray *properties = [[obj propertyCollection] objcPropertiesForRemoteEquivalent:parentModelName 
																		  autoinflect:[self getRelevantConfig].autoinflectsPropertyNames];
	
	for (NSRProperty *property in properties)
	{
		//only assign me to the child if it has me defined as a property and it's marked as nested to me
		if (property.retrievable &&
			[property.nestedClass isEqualToString:[self.class description]])
		{
			SEL setter = [objClass setterForProperty:property.name];
			[obj performSelector:setter withObject:self];
		}
	}
	
	return obj;
}

- (id) remoteRepresentationOfObjectForProperty:(NSRProperty *)prop
{
	SEL encoder = NULL;
	if (prop.encodable)
	{
		NSString *encodeMethod = [NSString stringWithFormat:@"encode%@", [prop.name firstLetterCapital]];
		
		//support encode methods being written with a parameter of obj being encoded
		NSString *withObject = [encodeMethod stringByAppendingString:@":"];
		if ([self respondsToSelector:NSSelectorFromString(withObject)])
			encoder = NSSelectorFromString(withObject);
		else
			encoder = NSSelectorFromString(encodeMethod);
	}
	else if (prop.isDate && !prop.isArray)
	{
		encoder = @selector(nsrails_encodeDate:);
	}
	
	SEL getter = [self.class getterForProperty:prop.name];

	if (encoder)
	{
		id obj = [self respondsToSelector:getter] ? [self performSelector:getter] : nil;
		
		//perform selector with the object itself in case it takes it
		id representation = [self performSelector:encoder withObject:obj];

		//send back an NSNull object instead of nil since we'll be encoding it into JSON, where that's relevant
		if (!representation)
		{
			return [NSNull null];
		}
		
		BOOL JSONParsable = ([representation isKindOfClass:[NSArray class]] ||
							 [representation isKindOfClass:[NSDictionary class]] ||
							 [representation isKindOfClass:[NSString class]] ||
							 [representation isKindOfClass:[NSNumber class]] ||
							 [representation isKindOfClass:[NSNull class]]);
		
		if (!JSONParsable)
		{
			[NSException raise:NSRJSONParsingException format:@"Trying to encode property '%@' in class '%@', but the result from %@ was not JSON-parsable. Please make sure you return NSDictionary, NSArray, NSString, NSNumber, or NSNull here. Remember, these are the values you want to send in the JSON to Rails. Also, defining this encoder method will override the automatic NSDate translation.",prop.name, NSStringFromClass([self class]),NSStringFromSelector(encoder)];
			return nil;
		}
		
		return representation;
	}
	else
	{
		id val = [self performSelector:getter];
		BOOL isArray = [val isKindOfClass:[NSArray class]];
		
		if (prop.nestedClass || prop.isArray)
		{
			//if the ivar is an array, we need to make every element into JSON and then put them back in the array
			if (isArray)
			{
				NSMutableArray *new = [NSMutableArray arrayWithCapacity:[val count]];
				
				for (int i = 0; i < [val count]; i++)
				{
					id element = [val objectAtIndex:i];
					
					id encodedObj = element;
					
					//if it's an NSRRemoteObject, we can use its dictionaryOfRemoteProperties
					if ([element isKindOfClass:[NSRRemoteObject class]])
					{
						encodedObj = [element dictionaryOfRemotePropertiesFromNesting:YES];
					}
					else if ([element isKindOfClass:[NSDate class]])
					{
						encodedObj = [self nsrails_encodeDate:element];
					}
					
					[new addObject:encodedObj];
				}
				return new;
			}
			
			//otherwise, if it's not array but nested, make the nested object a dictionary
			if (![val isKindOfClass:[NSRRemoteObject class]])
				return nil;
			
			//if it's belongs_to, we're only returning ID
			if (prop.isBelongsTo)
				return [val remoteID];
			
			return [val dictionaryOfRemotePropertiesFromNesting:YES];
		}
				
		//otherwise, just return the value from the get method
		return val;
	}
}

- (id) initWithRemoteDictionary:(NSDictionary *)railsDict
{
	NSManagedObjectContext *ctx = [[self class] getRelevantConfig].managedObjectContext;
	
	if (ctx)
	{
		NSEntityDescription *desc = [NSEntityDescription entityForName:[[self class] description] 
												inManagedObjectContext:ctx];
		
		self = [CD_SELF initWithEntity:desc insertIntoManagedObjectContext:ctx];
		
		//don't need to save context because the setPropertiesUsingRemoteDictionary: will do it anyway
	}
	else
	{
		self = [super init];
	}

	
	if (self)
	{
		[self setPropertiesUsingRemoteDictionary:railsDict applyToRemoteAttributes:YES];
	}
	
	return self;
}

- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict applyToRemoteAttributes:(BOOL)remote
{
	remoteAttributes = dict;
	
	//support JSON that comes in like {"post"=>{"something":"something"}}
	NSDictionary *innerDict = [dict objectForKey:[[self class] masterModelName]];
	if (dict.count == 1 && [innerDict isKindOfClass:[NSDictionary class]])
	{
		dict = innerDict;
	}
	
	BOOL changes = NO;
	
	for (NSString *railsProperty in dict)
	{
		NSArray *equivalents = [[self propertyCollection] objcPropertiesForRemoteEquivalent:railsProperty 
																				autoinflect:[self getRelevantConfig].autoinflectsPropertyNames];
		
		//loop through just in case there are multiple objcProps set to retrieve same remoteEquiv
		for (NSRProperty *property in equivalents)
		{
			if (!property.retrievable)
				continue;
			
			id railsObject = [dict objectForKey:railsProperty];
			if (railsObject == [NSNull null])
				railsObject = nil;
			
			SEL getter = [[self class] getterForProperty:property.name];
			SEL setter = [[self class] setterForProperty:property.name];
			
			id previousVal = [self performSelector:getter];
			
			SEL customDecode = NULL;
			if (property.decodable)
			{
				customDecode = NSSelectorFromString([NSString stringWithFormat:@"decode%@:",[property.name firstLetterCapital]]);
			}
			else if (property.isDate && !property.isArray)
			{
				customDecode = @selector(nsrails_decodeDate:);
			}
			
			BOOL checkForPlainEquality = NO;
			
			id decodedObj = nil;
			if (customDecode)
			{
				decodedObj = [self performSelector:customDecode withObject:railsObject];
				checkForPlainEquality = YES;
			}
			else	
			{
				if (railsObject)
				{
					//custom-encode if it's a datearray or if it's an array of nested classes
					if (property.isHasMany || (property.isDate && property.isArray))
					{
						if (![railsObject isKindOfClass:[NSArray class]])
							[NSException raise:NSRInternalError format:@"Attempt to set property '%@' in class '%@' (declared as array) to a non-array non-null value ('%@').", property, self.class, railsObject];

						BOOL checkForChange = !changes && ([railsObject count] == [previousVal count]);
						if (!checkForChange)
							changes = YES;

						NSMutableArray *newArray = [[NSMutableArray alloc] init];

						if (property.nestedClass)
						{							
							//array of NSRRemoteObjects is tricky, we need to go through each existing element, see if it needs an update (or delete), and then add any new ones
							
							for (id railsElement in railsObject)
							{
								id decodedElement;
								
								//see if there's a nester that matches this ID - we'd just have to update it w/this dict
								NSUInteger idx = [previousVal indexOfObjectPassingTest:
												  ^BOOL(NSRRemoteObject *obj, NSUInteger idx, BOOL *stop) 
												  {
													  if ([obj.remoteID isEqualToNumber:[railsElement objectForKey:@"id"]])
													  {
														  if (stop)
															  *stop = YES;
														  return YES;
													  }
													  return NO;
												  }];
								
								if (!previousVal || idx == NSNotFound)
								{
									//didn't previously exist - make a new one
									decodedElement = [self makeRelevantModelFromClass:property.nestedClass basedOn:railsElement];
									
									changes = YES;
								}
								else
								{
									//existed - simply update that one (recursively)
									decodedElement = [previousVal objectAtIndex:idx];
									BOOL neededChange = [decodedElement setPropertiesUsingRemoteDictionary:railsElement applyToRemoteAttributes:YES];
									
									if (neededChange)
										changes = YES;
								}

								
								[newArray addObject:decodedElement];
							}
						}
						else if (property.isDate)
						{
							//array of NSDates
							for (int i = 0; i < [railsObject count]; i++)
							{
								id railsElement = [railsObject objectAtIndex:i];
								NSDate *newDate = [self nsrails_decodeDate:railsElement];
								[newArray addObject:newDate];
								
								if (checkForChange && !changes)
								{
									NSDate *oldDate = [previousVal objectAtIndex:i];
									
									if ([newDate significantChangeSinceDate:oldDate])
										changes = YES;
								}
							}
						}
						decodedObj = newArray;
					}
					else if (property.nestedClass)
					{
						//if the nested object didn't exist before, make it & set it
						if (!previousVal)
						{
							decodedObj = [self makeRelevantModelFromClass:property.nestedClass basedOn:railsObject];
							
							changes = YES;
						}
						//otherwise, keep the old object & only mark as change if its properties changed (recursive)
						else
						{
							decodedObj = previousVal;
							
							BOOL objChange = [decodedObj setPropertiesUsingRemoteDictionary:railsObject applyToRemoteAttributes:YES];
							if (objChange)
								changes = YES;
						}
					}
					//otherwise, if not nested or anything, just use what we got (number, string, dictionary, array)
					else
					{
						decodedObj = railsObject;
						
						checkForPlainEquality = YES;
					}
				}
				//if new value is nil
				else
				{
					//if previous object existed, mark a change
					if (previousVal)
						changes = YES;
				}
			}
			
			if (checkForPlainEquality && !changes)
			{
				if (property.isDate)
				{
					if ([decodedObj significantChangeSinceDate:previousVal])
						changes = YES;
				}
				
				//otherwise, check for plain equality
				else if (![decodedObj isEqual:previousVal])
				{
					changes = YES;
				}	
			}
			
			[self performSelector:setter withObject:decodedObj];
		}
	}
	
	if (changes)
	{
		[self saveContext];
	}
	
	return changes;
}

- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict
{
	// Decided to allow public calls to influence remoteAttributes
	// That way properties can be set manually from a dict and remoteAttributes can be retrieved with confidence
	return [self setPropertiesUsingRemoteDictionary:dict applyToRemoteAttributes:YES];
}

- (NSDictionary *) remoteDictionaryRepresentationWrapped:(BOOL)wrapped
{
	NSDictionary *dict = [self dictionaryOfRemotePropertiesFromNesting:NO];
	
	if (wrapped)
		return [NSDictionary dictionaryWithObject:dict forKey:[[self class] masterModelName]];
	return dict;
}

- (NSDictionary *) dictionaryOfRemotePropertiesFromNesting:(BOOL)nesting
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	for (NSRProperty *objcProperty in [self propertyCollection].properties.allValues)
	{
		//this is recursion-protection. we don't want to include every nested class in this class because one of those nested class could nest us, causing infinite loop
		//  we are safe to include all nestedclasses on top-level (if not from within nesting)
		//  if we are a class being nested, we have to be careful - only inlude nestedclass attrs that were defined with -n
		//     except if belongs-to, since then attrs aren't being included - just "_id"
		
		BOOL excludeFromNesting = (nesting && objcProperty.nestedClass && !objcProperty.belongsTo && !objcProperty.includedOnNesting);
		
		if (!objcProperty.sendable || excludeFromNesting)
			continue;
		
		NSString *railsEquivalent = objcProperty.remoteEquivalent;
		if (!railsEquivalent)
		{
			if ([NSRConfig defaultConfig].autoinflectsPropertyNames)
				railsEquivalent = [objcProperty.name underscore];
			else
				railsEquivalent = objcProperty.name;
		}
		
		id remoteRep = [self remoteRepresentationOfObjectForProperty:objcProperty];

		//don't include a null id in json 
		if (!remoteRep && [railsEquivalent isEqualToString:@"id"])
			continue;

		if (!remoteRep)
		{
			if (objcProperty.isArray)
			{
				//make it an empty array (rails will get angry if you send null for an array)
				remoteRep = [NSArray array];
			}
			else
			{
				remoteRep = [NSNull null];
			}
		}
		else
		{
			if (objcProperty.isBelongsTo)
			{
				//in this case, remoteRep will already be just the id and not the dict
				railsEquivalent = [railsEquivalent stringByAppendingString:@"_id"];
			}
			else if (objcProperty.nestedClass)
			{
				railsEquivalent = [railsEquivalent stringByAppendingString:@"_attributes"];
			}
		}
		
		[dict setObject:remoteRep forKey:railsEquivalent];
	}

	if (remoteDestroyOnNesting)
	{
		[dict setObject:[NSNumber numberWithBool:remoteDestroyOnNesting] forKey:@"_destroy"];
	}
	
	return dict;
}

//pop the warning suppressor defined above (for calling performSelector's in ARC)
#pragma clang diagnostic pop




#pragma mark - HTTP Request stuff

+ (NSString *) routeForControllerMethod:(NSString *)customRESTMethod
{
	NSString *controller = [self masterPluralName];
	NSString *route = customRESTMethod;
	if (controller)
	{
		//this means this method was called on an NSRRemoteObject _subclass_, so appropriately point the method to its controller
		//eg, ([User makeGET:@"hello"] => myapp.com/users/hello)
		route = [NSString stringWithFormat:@"%@%@",controller, (customRESTMethod ? [@"/" stringByAppendingString:customRESTMethod] : @"")];
		
		//otherwise, if it was called on NSRRemoteObject (to access a "root method"), don't modify the route:
		//eg, ([NSRRemoteObject makeGET:@"hello"] => myapp.com/hello)
	}
	return (route ? route : @"");
}

+ (NSString *) routeForInstanceMethod:(NSString *)customRESTMethod withID:(NSInteger)rID
{
	//make request on an instance, so make route "id", or "id/route" if there's an additional route included (1/edit)
	NSString *idAndMethod = [NSString stringWithFormat:@"%d%@",rID,(customRESTMethod ? [@"/" stringByAppendingString:customRESTMethod] : @"")];
	
	return [self routeForControllerMethod:idAndMethod];
}

- (NSString *) routeForInstanceMethod:(NSString *)customRESTMethod
{
	[self testIfCanSendInstanceRequest];

	return [[self class] routeForInstanceMethod:customRESTMethod withID:self.remoteID.integerValue];
}


#pragma mark Performing actions on instances

- (void) testIfCanSendInstanceRequest
{
	if (!self.remoteID)
	{
		[NSException raise:NSRNullRemoteIDException format:@"Attempted to update, delete, or retrieve an object with no ID. (Instance of %@)",NSStringFromClass([self class])];
	}
}

- (id) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(id)body error:(NSError **)error
{
	NSString *route = [self routeForInstanceMethod:customRESTMethod];
	return [[self getRelevantConfig] makeRequest:httpVerb requestBody:body route:route sync:error orAsync:nil];
}

- (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(id)body async:(NSRHTTPCompletionBlock)completionBlock
{
	NSString *route = [self routeForInstanceMethod:customRESTMethod];
	[[self getRelevantConfig] makeRequest:httpVerb requestBody:body route:route sync:nil orAsync:completionBlock];
}

//these are really just convenience methods that'll call the above method sending the object data as request body

- (id) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod error:(NSError **)error
{
	//done again so it can be tested before converting to JSON
	[self testIfCanSendInstanceRequest];
	
	return [self remoteRequest:httpVerb method:customRESTMethod body:[self remoteDictionaryRepresentationWrapped:YES] error:error];
}

- (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod async:(NSRHTTPCompletionBlock)completionBlock
{
	[self testIfCanSendInstanceRequest];
	
	[self remoteRequest:httpVerb method:customRESTMethod body:[self remoteDictionaryRepresentationWrapped:YES] async:completionBlock];
}

//these are really just convenience methods that'll call the above method with pre-built "GET" and no body

- (id) remoteGET:(NSString *)customRESTMethod error:(NSError **)error
{
	return [self remoteRequest:@"GET" method:customRESTMethod body:nil error:error];
}

- (void) remoteGET:(NSString *)customRESTMethod async:(NSRHTTPCompletionBlock)completionBlock
{
	[self remoteRequest:@"GET" method:customRESTMethod body:nil async:completionBlock];
}


#pragma mark Performing actions on classes


+ (id) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(id)body error:(NSError **)error
{
	NSString *route = [self routeForControllerMethod:customRESTMethod];
	return [[self getRelevantConfig] makeRequest:httpVerb requestBody:body route:route sync:error orAsync:nil];
}

+ (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(id)body async:(NSRHTTPCompletionBlock)completionBlock
{
	NSString *route = [self routeForControllerMethod:customRESTMethod];
	[[self getRelevantConfig] makeRequest:httpVerb requestBody:body route:route sync:nil orAsync:completionBlock];
}

//these are really just convenience methods that'll call the above method with the JSON representation of the object

+ (id) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod bodyAsObject:(NSRRemoteObject *)obj error:(NSError **)error
{
	return [self remoteRequest:httpVerb method:customRESTMethod body:[obj remoteDictionaryRepresentationWrapped:YES] error:error];
}

+ (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod bodyAsObject:(NSRRemoteObject *)obj async:(NSRHTTPCompletionBlock)completionBlock
{
	[self remoteRequest:httpVerb method:customRESTMethod body:[obj remoteDictionaryRepresentationWrapped:YES] async:completionBlock];
}

//these are really just convenience methods that'll call the above method with pre-built "GET" and no body

+ (id) remoteGET:(NSString *)customRESTMethod error:(NSError **)error
{
	return [self remoteRequest:@"GET" method:customRESTMethod body:nil error:error];
}

+ (void) remoteGET:(NSString *)customRESTMethod async:(NSRHTTPCompletionBlock)completionBlock
{
	[self remoteRequest:@"GET" method:customRESTMethod body:nil async:completionBlock];
}



#pragma mark - External stuff (CRUD)

#pragma mark Create

- (BOOL) remoteCreate:(NSError **)error
{
	NSDictionary *jsonResponse = [[self class] remoteRequest:@"POST" method:nil bodyAsObject:self error:error];
	if (!jsonResponse)
		return NO;
	
	[self setPropertiesUsingRemoteDictionary:jsonResponse applyToRemoteAttributes:YES];
	
	return YES;
}

- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[self class] remoteRequest:@"POST" method:nil bodyAsObject:self async:
	 ^(id result, NSError *error) 
	 {
		 if (result)
			 [self setPropertiesUsingRemoteDictionary:result applyToRemoteAttributes:YES];
		 completionBlock(error);
	 }];
}

#pragma mark Update

- (BOOL) remoteUpdate:(NSError **)error
{
	BOOL didUpdate = !![self remoteRequest:@"PUT" method:nil error:error];
	if (didUpdate && self.managedObjectContext)
	{
		[self saveContext];
	}
	return didUpdate;
}

- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[self remoteRequest:@"PUT" method:nil async:
	 ^(id result, NSError *error) 
	 {
		 if (result && self.managedObjectContext)
		 {
			 [self saveContext];
		 }
		 completionBlock(error);
	 }];
}

#pragma mark Destroy

- (BOOL) remoteDestroy:(NSError **)error
{
	BOOL didDestroy = !![self remoteRequest:@"DELETE" method:nil body:nil error:error];
	if (didDestroy && self.managedObjectContext)
	{
		[self.managedObjectContext deleteObject:CD_SELF];
	}
	return didDestroy;
}

- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock
{
	[self remoteRequest:@"DELETE" method:nil body:nil async:
	 ^(id result, NSError *error) 
	{
		if (result && self.managedObjectContext)
		{
			[self.managedObjectContext deleteObject:CD_SELF];
		}
		completionBlock(error);
	}];
}

#pragma mark Get latest

- (BOOL) remoteFetch:(NSError **)error changes:(BOOL *)changesPtr
{
	NSDictionary *jsonResponse = [self remoteGET:nil error:error];
	
	if (!jsonResponse)
	{
		if (changesPtr)
			*changesPtr = NO;
		return NO;
	}
	
	BOOL changes = [self setPropertiesUsingRemoteDictionary:jsonResponse applyToRemoteAttributes:YES];
	if (changesPtr)
		*changesPtr = changes;
	
	return YES;
}

- (BOOL) remoteFetch:(NSError **)error
{
	return [self remoteFetch:error changes:NULL];
}

- (void) remoteFetchAsync:(NSRFetchCompletionBlock)completionBlock
{
	[self remoteGET:nil async:
	 ^(id result, NSError *error) 
	 {
		 BOOL change = NO;
		 if (result)
			change = [self setPropertiesUsingRemoteDictionary:result applyToRemoteAttributes:YES];
		 completionBlock(change, error);
	 }];
}

#pragma mark Get specific object (class-level)

+ (void) assertValidRemoteID:(NSNumber *)mID cmd:(SEL)sel
{
	if (!mID)
	{
		[NSException raise:NSInvalidArgumentException format:@"Attempt to call +[%@ %@] with a null remoteID.", self.class, NSStringFromSelector(sel)];
	}
}

+ (id) remoteObjectWithID:(NSNumber *)mID error:(NSError **)error
{
	[self assertValidRemoteID:mID cmd:_cmd];
	
	NSDictionary *objData = [[self class] remoteGET:[mID stringValue] error:error];
	
	if (objData)
	{
		id obj = [[self class] findAndUpdateExistingObjectOrCreateObjectUsingRemoteDictionary:objData];
		return obj;
	}
	
	return nil;
}

+ (void) remoteObjectWithID:(NSNumber *)mID async:(NSRFetchObjectCompletionBlock)completionBlock
{
	[self assertValidRemoteID:mID cmd:_cmd];
	
	[[self class] remoteGET:[mID stringValue]
					  async:
							 ^(id jsonRep, NSError *error) 
							 {
								 if (!jsonRep)
								 {
									 completionBlock(nil, error);
								 }
								 else
								 {
									 id obj = [[self class] findAndUpdateExistingObjectOrCreateObjectUsingRemoteDictionary:jsonRep];
									 completionBlock(obj, nil);
								 }
							 }];
}

#pragma mark Get all objects (class-level)

//helper method for both sync+async for remoteAll
+ (NSArray *) objectsWithRemoteArray:(NSArray *)jsonArray
{
	if (![jsonArray isKindOfClass:[NSArray class]])
	{
		[NSException raise:NSRInternalError format:@"getAll method (index) for %@ controller (from %@ class) retuned this JSON: `%@`, which is not an array - check your server output.", [self masterPluralName], self.class, jsonArray];	
	}
	
	NSMutableArray *objects = [NSMutableArray array];
	
	//iterate through every object returned by Rails (as dicts)
	for (NSDictionary *dict in jsonArray)
	{
		NSRRemoteObject *obj = [[self class] findAndUpdateExistingObjectOrCreateObjectUsingRemoteDictionary:dict];	
		
		[objects addObject:obj];
	}
	
	return objects;
}

+ (NSArray *) remoteAll:(NSError **)error
{
	//make a class GET call (so just the controller - myapp.com/users)
	id json = [self remoteGET:nil error:error];
	if (!json)
		return nil;

	return [self objectsWithRemoteArray:json];
}

+ (void) remoteAllAsync:(NSRFetchAllCompletionBlock)completionBlock
{
	[self remoteGET:nil async:
	 ^(id result, NSError *error) 
	 {
		 if (!result)
		 {
			 completionBlock(nil, error);
		 }
		 else
		 {
			 NSArray *array = [self objectsWithRemoteArray:result];
			 
			 completionBlock(array,error);
		 }
	 }];
}


#pragma mark - CoreData helpers

- (void) saveContext 
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		@try
		{
			NSError *error = nil;
			if (![self.managedObjectContext save:&error]) 
			{
				NSLog(@"NSRailsManagedObject instance %@: failed to save core data with error: %@", NSStringFromClass([self class]), [error localizedDescription]);
			} 
			else 
			{
				NSLog(@"NSRailsManagedObject instance %@: successfully saved core data!", NSStringFromClass([self class]));
			}
		}
		@catch (NSException *exception) 
		{
			NSLog(@"NSRailsManagedObject instance (%@) triggered an exception when trying to save core data: %@", NSStringFromClass([self class]), [exception reason]);
		}
	});
	[[NSNotificationCenter defaultCenter] postNotificationName:@"" object:nil];
}

+ (id) findAndUpdateExistingObjectOrCreateObjectUsingRemoteDictionary:(NSDictionary *)dict
{
	NSRRemoteObject *obj = nil;
	if ([[self getRelevantConfig] managedObjectContext])
		obj = [[self class] findLocalObjectWithRemoteID:[dict objectForKey:@"id"]];
	
	if (obj)
	{
		[obj setPropertiesUsingRemoteDictionary:dict];
	}
	else
	{
		obj = [[[self class] alloc] initWithRemoteDictionary:dict];
	}
	return obj;
}

+ (id) findLocalObjectWithRemoteID:(NSNumber *)rID
{
	NSManagedObjectContext *ctx = [[self getRelevantConfig] managedObjectContext];
	
	return [[self class] findFirstObjectByAttribute:@"remoteID" withValue:rID inContext:ctx];
}

+ (id) findFirstObjectByAttribute:(NSString *)attrName withValue:(id)value inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *fetch = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([self class])];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", attrName, value];
	fetch.predicate = predicate;
	fetch.fetchLimit = 1;
	
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:fetch error:&error];
	if (results.count > 0) 
	{
		return [results objectAtIndex:0];
	}
	return nil;
}

#pragma mark - NSCoding

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
		self.remoteID = [aDecoder decodeObjectForKey:@"remoteID"];
		remoteAttributes = [aDecoder decodeObjectForKey:@"remoteAttributes"];
		self.remoteDestroyOnNesting = [aDecoder decodeBoolForKey:@"remoteDestroyOnNesting"];
		
		customProperties = [aDecoder decodeObjectForKey:@"customProperties"];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:remoteID forKey:@"remoteID"];
	[aCoder encodeObject:remoteAttributes forKey:@"remoteAttributes"];
	[aCoder encodeBool:remoteDestroyOnNesting forKey:@"remoteDestroyOnNesting"];
	
	[aCoder encodeObject:customProperties forKey:@"customProperties"];
}

@end
