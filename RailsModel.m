//
//  RailsModel.m
//  Storyline
//
//  Created by Dan Hassin on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RailsModel.h"
#import "JSONFramework.h"
#import "NSString+InflectionSupport.h"
#import "NSData+Additions.h"

#import <objc/runtime.h>

#define RMLogErrors
#define BASE_RAILS @"modelID=id"


@interface RailsModel (internal)

- (void) setAttributesAsPerDictionary:(NSDictionary *)dict;

- (NSDictionary *) dictionaryOfRelevantProperties;
- (NSDictionary *) envelopedDictionaryOfRelevantProperties:(NSString *)envelope;

@end

@implementation RailsModel
@synthesize modelID, attributes, destroyOnNesting;

#pragma mark App Setup

//super-static
static NSString* appURL;
static NSString* appUsername;
static NSString* appPassword;

+ (void) setAppURL:(NSString *)str
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
+ (void) setAppUsername:(NSString *)str {	appUsername = str;	}
+ (void) setAppPassword:(NSString *)str {	appPassword = str;	}

#pragma mark -
#pragma mark Meta-RM stuff
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

+ (NSString *) MakeRails
{
	return BASE_RAILS;
}

+ (NSString *) railsProperties
{
	if ([self respondsToSelector:@selector(MakeRailsNoSuper)])
	{
		NSString *props = [self performSelector:@selector(MakeRailsNoSuper)];
		if (props.length > 0)
		{
			//always want to keep base (modelID) even if nosuper
			return [BASE_RAILS stringByAppendingFormat:@", %@",props];
		}
	}
	return [self MakeRails];
}

+ (NSString *) getModelName
{
	//if defined through ModelName() then use that instead
	SEL sel = @selector(ModelName);
	if ([self respondsToSelector:sel])
	{
		return [self performSelector:sel];
	}
	
	NSString *class = NSStringFromClass(self);
	if ([class isEqualToString:@"RailsModel"])
		class = nil;
	
#ifdef RMAutomaticallyUnderscoreAndCamelize
	return [class underscore];
#else
	return class;
#endif
}

+ (NSString *) getPluralModelName
{
	SEL sel = @selector(PluralModelName);
	if ([self respondsToSelector:sel])
	{
		return [self performSelector:sel];
	}
	return [[self getModelName] pluralize];
}

- (NSString *) camelizedModelName
{
	return [[[self class] getModelName] camelize];
}

