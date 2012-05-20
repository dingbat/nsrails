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

#import "NSRailsModel.h"

#import "NSRPropertyCollection.h"
#import "NSRConfig.h"

#import "NSString+Inflection.h"
#import "NSData+Additions.h"
#import "NSObject+Properties.h"
#import "NSRails+SBJson.h"

/* 
    If this file is too intimidating, 
 remember that you can navigate it
 quickly in Xcode using #pragma marks.
								    	*/

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface NSRailsModel (internal)

+ (NSRConfig *) getRelevantConfig;
- (NSRConfig *) getRelevantConfig;

+ (NSRPropertyCollection *) propertyCollection;
- (NSRPropertyCollection *) propertyCollection;

@end

@interface NSRConfig (override)

+ (NSRConfig *) overrideConfig;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NSRailsModel
@synthesize remoteID, remoteDestroyOnNesting, remoteAttributes;

#pragma mark - Meta-NSR stuff

//this will suppress the compiler warnings that come with ARC when doing performSelector
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


// Use default config + model name by default
NSRailsUseDefaultModelName;
NSRailsUseDefaultConfig;

// If NSRailsSync isn't overriden (ie, if NSRailsSync() macro is not declared in subclass), default to *
NSRailsSync(*);


//returns the sync string expanded + inherited
+ (NSString *) masterNSRailsSyncWithOverrideString:(NSString *)override
{
	//base case
	if (self == [NSRailsModel class])
		return @"remoteID=id";
	
	NSString *syncStr = (override ? override : [self NSRailsSync]);	
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

		//skip right up the hierarchy to NSRailsModel
		return [syncStr stringByAppendingFormat:@", %@", [NSRailsModel masterNSRailsSyncWithOverrideString:nil]];
	}
	
	//traverse up the hierarchy (always getting the default NSRailsSync -- custom sync string instances are subject to inheritance too!)
	return [syncStr stringByAppendingFormat:@", %@", [self.superclass masterNSRailsSyncWithOverrideString:nil]];
}

+ (NSString *) masterNSRailsSync
{
	return [self masterNSRailsSyncWithOverrideString:nil];
}

+ (NSRConfig *) masterClassConfig
{
	//check for a custom config for the class
	
	NSString *url = [self NSRailsUseConfigURL];
	if (url)
	{
		NSRConfig *custom = [[NSRConfig alloc] initWithAppURL:url];
		custom.appUsername = [self NSRailsUseConfigUsername];
		custom.appPassword = [self NSRailsUseConfigPassword];
		
		return custom;
	}
	
	return nil;
}

+ (NSString *) masterModelName
{
	if (self == [NSRailsModel class])
		return nil;
	
	NSString *defined = [self NSRailsUseModelName];
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
	NSString *defined = [self NSRailsUsePluralName];
	if (defined)
		return defined;

	//otherwise, pluralize ModelName
	return [[self masterModelName] pluralize];
}