- (id) init
{
	if ((self = [super init]))
	{
		sendableProperties = [[NSMutableArray alloc] init];
		retrievableProperties = [[NSMutableArray alloc] init];
		modelRelatedProperties = [[NSMutableDictionary alloc] init];
		propertyEquivalents = [[NSMutableDictionary alloc] init];
		encodeProperties = [[NSMutableArray alloc] init];
		decodeProperties = [[NSMutableArray alloc] init];
		destroyOnNesting = NO;
		
		NSString *props = [[self class] railsProperties];
//		NSLog(@"found r-properties %@",props);
		NSCharacterSet *wn = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		
		NSArray *elements = [props componentsSeparatedByString:@","];
		for (int i = 0; i < elements.count; i++)
		{
			NSString *str = [elements objectAtIndex:i];
			NSString *prop = [str stringByTrimmingCharactersInSet:wn];
			
			if (prop.length > 0)
			{
				NSArray *opSplit = [prop componentsSeparatedByString:@"-"];
				NSArray *modSplit = [[opSplit objectAtIndex:0] componentsSeparatedByString:@":"];
				NSArray *eqSplit = [[modSplit objectAtIndex:0] componentsSeparatedByString:@"="];
				
				prop = [[eqSplit objectAtIndex:0] stringByTrimmingCharactersInSet:wn];
				
				NSString *options = [opSplit lastObject];
				if (opSplit.count > 1)
				{
					if ([options rangeOfString:@"s"].location != NSNotFound)
						[sendableProperties addObject:prop];
					if ([options rangeOfString:@"r"].location != NSNotFound)
						[retrievableProperties addObject:prop];
					if ([options rangeOfString:@"e"].location != NSNotFound)
						[encodeProperties addObject:prop];
					if ([options rangeOfString:@"d"].location != NSNotFound)
						[decodeProperties addObject:prop];
				}
				
				//if neither -s or -r aren't defined, by deault make it both sendable+retrievable
				if (opSplit.count == 1 || 
					([options rangeOfString:@"s"].location == NSNotFound && [options rangeOfString:@"r"].location == NSNotFound))
				{
					[sendableProperties addObject:prop];
					[retrievableProperties addObject:prop];
				}
				
				if (modSplit.count > 1)
				{
					NSString *otherModel = [[modSplit lastObject] stringByTrimmingCharactersInSet:wn];
	#ifdef RMLogErrors
					if (!NSClassFromString(otherModel))
						NSLog(@"failed to make relation with models %@ and %@ - could not find class %@. make sure you entered the class of the related model correctly into the MakeRails of the %@ class",[self camelizedModelName],otherModel,otherModel,[self camelizedModelName]);
	#endif
					[modelRelatedProperties setObject:otherModel forKey:prop];
				}
				
				NSString *equivalent = prop;
				if (eqSplit.count > 1)
				{
					equivalent = [[eqSplit lastObject] stringByTrimmingCharactersInSet:wn];
					if ([equivalent isEqualToString:@"id"] && i != 0)
					{
	#ifdef RMLogErrors
						NSLog(@"found attempt to set the rails equivalent of ivar '%@' in model %@ to 'id'. this property is reserved and should be accessed through 'modelID' from a RailsModel subclass. equivalence not set, but please fix this.", prop, [self camelizedModelName]);
	#endif
						equivalent = prop;
					}
					else if ([propertyEquivalents allKeysForObject:equivalent].count > 0)
					{
	#ifdef RMLogErrors
						NSLog(@"found multiple instance variables tied to one rails equivalent in class %@. please fix; could be buggy.",[self camelizedModelName]);
	#endif
					}
				}
#ifdef RMAutomaticallyUnderscoreAndCamelize
				else
				{
					equivalent = [[prop underscore] lowercaseString];
				}
#endif
				[propertyEquivalents setObject:equivalent forKey:prop];
			}
		}
		
	//	NSLog(@"sendable: %@",sendableProperties);
	//	NSLog(@"retrievable: %@",retrievableProperties);
	//	NSLog(@"MRP: %@",modelRelatedProperties);
	//	NSLog(@"eqiuvalents: %@",propertyEquivalents);
		 
	}
	return self;
}

#pragma mark -
#pragma mark Internal RM stuff

- (NSString *) description
{
	return [attributes description];
}

- (id) makeRelevantModelFromClass:(NSString *)classN basedOn:(NSDictionary *)dict
{
	RailsModel *model = [[NSClassFromString(classN) alloc] init];
	if (!model)
	{
#ifdef RMLogErrors
		NSLog(@"could not find %@ class; leaving property null.",classN);
#endif
		return nil;
	}
	[model setAttributesAsPerDictionary:dict];
	return model;
}

- (id) objectForProperty:(NSString *)prop representation:(id)rep
{
	if ([decodeProperties indexOfObject:prop] != NSNotFound)
	{
		NSString *sel = [NSString stringWithFormat:@"decode%@:",[prop toClassName]];
		SEL selector = NSSelectorFromString(sel);
		if ([self respondsToSelector:selector])
		{
			id obj = [self performSelector:selector withObject:rep];
			return obj;
		}
	}
	
	return rep;
}

- (id) representationOfObjectForProperty:(NSString *)prop
{
	SEL sel = NSSelectorFromString(prop);
	if ([self respondsToSelector:sel])
	{
		id val = [self performSelector:sel];
		if ([modelRelatedProperties objectForKey:prop])
		{
			if ([val isKindOfClass:[NSArray class]])
			{
#ifdef RMSendHasManyRelationAsHash
				NSMutableDictionary *new = [NSMutableDictionary dictionary];
#else
				NSMutableArray *new = [NSMutableArray arrayWithCapacity:[val count]];
#endif
				for (int i = 0; i < [val count]; i++)
				{
					id obj = [[val objectAtIndex:i] dictionaryOfRelevantProperties];
#ifdef RMSendNilValues
					if (!obj)
					{
						obj = [NSNull null];
					}
#endif
					if (obj)
					{
#ifdef RMSendHasManyRelationAsHash
						[new setObject:obj forKey:[NSString stringWithFormat:@"%d",i]];
#else
						[new addObject:obj];
#endif
					}
				}
				return new;
			}
			return [val dictionaryOfRelevantProperties];
		}
		
		if ([encodeProperties indexOfObject:prop] != NSNotFound)
		{
			NSString *sel = [NSString stringWithFormat:@"encode%@:",[prop toClassName]];
			SEL selector = NSSelectorFromString(sel);
			if ([self respondsToSelector:selector])
			{
				id obj = [self performSelector:selector withObject:val];
				return obj;
			}
		}
		
		return val;
	}
	return nil;
}
//little reminder of how propertEquiv dict works
// username=rails_username ----> setObject:rails_username forKey:username
- (void) setAttributesAsPerDictionary:(NSDictionary *)dict
{
	attributes = dict;
	for (NSString *key in dict)
	{
		NSString *property;
		NSArray *equiv = [propertyEquivalents allKeysForObject:key];
		if (equiv.count > 0) //means its a relevant property, so lets try to set it
		{
			property = [equiv objectAtIndex:0];
#ifdef RMLogErrors
			if (equiv.count > 1)
				NSLog(@"found multiple instance variables tied to one rails equivalent (%@ are all set to equal rails property '%@'). setting data for it into the first ivar listed, but please fix.",equiv,key);
#endif
		
			SEL sel = NSSelectorFromString([NSString stringWithFormat:@"set%@:",[property toClassName]]);
			if ([self respondsToSelector:sel] && [retrievableProperties indexOfObject:property] != NSNotFound)
				//means its marked as retrievable and is settable through setEtc:.
			{
				id val = [dict objectForKey:key];
				val = [self objectForProperty:property representation:([val isKindOfClass:[NSNull class]] ? nil : val)];
				if (val)
				{
					NSString *relatedClass = [[modelRelatedProperties objectForKey:property] toClassName];
					//instantiate it as the class specified in MakeRails
					//if the JSON conversion returned an array for the value, instantiate each element
					if (relatedClass)
					{
						if ([val isKindOfClass:[NSArray class]])
						{
							NSMutableArray *array = [NSMutableArray array];
							for (NSDictionary *dict in val)
							{
								id model = [self makeRelevantModelFromClass:relatedClass basedOn:dict];
								[array addObject:model];
							}
							val = array;
						}
						else
						{
							val = [self makeRelevantModelFromClass:relatedClass basedOn:[dict objectForKey:key]];
						}
					}
					[self performSelector:sel withObject:val];
				}
				else
				{
					[self performSelector:sel withObject:nil];
				}
			}
		}
	}
}

- (NSDictionary *) envelopedDictionaryOfRelevantProperties:(NSString *)envelope
{
	NSDictionary *dict = [NSDictionary dictionaryWithObject:[self dictionaryOfRelevantProperties]
													 forKey:envelope];
	return dict;
}

- (NSDictionary *) dictionaryOfRelevantProperties
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	for (NSString *key in sendableProperties)
	{
		NSString *property = [propertyEquivalents objectForKey:key];
		
		id val = [self representationOfObjectForProperty:key];
		BOOL null = !val;
#ifdef RMSendNilValues
		if (!val && ![property isEqualToString:@"id"])
		{
			@try
			{
				Ivar var = class_getInstanceVariable([self class], [key cStringUsingEncoding:NSASCIIStringEncoding]);
				const char* typeEncoding = ivar_getTypeEncoding(var);
				NSString *string = [NSString stringWithCString:typeEncoding encoding:NSASCIIStringEncoding];
				if ([string isEqualToString:@"@\"NSArray\""] || [string isEqualToString:@"@\"NSMutableArray\""])
				{
					//there's an array, and because the value is nil, make it an empty array
					val = [NSArray array];
				}
				else
				{
					val = [NSNull null];
				}
			}
			@catch (NSException *e)
			{
				val = [NSNull null];
			}
		}
#endif
		if (val)
		{
			if ([modelRelatedProperties objectForKey:key] && !null) //if its null/empty(for arrays), dont append _attributes
				property = [property stringByAppendingString:RMAppendRelatedModelKeyOnSend];
			[dict setObject:val forKey:property];
		}
	}
	if (destroyOnNesting)
	{
		[dict setObject:[NSNumber numberWithBool:destroyOnNesting] forKey:@"_destroy"];
	}

	return dict;
}