+ (NSRPropertyCollection *) propertyCollection
{
	__strong static NSMutableDictionary *propertyCollections = nil;
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
													   syncString:[self masterNSRailsSync] 
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
	
	//if this class/instance defines NSRailsUseConfig, use it over the default
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


// Encode/decode date objects by default (will be added as custom en/de coders if they aren't declared)

- (NSString *) nsrails_encodeDate:(NSDate *)date
{
	return [[self getRelevantConfig] stringFromDate:date];
}

- (NSDate *) nsrails_decodeDate:(NSString *)dateRep
{
	return [[self getRelevantConfig] dateFromString:dateRep];
}


- (id) initWithCustomSyncProperties:(NSString *)str customConfig:(NSRConfig *)config
{
	if ((self = [super init]))
	{
		//apply inheritance rules etc to the given string
		str = [[self class] masterNSRailsSyncWithOverrideString:str];
		
		customProperties = [[NSRPropertyCollection alloc] initWithClass:[self class] 
															 syncString:str 
														   customConfig:config];
	}
	return self;
}

- (id) initWithCustomSyncProperties:(NSString *)str
{
	self = [self initWithCustomSyncProperties:str customConfig:nil];
	return self;
}



#pragma mark - Internal NSR stuff

//overload NSObject's description method to be a bit more, hm... descriptive
//will return the latest Rails dictionary (hash) retrieved
- (NSString *) description
{
	if (remoteAttributes)
		return [[super description] stringByAppendingFormat:@"=> Remote attr: %@", remoteAttributes];
	return [super description];
}

- (NSString *) remoteJSONRepresentation:(NSError **)e
{
	// enveloped meaning with the model name out front, {"user"=>{"name"=>"x", "password"=>"y"}}
	
	NSDictionary *enveloped = [NSDictionary dictionaryWithObject:[self dictionaryOfRemoteProperties]
														  forKey:[[self class] masterModelName]];
	
	NSError *error = nil;
	NSString *json = [enveloped JSONRepresentation:&error];
	if (!json)
	{
		if (e)
			*e = error;
		NSRLogError(error);
	}
	return json;
}


//will turn it into a JSON string
//includes any nested models (which the json framework can't do)
- (NSString *) remoteJSONRepresentation
{
	return [self remoteJSONRepresentation:nil];
}

//used to override SBJson's category to use the remoteJSON
- (NSString *) JSONRepresentation
{
	return [self JSONRepresentation:nil];
}
- (NSString *) JSONRepresentation:(NSError **)error
{
	return [self remoteJSONRepresentation:error];
}

// Helper method for when mapping nested properties to JSON
- (NSRailsModel *) makeRelevantModelFromClass:(NSString *)classN basedOn:(NSDictionary *)dict
{
	//make a new class to be entered for this property/array (we can assume it subclasses NSRailsModel)
	NSRailsModel *model = [[NSClassFromString(classN) alloc] initWithRemoteDictionary:dict];
	
	//see if we can assign an association to its parent (self)
	NSString *parentModelName = [[self class] masterModelName];
	NSArray *properties = [[model propertyCollection] objcPropertiesForRemoteEquivalent:parentModelName 
																			autoinflect:[self getRelevantConfig].autoinflectsPropertyNames];
	
	for (NSRProperty *property in properties)
	{
		//only assign me to the child if it has me defined as a property and it's marked as nested to me
		if (property.retrievable &&
			[property.nestedClass isEqualToString:[self.class description]])
		{
			SEL setter = [[model class] setterForProperty:property.name];
			[model performSelector:setter withObject:self];
		}
	}
	
	return model;
}

- (id) remoteRepresentationOfObjectForProperty:(NSRProperty *)prop
{
	SEL encoder = NULL;
	if (prop.encodable)
	{
		encoder = NSSelectorFromString([NSString stringWithFormat:@"encode%@", [prop.name firstLetterCapital]]);
	}
	else if (prop.isDate)
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
		
		//make sure that the result is a JSON parsable
		if (![representation isJSONParsable])
		{
			[NSException raise:NSRailsInvalidJSONEncodingException format:@"Trying to encode property '%@' in class '%@', but the result from %@ was not JSON-parsable. Please make sure you return NSDictionary, NSArray, NSString, NSNumber, or NSNull here. Remember, these are the values you want to send in the JSON to Rails. Also, defining this encoder method will override the automatic NSDate translation.",prop, NSStringFromClass([self class]),NSStringFromSelector(encoder)];
			return nil;
		}
		
		return representation;
	}
	else
	{
		id val = [self performSelector:getter];
		BOOL isArray = [val isKindOfClass:[NSArray class]];
		
		if (prop.nestedClass || prop.isHasMany)
		{
			//if the ivar is an array, we need to make every element into JSON and then put them back in the array
			if (isArray)
			{
				NSMutableArray *new = [NSMutableArray arrayWithCapacity:[val count]];
				
				for (int i = 0; i < [val count]; i++)
				{
					id element = [val objectAtIndex:i];
					
					id encodedObj = element;
					
					//if it's an NSRailsModel, we can use its dictionaryOfRemoteProperties
					if ([element isKindOfClass:[NSRailsModel class]])
					{
						//have to make it shallow so we don't loop infinitely (if that model defines us as an assc)
						encodedObj = [element dictionaryOfRemotePropertiesShallow:YES];
					}
					else if ([element isKindOfClass:[NSDate class]])
					{
						encodedObj = [self nsrails_encodeDate:element];
					}
					
					[new addObject:encodedObj];
				}
				return new;
			}
			
			//otherwise, make that nested object a dictionary through NSRailsModel
			//first make sure it's an NSRailsModel subclass
			if (![val isKindOfClass:[NSRailsModel class]])
				return nil;
			
			//have to make it shallow so we don't loop infinitely (if that model defines us as an assc)
			return [val dictionaryOfRemotePropertiesShallow:YES];
		}
				
		//otherwise, just return the value from the get method
		return val;
	}
	return nil;
}