- (BOOL) setAttributesAsPerJSON:(NSString *)json
{
	NSDictionary *dict;
	@try
	{
		dict = [json JSONValue];
	}
	@catch (NSException *exception)
	{
		NSLog(@"something went wrong in json conversion!");
		return NO;
	}
	if (!dict || dict.count == 0)
	{
		NSLog(@"something went wrong in json conversion!");
		return NO;
	}
		
	[self setAttributesAsPerDictionary:dict];
	
	return YES;
}

#pragma clang diagnostic pop


#pragma mark -
#pragma mark HTTP Request stuff

+ (NSString *) makeRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route error:(NSError **)error
{
//	requestStr = @"{\"user\":{\"password\":\"123454\",\"username\":\"Dan\",\"stories\":[],\"friend\":{\"name\":\"hu\"}}}";
		
	NSString *url = [NSString stringWithFormat:@"%@/%@",appURL,route];
	
#ifdef RMAutomaticallyMakeURLsLowercase
	url = [url lowercaseString];
#endif
	
#if RMLog > 0
	NSLog(@"%@ to %@",type,url);
#if RMLog == 2
	NSLog(@"OUT===> %@",requestStr);
#endif
#endif
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
	
	[request setHTTPMethod:type];
	[request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	if (appUsername && appPassword)
	{
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", appUsername, appPassword];
		NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
		NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
		
		[request setValue:authHeader forHTTPHeaderField:@"Authorization"]; 
	}
	
	if (![type isEqualToString:@"GET"])
	{
		NSData *requestData = [NSData dataWithBytes:[requestStr UTF8String] length:[requestStr length]];

		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody: requestData];
		[request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
 	}
	
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
	
	int statusCode = -1;
	if ([response respondsToSelector:@selector(statusCode)])
	{
		statusCode = [((NSHTTPURLResponse *)response) statusCode];
	}
	BOOL err = (statusCode == -1 || statusCode >= 400);
	
	NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
#if RMLog == 2
	NSLog(@"IN<=== Code %d; %@\n\n",statusCode,(err ? @"[see ERROR]" : result));
#endif
	
	if (err)
	{
		NSDictionary *inf = [NSDictionary dictionaryWithObject:result
														forKey:NSLocalizedDescriptionKey];
		NSError *statusError = [NSError errorWithDomain:@"rails"
												   code:statusCode
											   userInfo:inf];

		if (error)
		{
			*error = statusError;
		}
		
#if RMLog > 0
		NSLog(@"%@",[statusError localizedDescription]);
#endif
		
		return nil;
	}
	
	return result;
}


- (NSString *) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error
{
	NSString *route = [NSString stringWithFormat:@"%@/%@",[[self class] getPluralModelName], self.modelID];
	if (method.length > 0)
	{
		if ([[method substringToIndex:1] isEqualToString:@"/"])
			method = [method substringFromIndex:1];
		
		route = [route stringByAppendingFormat:@"/%@",method];
	}
	
	return [RailsModel makeRequestType:httpVerb requestBody:requestStr route:route error:error];
}

- (NSString *) makeGETRequestWithMethod:(NSString *)method error:(NSError **)error
{
	return [self makeRequest:@"GET" requestBody:nil method:method error:error];
}

- (id) makeRequest:(NSString *)type error:(NSError **)error
{
	if ([type isEqualToString:@"GET"])
	{
		return [self makeGETRequestWithMethod:nil error:error];
	}
	
	if ([type isEqualToString:@"DELETE"])
	{
		return [self makeRequest:@"DELETE" requestBody:nil method:nil error:error];
	}
	
	NSString *body = [self JSONRepresentation];		
	
	//for POST, PUT, and any others
	return [self makeRequest:type requestBody:body method:nil error:error];
}

+ (NSString *) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error
{
	NSString *route;
	NSString *controller = [self getPluralModelName];
	if (controller)
	{
		//this means this method was called on a RailsMethod _subclass_, so appropriately point the method to its controller
		route = controller;
		if (method)
			route = [route stringByAppendingFormat:@"/%@", method];
	}
	else
	{
		//this means this method was called on RailsModel (to access a "root method")
		route = method;
	}
	
	return [RailsModel makeRequestType:httpVerb requestBody:requestStr route:route error:error];
}

+ (NSString *) makeGETRequestWithMethod:(NSString *)method error:(NSError **)error
{
	return [self makeRequest:@"GET" requestBody:nil method:method error:error];
}

#pragma mark -
#pragma mark External stuff (CRUD)

- (BOOL) createRemote {	return [self createRemote:nil];	}
- (BOOL) createRemote:(NSError **)error {	return [self createRemote:error excluding:nil];	}
- (BOOL) createRemote:(NSError **)error excluding:(NSString *)exc, ...
{
	NSMutableArray *list = [NSMutableArray array];
	
	if (exc)
	{
		va_list args;
		va_start(args, exc);
		for (id arg = exc; arg != nil; arg = va_arg(args, id))
		{
			[list addObject:arg];
		}
		va_end(args);
		
	}
	
	[sendableProperties removeObjectsInArray:list];
	NSString *json = [self makeRequest:@"POST" error:error];
	[sendableProperties addObjectsFromArray:list];
	
	return (json && [self setAttributesAsPerJSON:json]);
}

- (BOOL) updateRemote {	return [self updateRemote:nil];	}
- (BOOL) updateRemote:(NSError **)error {	return [self updateRemote:error excluding:nil];	}
- (BOOL) updateRemote:(NSError **)error excluding:(NSString *)exc, ...
{
	if (!self.modelID)
	{
#ifdef RMLogErrors
		NSLog(@"error in updating %@ instance - object has no ID.",[self camelizedModelName]);
#endif
		return NO;
	}
	
	NSMutableArray *list = [NSMutableArray array];
	
	if (exc)
	{
		va_list args;
		va_start(args, exc);
		for (id arg = exc; arg != nil; arg = va_arg(args, id))
		{
			[list addObject:arg];
		}
		va_end(args);
		
	}
	
	[sendableProperties removeObjectsInArray:list];
	BOOL success = !![self makeRequest:@"PUT" error:error];
	[sendableProperties addObjectsFromArray:list];
	
	return success;
}

- (BOOL) destroyRemote {	return [self destroyRemote:nil]; }
- (BOOL) destroyRemote:(NSError **)error
{
	if (!self.modelID)
	{
#ifdef RMLogErrors
		NSLog(@"error in deleting %@ instance - object has no ID.",[self camelizedModelName]);
#endif
		return NO;
	}
	
	return ([self makeRequest:@"DELETE" error:error] != nil);
}

- (BOOL) getRemoteLatest {	return [self getRemoteLatest:nil]; }
- (BOOL) getRemoteLatest:(NSError **)error
{
	NSString *json = [self makeRequest:@"GET" error:error];
	if (!json)
	{
		return NO;
	}
	return ([self setAttributesAsPerJSON:json]); //will return true/false if conversion worked
}

+ (id) remoteObjectWithID:(int)mID
{
	RailsModel *rm = [[[self class] alloc] init];
	rm.modelID = [NSDecimalNumber numberWithInt:mID];
	
	if (![rm getRemoteLatest])
		rm = nil;
	
	return rm;
}

+ (NSArray *) getAllRemote {	return [self getAllRemote:nil]; }

+ (NSArray *) getAllRemote:(NSError **)error
{
	NSString *json = [[self class] makeGETRequestWithMethod:nil error:error];
	
	if (!json)
	{
		return nil;
	}
	
	NSArray *arr = [json JSONValue];
	NSMutableArray *objects = [NSMutableArray array];
	
	for (NSDictionary *dict in arr)
	{
		RailsModel *obj = [[[self class] alloc] init];		
		[obj setAttributesAsPerDictionary:dict];
		
		[objects addObject:obj];
	}
	
	return objects;
}

- (NSString *) JSONRepresentation
{
	// enveloped meaning with the model name out front, {"user"=>{"name"=>"x", "password"=>"y"}}
	return [[self envelopedDictionaryOfRelevantProperties:[[self class] getModelName]] JSONRepresentation];
}

@end