- (id) initWithRemoteDictionary:(NSDictionary *)railsDict
{
	if ((self = [super init]))
	{
		[self setPropertiesUsingRemoteDictionary:railsDict];
	}
	return self;
}

- (id) initWithRemoteJSON:(NSString *)json
{
	if ((self = [super init]))
	{
		[self setPropertiesUsingRemoteJSON:json];
	}
	return self;
}

- (BOOL) setPropertiesUsingRemoteDictionary:(NSDictionary *)dict
{
	//support JSON that comes in like {"post"=>{"something":"something"}}
	NSDictionary *innerDict = [dict objectForKey:[[self class] masterModelName]];
	if (dict.count == 1 && innerDict)
		dict = innerDict;
	
	remoteAttributes = dict;
	
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
			id decodedObj = railsObject;
			
			SEL customDecode = NULL;
			if (property.decodable)
			{
				customDecode = NSSelectorFromString([NSString stringWithFormat:@"decode%@:",[property.name firstLetterCapital]]);
			}
			else if (property.isDate)
			{
				customDecode = @selector(nsrails_decodeDate:);
			}

			if (customDecode)
			{
				decodedObj = [self performSelector:customDecode withObject:railsObject];
			}
			else	
			{
				if (decodedObj)
				{
					if (property.isHasMany && property.nestedClass)
					{
						if (![railsObject isKindOfClass:[NSArray class]])
							[NSException raise:NSRailsInternalError format:@"Attempt to set property '%@' in class '%@' (declared as has-many) to a non-array non-null value ('%@').", property, self.class, railsObject];
							
						//array of NSRailsModels is tricky, we need to go through each existing element, see if it needs an update (or delete), and then add any new ones
						
						NSMutableArray *newArray = [[NSMutableArray alloc] init];
						
						for (id railsElement in railsObject)
						{
							id decodedElement;
							
							//array of NSDates
							if ([property.nestedClass isEqualToString:@"NSDate"])
							{
								decodedElement = [self nsrails_decodeDate:railsElement];
							}
							
							//otherwise, array of nested classes (NSRailsModels)
							else
							{
								//see if there's a nester that matches this ID - we'd just have to update it w/this dict
								NSUInteger idx = [previousVal indexOfObjectPassingTest:
													^BOOL(NSRailsModel *obj, NSUInteger idx, BOOL *stop) 
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
									BOOL neededChange = [decodedElement setPropertiesUsingRemoteDictionary:railsElement];
									
									if (neededChange)
										changes = YES;
								}
							}
							
							[newArray addObject:decodedElement];
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
							
							BOOL objChange = [decodedObj setPropertiesUsingRemoteDictionary:railsObject];
							if (objChange)
								changes = YES;
						}
					}
				}
				//new value is nil
				else
				{
					//if previous object existed, mark a change
					if (previousVal)
						changes = YES;
				}
			}
			
			//check for plain equality
			if (![decodedObj isEqual:previousVal])
			{
				changes = YES;
			}
			
			
			[self performSelector:setter withObject:decodedObj];
		}
	}
	return changes;
}

- (NSDictionary *) dictionaryOfRemoteProperties
{
	return [self dictionaryOfRemotePropertiesShallow:NO];
}

- (NSDictionary *) dictionaryOfRemotePropertiesShallow:(BOOL)shallow
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	for (NSRProperty *objcProperty in [self propertyCollection].sendableProperties)
	{
		//skip this property if it's nested and we're only looking shallow (to prevent infinite recursion)
		if (shallow && objcProperty.nestedClass)
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

		BOOL null = !remoteRep;
		
		//if we got back nil, we want to change that to the [NSNull null] object so it'll show up in the JSON
		//but only do it for non-ID properties - we want to omit ID if it's null (could be for create)
		if (!remoteRep && ![railsEquivalent isEqualToString:@"id"])
		{
			if (objcProperty.isHasMany)
			{
				//make it an empty array (rails will get angry if you send null for an array)
				remoteRep = [NSArray array];
			}
			else
			{
				remoteRep = [NSNull null];
			}
		}
		if (remoteRep)
		{
			//if it's an array, remove any null values (wouldn't make sense in the array)
			if (objcProperty.isHasMany)
			{
				for (int i = 0; i < [remoteRep count]; i++)
				{
					if ([remoteRep objectAtIndex:i] == [NSNull class])
					{
						[remoteRep removeObjectAtIndex:i];
						i--;
					}
				}
			}
			
			//this is the belongs_to trick
			//if "-b" declared and it's not NSNull and the relation's remoteID exists, THEN, we should use _id instead of _attributes
			if (objcProperty.isBelongsTo &&
				!null &&
				[remoteRep objectForKey:@"id"])
			{
				railsEquivalent = [railsEquivalent stringByAppendingString:@"_id"];
				
				//instead of the entire array, set the value to be only the ID
				remoteRep = [remoteRep objectForKey:@"id"];
			}
			
			//otherwise, if it's associative, use "_attributes" if not "null"
			else if ((objcProperty.nestedClass || objcProperty.isHasMany) && !null)
			{
				railsEquivalent = [railsEquivalent stringByAppendingString:@"_attributes"];
			}
			
			//check to see if it was already set (ie, ignore it if there are multiple properties pointing to the same rails attr)
			[dict setObject:remoteRep forKey:railsEquivalent];
		}
	}

	if (remoteDestroyOnNesting)
	{
		[dict setObject:[NSNumber numberWithBool:remoteDestroyOnNesting] forKey:@"_destroy"];
	}
	
	return dict;
}

- (BOOL) setPropertiesUsingRemoteJSON:(NSString *)json error:(NSError **)e
{
	if (!json)
	{
		NSLog(@"NSR Warning: Can't set attributes to nil JSON.");
		return NO;

		//decided to not make this raise an exception
		//[NSException raise:@"NSRailsNilJSONException" format:@"Can't set attributes to nil JSON."];
	}
	
	NSDictionary *dict = [json JSONValue:e];
	
	if (dict)
	{
		return [self setPropertiesUsingRemoteDictionary:dict];
	}
	else
	{
		if (e)
			NSRLogError(*e);
		return NO;
	}
}

- (BOOL) setPropertiesUsingRemoteJSON:(NSString *)json
{
	return [self setPropertiesUsingRemoteJSON:json error:nil];
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
		//this means this method was called on an NSRailsMethod _subclass_, so appropriately point the method to its controller
		//eg, ([User makeGET:@"hello"] => myapp.com/users/hello)
		route = [NSString stringWithFormat:@"%@%@",controller, (customRESTMethod ? [@"/" stringByAppendingString:customRESTMethod] : @"")];
		
		//otherwise, if it was called on NSRailsModel (to access a "root method"), don't modify the route:
		//eg, ([NSRailsModel makeGET:@"hello"] => myapp.com/hello)
	}
	return (route ? route : @"");
}

- (NSString *) routeForInstanceMethod:(NSString *)customRESTMethod
{
	[self testIfCanSendInstanceRequest];

	//make request on an instance, so make route "id", or "id/route" if there's an additional route included (1/edit)
	NSString *idAndMethod = [NSString stringWithFormat:@"%@%@",self.remoteID,(customRESTMethod ? [@"/" stringByAppendingString:customRESTMethod] : @"")];
	
	return [[self class] routeForControllerMethod:idAndMethod];
}


#pragma mark Performing actions on instances

- (void) testIfCanSendInstanceRequest
{
	if (!self.remoteID)
	{
		[NSException raise:NSRailsNullRemoteIDException format:@"Attempted to update, delete, or retrieve an object with no ID. (Instance of %@)",NSStringFromClass([self class])];
	}
}

- (NSString *) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(NSString *)body error:(NSError **)error
{
	NSString *route = [self routeForInstanceMethod:customRESTMethod];
	return [[self getRelevantConfig] makeRequest:httpVerb requestBody:body route:route sync:error orAsync:nil];
}

- (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(NSString *)body async:(NSRHTTPCompletionBlock)completionBlock
{
	NSString *route = [self routeForInstanceMethod:customRESTMethod];
	[[self getRelevantConfig] makeRequest:httpVerb requestBody:body route:route sync:nil orAsync:completionBlock];
}

//these are really just convenience methods that'll call the above method sending the object data as request body

- (NSString *) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod error:(NSError **)error
{
	//done again so it can be tested before converting to JSON
	[self testIfCanSendInstanceRequest];
	
	NSString *json = [self remoteJSONRepresentation:error];
	if (json)
		return [self remoteRequest:httpVerb method:customRESTMethod body:json error:error];
	return nil;
}

- (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod async:(NSRHTTPCompletionBlock)completionBlock
{
	[self testIfCanSendInstanceRequest];
	
	NSError *e = nil;
	NSString *json = [self remoteJSONRepresentation:&e];
	if (json)
		[self remoteRequest:httpVerb method:customRESTMethod body:json async:completionBlock];
	else
		completionBlock(nil, e);
}

//these are really just convenience methods that'll call the above method with pre-built "GET" and no body

- (NSString *) remoteGET:(NSString *)customRESTMethod error:(NSError **)error
{
	return [self remoteRequest:@"GET" method:customRESTMethod body:nil error:error];
}

- (void) remoteGET:(NSString *)customRESTMethod async:(NSRHTTPCompletionBlock)completionBlock
{
	[self remoteRequest:@"GET" method:customRESTMethod body:nil async:completionBlock];
}


#pragma mark Performing actions on classes


+ (NSString *)	remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(NSString *)body error:(NSError **)error
{
	NSString *route = [self routeForControllerMethod:customRESTMethod];
	return [[self getRelevantConfig] makeRequest:httpVerb requestBody:body route:route sync:error orAsync:nil];
}

+ (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod body:(NSString *)body async:(NSRHTTPCompletionBlock)completionBlock
{
	NSString *route = [self routeForControllerMethod:customRESTMethod];
	[[self getRelevantConfig] makeRequest:httpVerb requestBody:body route:route sync:nil orAsync:completionBlock];
}

//these are really just convenience methods that'll call the above method with the JSON representation of the object

+ (NSString *)	remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod bodyAsObject:(NSRailsModel *)obj error:(NSError **)error
{
	NSString *json = [obj remoteJSONRepresentation:error];
	if (json)
		return [self remoteRequest:httpVerb method:customRESTMethod body:json error:error];
	return nil;
}

+ (void) remoteRequest:(NSString *)httpVerb method:(NSString *)customRESTMethod bodyAsObject:(NSRailsModel *)obj async:(NSRHTTPCompletionBlock)completionBlock
{
	NSError *e = nil;
	NSString *json = [obj remoteJSONRepresentation:&e];
	if (json)
		[self remoteRequest:httpVerb method:customRESTMethod body:json async:completionBlock];
	else
		completionBlock(nil, e);
}

//these are really just convenience methods that'll call the above method with pre-built "GET" and no body

+ (NSString *) remoteGET:(NSString *)customRESTMethod error:(NSError **)error
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
	NSString *jsonResponse = [[self class] remoteRequest:@"POST" method:nil bodyAsObject:self error:error];
	if (!jsonResponse)
		return NO;
	
	NSError *e = nil;
	[self setPropertiesUsingRemoteJSON:jsonResponse error:&e];
	
	//just make sure that setPropertiesUsingRemoteJSON went smoothly (in case there was a JSON error)
	if (e)
	{
		if (error)
			*error = e;
		return NO;
	}
	
	return YES;
}

- (void) remoteCreateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[[self class] remoteRequest:@"POST" method:nil bodyAsObject:self async:
	 
	 ^(NSString *result, NSError *error) {
		 if (result)
			 [self setPropertiesUsingRemoteJSON:result error:&error];
		 completionBlock(error);
	 }];
}

#pragma mark Update

- (BOOL) remoteUpdate:(NSError **)error
{
	return !![self remoteRequest:@"PUT" method:nil error:error];
}

- (void) remoteUpdateAsync:(NSRBasicCompletionBlock)completionBlock
{
	[self remoteRequest:@"PUT" method:nil async:
	 
	 ^(NSString *result, NSError *error) {
		 completionBlock(error);
	 }];
}

#pragma mark Destroy

- (BOOL) remoteDestroy:(NSError **)error
{
	return !![self remoteRequest:@"DELETE" method:nil body:nil error:error];
}

- (void) remoteDestroyAsync:(NSRBasicCompletionBlock)completionBlock
{
	[self remoteRequest:@"DELETE" method:nil body:nil async:
	 
	 ^(NSString *result, NSError *error) {
		completionBlock(error);
	}];
}

#pragma mark Get latest

- (BOOL) remoteFetch:(NSError **)error changes:(BOOL *)changesPtr
{
	NSString *jsonResponse = [self remoteGET:nil error:error];
	
	if (!jsonResponse)
		return NO;
	
	NSError *e = nil;
	BOOL changes = [self setPropertiesUsingRemoteJSON:jsonResponse error:&e];
	if (changesPtr)
		*changesPtr = changes;
	
	//just make sure that setPropertiesUsingRemoteJSON went smoothly (in case there was a JSON error)
	if (e)
	{
		if (error)
			*error = e;
		return NO;
	}
	
	return YES;
}

- (BOOL) remoteFetch:(NSError **)error
{
	return [self remoteFetch:error changes:NULL];
}

- (void) remoteFetchAsync:(NSRGetLatestCompletionBlock)completionBlock
{
	[self remoteGET:nil async:
	 
	 ^(NSString *result, NSError *error) 
	 {
		 BOOL change = NO;
		 if (result)
			change = [self setPropertiesUsingRemoteJSON:result error:&error];
		 completionBlock(change, error);
	 }];
}

#pragma mark Get specific object (class-level)

+ (id) remoteObjectWithID:(NSInteger)mID error:(NSError **)error
{
	NSRailsModel *obj = [[[self class] alloc] init];
	obj.remoteID = [NSDecimalNumber numberWithInteger:mID];
	
	if (![obj remoteFetch:error])
	{
		obj = nil;
	}

	return obj;
}

+ (void) remoteObjectWithID:(NSInteger)mID async:(NSRGetObjectCompletionBlock)completionBlock
{
	NSRailsModel *obj = [[[self class] alloc] init];
	obj.remoteID = [NSDecimalNumber numberWithInteger:mID];
		
	[obj remoteFetchAsync:
	 
	 ^(BOOL changed, NSError *error) {
		if (error)
			completionBlock(nil, error);
		else
			completionBlock(obj, error);
	}];
}

#pragma mark Get all objects (class-level)

//helper method for both sync+async for remoteAll
+ (NSArray *) arrayOfModelsFromJSON:(NSString *)json error:(NSError **)error
{
	NSError *jsonError = nil;
	
	//transform result into array (via json)
	id arr = [json JSONValue:&jsonError];
	
	if (jsonError || !arr || arr == [NSNull null])
	{
		if (jsonError)
		{
			NSRLogError(jsonError);
			if (error)
				*error = jsonError;
		}
		return nil;
	}
	
	if (![arr isKindOfClass:[NSArray class]])
	{
		[NSException raise:NSRailsInternalError format:@"getAll method (index) for %@ controller retuned this JSON: `%@`, which is not an array - check your server output.",NSStringFromClass([self class]), json];
		return nil;
	}
	
	//here comes actually making the array to return
	
	NSMutableArray *objects = [NSMutableArray array];
	
	//iterate through every object returned by Rails (as dicts)
	for (NSDictionary *dict in arr)
	{
		NSRailsModel *obj = [[[self class] alloc] initWithRemoteDictionary:dict];	
		
		[objects addObject:obj];
	}
	
	return objects;
}

+ (NSArray *) remoteAll:(NSError **)error
{
	//make a class GET call (so just the controller - myapp.com/users)
	NSString *json = [self remoteGET:nil error:error];
	if (!json)
	{
		return nil;
	}
	return [self arrayOfModelsFromJSON:json error:error];
}

+ (void) remoteAllAsync:(NSRGetAllCompletionBlock)completionBlock
{
	[self remoteGET:nil async:
	 ^(NSString *result, NSError *error) 
	 {
		 if (!result)
		 {
			 completionBlock(nil, error);
		 }
		 else
		 {
			 //make an array from the result returned async, and we can reuse the same error dereference (since we know it's nil)
			 NSArray *array = [self arrayOfModelsFromJSON:result error:&error];
			 completionBlock(array,error);
		 }
	 }];
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
