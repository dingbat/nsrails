//
//  RailsModel.m
//  Storyline
//
//  Created by Dan Hassin on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSRails.h"
#import "JSONFramework.h"
#import "NSString+InflectionSupport.h"
#import "NSData+Additions.h"

#import <objc/runtime.h>

//log NSR errors by default
#define NSRLogErrors
#define BASE_RAILS @"modelID=id"

#define NSRLogError(x)	NSLog(@"Error Domain=%@ Code=%d \"%@\"",x.domain,x.code,[x localizedDescription]);



@interface RailsModel (internal)

- (void) setAttributesAsPerDictionary:(NSDictionary *)dict;

- (NSDictionary *) dictionaryOfRelevantProperties;
- (NSDictionary *) envelopedDictionaryOfRelevantProperties:(NSString *)envelope;
- (NSString *) getIvarType:(NSString *)ivar;
- (SEL) getIvarSetter:(NSString *)ivar;
- (SEL) getIvarGetter:(NSString *)ivar;

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
#pragma mark Meta-NSR stuff

//this will suppress the compiler warnings that come with ARC when doing performSelector
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
	
	//otherwise, return name of the class
	NSString *class = NSStringFromClass(self);
	if ([class isEqualToString:@"RailsModel"])
		class = nil;
	
#ifdef NSRAutomaticallyUnderscoreAndCamelize
	return [class underscore];
#else
	return class;
#endif
}

+ (NSString *) getPluralModelName
{
	//if defined through ModelNameWithPlural(), use that instead
	SEL sel = @selector(PluralModelName);
	if ([self respondsToSelector:sel])
	{
		return [self performSelector:sel];
	}
	//otherwise, pluralize ModelName
	return [[self getModelName] pluralize];
}

//convenience
- (NSString *) camelizedModelName
{
	return [[[[self class] getModelName] camelize] toClassName];
}

- (id) init
{
	if ((self = [super init]))
	{
		//initialize property categories
		sendableProperties = [[NSMutableArray alloc] init];
		retrievableProperties = [[NSMutableArray alloc] init];
		modelRelatedProperties = [[NSMutableDictionary alloc] init];
		propertyEquivalents = [[NSMutableDictionary alloc] init];
		encodeProperties = [[NSMutableArray alloc] init];
		decodeProperties = [[NSMutableArray alloc] init];
		
		destroyOnNesting = NO;
		
		//begin reading in properties defined through MakeRails
		NSString *props = [[self class] railsProperties];
		NSCharacterSet *wn = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		
		NSArray *elements = [props componentsSeparatedByString:@","];
		for (int i = 0; i < elements.count; i++)
		{
			NSString *str = [elements objectAtIndex:i];
			NSString *prop = [str stringByTrimmingCharactersInSet:wn];
			
			if (prop.length > 0)
			{
				//prop ~= "username=user_name:Class -etc"
				//find string sets between =, :, and -
				NSArray *opSplit = [prop componentsSeparatedByString:@"-"];
				NSArray *modSplit = [[opSplit objectAtIndex:0] componentsSeparatedByString:@":"];
				NSArray *eqSplit = [[modSplit objectAtIndex:0] componentsSeparatedByString:@"="];
				
				prop = [[eqSplit objectAtIndex:0] stringByTrimmingCharactersInSet:wn];
				
				NSString *options = [opSplit lastObject];
				if (opSplit.count > 1)
				{
					//if any of these flags exist, add to appropriate category
					if ([options rangeOfString:@"s"].location != NSNotFound)
						[sendableProperties addObject:prop];
					if ([options rangeOfString:@"r"].location != NSNotFound)
						[retrievableProperties addObject:prop];
					if ([options rangeOfString:@"e"].location != NSNotFound)
						[encodeProperties addObject:prop];
					if ([options rangeOfString:@"d"].location != NSNotFound)
						[decodeProperties addObject:prop];
				}
				
				//if no options are defined or they _are_ but neither -s nor -r are defined, by default add sendable+retrievable
				if (opSplit.count == 1 ||
					([options rangeOfString:@"s"].location == NSNotFound && [options rangeOfString:@"r"].location == NSNotFound))
				{
					[sendableProperties addObject:prop];
					[retrievableProperties addObject:prop];
				}
				
				//see if there was a : declared
				if (modSplit.count > 1)
				{
					NSString *otherModel = [[modSplit lastObject] stringByTrimmingCharactersInSet:wn];
					if (otherModel.length > 0)
					{
						//class entered is not a real class
						if (!NSClassFromString(otherModel))
						{
#ifdef NSRLogErrors
							NSLog(@"failed to find class %@ (declared for property %@ of class %@) - please fix this. relation not set. ",otherModel,prop,[self camelizedModelName]);
#endif
						}
						//class entered is not a subclass of RailsModel
						else if (![NSClassFromString(otherModel) isSubclassOfClass:[RailsModel class]])
						{
#ifdef NSRLogErrors
							NSLog(@"class %@ was declared for property %@ of class %@, but %@ is not a subclass of RailsModel - please fix this. relation not set.",otherModel,prop,[self camelizedModelName],otherModel);
#endif
						}
						else
							[modelRelatedProperties setObject:otherModel forKey:prop];
					}
				}
				else
				{
					//if no : was declared for this property, check to see if we should link it anyway
					NSString *ivarType = [self getIvarType:prop];
					if (!([ivarType isEqualToString:@"NSString"] ||
						  [ivarType isEqualToString:@"NSMutableString"] ||
						  [ivarType isEqualToString:@"NSDictionary"] ||
						  [ivarType isEqualToString:@"NSMutableDictionary"] ||
						  [ivarType isEqualToString:@"NSNumber"] ||
						  [ivarType isEqualToString:@"NSArray"] ||
						  [ivarType isEqualToString:@"NSMutableArray"]))
					{
						//must be custom obj, see if its a railsmodel, if it is, link it automatically
						Class c = NSClassFromString(ivarType);
						if (c && [c isSubclassOfClass:[RailsModel class]])
						{
#if NSRLog > 2
							NSLog(@"automatically linking ivar %@ in class %@ with related railsmodel %@",prop,[self camelizedModelName],ivarType);
#endif
							[modelRelatedProperties setObject:ivarType forKey:prop];
						}
					}
				}
				
				//see if there are any = declared
				NSString *equivalent = prop;
				if (eqSplit.count > 1)
				{
					equivalent = [[eqSplit lastObject] stringByTrimmingCharactersInSet:wn];
					//if they tried to tie it to 'id', give error (but ignore if it's the first equivalence (modelID via base_rails)
					if ([equivalent isEqualToString:@"id"] && i != 0)
					{
#ifdef NSRLogErrors
						NSLog(@"found attempt to set the rails equivalent of ivar '%@' in class %@ to 'id'. this property is reserved and should be accessed through 'modelID' from a RailsModel subclass - please fix this. equivalence not set.", prop, [self camelizedModelName]);
#endif
						equivalent = prop;
					}
					//see if there's already 1 or more rails names set for this equivalency
					else if ([propertyEquivalents allKeysForObject:equivalent].count > 0)
					{
#ifdef NSRLogErrors
						NSLog(@"found multiple instance variables tied to one rails equivalent in class %@ - please fix this. when receiving rails property %@, NSR will assign it to the first equivalence listed.",[self camelizedModelName], equivalent);
#endif
					}
				}
#ifdef NSRAutomaticallyUnderscoreAndCamelize
				else
				{
					//if no = was declared for this property, default by using underscore+lowercase'd version of it
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
#pragma mark Ivar tricks

- (NSString *) getIvarType:(NSString *)ivar
{
	//get class's ivar
	Ivar var = class_getInstanceVariable([self class], [ivar UTF8String]);
	if (!var)
		return nil;
	
	NSString *ret = [NSString stringWithCString:ivar_getTypeEncoding(var) encoding:NSUTF8StringEncoding];
	
	//ret will be like @"NSString", so strip " and @
	return [[ret stringByReplacingOccurrencesOfString:@"\"" withString:@""] stringByReplacingOccurrencesOfString:@"@" withString:@""];
}

- (SEL) getIvar:(NSString *)ivar attributePrefix:(NSString *)str
{
	objc_property_t property = class_getProperty([self class], [ivar UTF8String]);
	if (!property)
		return nil;
	
	NSString *atts = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
	//this will return some garbage like "Ti,GgetFoo,SsetFoo:,Vproperty"
	//getter is prefixed by a G and setter is prefixed by an S
	//split it by attribute and return anything matching the prefix specified (would be S or G)
	for (NSString *att in [atts componentsSeparatedByString:@","])
	{
		if (att.length > 0 && [[att substringToIndex:1] isEqualToString:str])
		{
			NSString *setter = [att substringFromIndex:1];
			return NSSelectorFromString(setter);
		}
	}
	
	return nil;
}

- (SEL) getIvarGetter:(NSString *)ivar
{
	SEL s = [self getIvar:ivar attributePrefix:@"G"];
	//if no custom setter specified, return the standard etc
	if (!s)
	{
		s = NSSelectorFromString(ivar);
	}
	return s;
}

- (SEL) getIvarSetter:(NSString *)ivar
{
	SEL s = [self getIvar:ivar attributePrefix:@"S"];
	//if no custom setter specified, return the standard setEtc:
	if (!s)
	{
		s = NSSelectorFromString([NSString stringWithFormat:@"set%@:",[ivar toClassName]]);
	}
	return s;
}

#pragma mark -
#pragma mark Internal NSR stuff

- (NSString *) description
{
	return [attributes description];
}

- (id) makeRelevantModelFromClass:(NSString *)classN basedOn:(NSDictionary *)dict
{
	//make a new class to be entered for this property/array (we can assume it subclasses RM)
	RailsModel *model = [[NSClassFromString(classN) alloc] init];
	if (!model)
	{
#ifdef NSRLogErrors
		NSLog(@"could not find %@ class; leaving property null.",classN);
#endif
		return nil;
	}
#ifndef NSRCompileWithARC
	[model autorelease];
#endif
	
	//populate the new class with attributes specified
	[model setAttributesAsPerDictionary:dict];
	return model;
}

- (id) objectForProperty:(NSString *)prop representation:(id)rep
{
	//if object is marked as decodable, use the decode method
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
	
	//otherwise, return whatever it is
	return rep;
}

- (id) representationOfObjectForProperty:(NSString *)prop
{
	//get the value of the property
	SEL sel = [self getIvarGetter:prop];
	if ([self respondsToSelector:sel])
	{
		id val = [self performSelector:sel];
		
		//see if this property actually links to a custom RailsModel subclass
		if ([modelRelatedProperties objectForKey:prop])
		{
			//if the ivar is an array, we need to make every element into JSON and then put them back in the array
			if ([val isKindOfClass:[NSArray class]])
			{
#ifdef NSRSendHasManyRelationAsHash
				NSMutableDictionary *new = [NSMutableDictionary dictionary];
#else
				NSMutableArray *new = [NSMutableArray arrayWithCapacity:[val count]];
#endif
				for (int i = 0; i < [val count]; i++)
				{
					id obj = [[val objectAtIndex:i] dictionaryOfRelevantProperties];
					if (!obj)
					{
						obj = [NSNull null];
					}
#ifdef NSRSendHasManyRelationAsHash
					[new setObject:obj forKey:[NSString stringWithFormat:@"%d",i]];
#else
					[new addObject:obj];
#endif
				}
				return new;
			}
			//otherwise, make it into JSON through dictionary method in RailsModel
			return [val dictionaryOfRelevantProperties];
		}
		
		//if NOT linked property, if its declared as encodable, return encoded version
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
#ifdef NSRLogErrors
			if (equiv.count > 1)
				NSLog(@"found multiple instance variables tied to one rails equivalent (%@ are all set to equal rails property '%@'). setting data for it into the first ivar listed, but please fix.",equiv,key);
#endif
		
			
			SEL sel = [self getIvarSetter:property];
			if ([self respondsToSelector:sel] && [retrievableProperties indexOfObject:property] != NSNotFound)
				//means its marked as retrievable and is settable through setEtc:.
			{
				id val = [dict objectForKey:key];
				val = [self objectForProperty:property representation:([val isKindOfClass:[NSNull class]] ? nil : val)];
				if (val)
				{
					NSString *relatedClass = [[modelRelatedProperties objectForKey:property] toClassName];
					//instantiate it as the class specified in MakeRails
					if (relatedClass)
					{
						//if the JSON conversion returned an array for the value, instantiate each element
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
					//TODO: maybe remove/enhance?
					// check to see if you're gonna enter a dictionary and ivar isn't a dict (ie custom class)
					NSString *ivarType = [self getIvarType:property];
					if ([val isKindOfClass:[NSDictionary class]]
						&& ![ivarType isEqualToString:@"NSDictionary"] && ![ivarType isEqualToString:@"NSMutableDictionary"])
					{
#ifdef NSRLogErrors
						NSLog(@"NOTE: entering NSDictionary into %@'s ivar '%@' (type = %@) -- types do not match up!!",property,ivarType,[self camelizedModelName]);
#endif
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
	//loop through all properties marked as sendable
	for (NSString *key in sendableProperties)
	{
		NSString *property = [propertyEquivalents objectForKey:key];
		
		id val = [self representationOfObjectForProperty:key];
		BOOL null = !val;
		if (!val && ![property isEqualToString:@"id"]) //if ID is null, simply bypass it, don't stick in "null" - it could be for create
		{
			NSString *string = [self getIvarType:key];
			if ([string isEqualToString:@"NSArray"] || [string isEqualToString:@"NSMutableArray"])
			{
				//there's an array, and because the value is nil, make it an empty array (rails will get angry if you send nil)
				val = [NSArray array];
			}
			else
			{
				val = [NSNull null];
			}
		}
		if (val)
		{
			if ([modelRelatedProperties objectForKey:key] && !null) //if its null/empty(for arrays), dont append _attributes
				property = [property stringByAppendingString:NSRAppendRelatedModelKeyOnSend];
			[dict setObject:val forKey:property];
		}
	}
	//if object is marked as destroy for nesting, add "_destroy"=>true to hash 
	if (destroyOnNesting)
	{
		[dict setObject:[NSNumber numberWithBool:destroyOnNesting] forKey:@"_destroy"];
	}

	return dict;
}

- (BOOL) setAttributesAsPerJSON:(NSString *)json
{
	NSDictionary *dict = [json JSONValue];
	
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
	//generate url based on base URL + route given
	NSString *url = [NSString stringWithFormat:@"%@/%@",appURL,route];
	
#ifdef NSRAutomaticallyMakeURLsLowercase
	url = [url lowercaseString];
#endif
	
	//log relevant stuff
#if NSRLog > 0
	NSLog(@" ");
	NSLog(@"%@ to %@",type,url);
#if NSRLog > 1
	NSLog(@"OUT===> %@",requestStr);
#endif
#endif
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
	
	[request setHTTPMethod:type];
	[request setHTTPShouldHandleCookies:NO];
	//set for json content
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	//if username & password set, assume basic HTTP authentication
	if (appUsername && appPassword)
	{
		//add auth header encoded in base64
		NSString *authStr = [NSString stringWithFormat:@"%@:%@", appUsername, appPassword];
		NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
		NSString *authHeader = [NSString stringWithFormat:@"Basic %@", [authData base64Encoding]];
		
		[request setValue:authHeader forHTTPHeaderField:@"Authorization"]; 
	}
	
	//if there's an actual request, add the body
	if (requestStr)
	{
		NSData *requestData = [NSData dataWithBytes:[requestStr UTF8String] length:[requestStr length]];

		[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody: requestData];
		[request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
 	}
	
	//send request!
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
	
	int statusCode = -1;
	BOOL err;
	NSString *result;
	//if no response, the server must be down and log an error
	if (!response || !data)
	{
		err = YES;
		statusCode = 0;
		result = [NSString stringWithFormat:@"Connection with %@ failed.",appURL];
	}
	else
	{
		//otherwise, get the statuscode from the response (it'll be an NSHTTPURLResponse but to be safe check if it responds)
		if ([response respondsToSelector:@selector(statusCode)])
		{
			statusCode = [((NSHTTPURLResponse *)response) statusCode];
		}
		err = (statusCode == -1 || statusCode >= 400);
		
		result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
		
#ifndef NSRCompileWithARC
		[request release];
		[result autorelease];
#endif
	
#if NSRLog > 1
		NSLog(@"IN<=== Code %d; %@\n\n",statusCode,(err ? @"[see ERROR]" : result));
		NSLog(@" ");
#endif
	}
	
	if (err)
	{
#ifdef NSRSuccinctErrorMessages
		//if error message is in HTML,
		if ([result rangeOfString:@"</html>"].location != NSNotFound)
		{
			NSArray *pres = [result componentsSeparatedByString:@"<pre>"];
			if (pres.count > 1)
			{
				//get the value between <pre> and </pre>
				result = [[[pres objectAtIndex:1] componentsSeparatedByString:@"</pre"] objectAtIndex:0];
				//some weird thing rails does, will send html tags &quot; for quotes
				result = [result stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
			}
		}
#endif
		
		//make a new error
		NSDictionary *inf = [NSDictionary dictionaryWithObject:result
														forKey:NSLocalizedDescriptionKey];
		NSError *statusError = [NSError errorWithDomain:@"rails"
												   code:statusCode
											   userInfo:inf];

		if (error)
		{
			*error = statusError;
		}

#if NSRLog > 0
		NSRLogError(statusError);
		NSLog(@" ");
#endif
		
#ifdef NSRCrashOnError
		[NSException raise:[NSString stringWithFormat:@"Rails error code %d",statusCode] format:result];
#endif
		
		return nil;
	}
	
	return result;
}


- (NSString *) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error
{
	//make request on instance, so set URL to be in format "users/1"
	NSString *route = [NSString stringWithFormat:@"%@/%@",[[self class] getPluralModelName], self.modelID];
	if (method.length > 0)
	{
		//if there's a method included too,
		//make sure sure there's no / starting the method string
		if ([[method substringToIndex:1] isEqualToString:@"/"])
			method = [method substringFromIndex:1];
		
		//tack the method onto the end
		route = [route stringByAppendingFormat:@"/%@",method];
	}
	
	return [RailsModel makeRequestType:httpVerb requestBody:requestStr route:route error:error];
}

- (NSString *) makeGETRequestWithMethod:(NSString *)method error:(NSError **)error
{
	return [self makeRequest:@"GET" requestBody:nil method:method error:error];
}

+ (NSString *) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error
{
	NSString *route;
	NSString *controller = [self getPluralModelName];
	if (controller)
	{
		//this means this method was called on a RailsMethod _subclass_, so appropriately point the method to its controller
		//eg, ([User makeGET:@"hello"] => myapp.com/users/hello)
		route = controller;
		if (method)
			route = [route stringByAppendingFormat:@"/%@", method];
	}
	else
	{
		//this means this method was called on RailsModel (to access a "root method")
		//eg, ([RailsModel makeGET:@"hello"] => myapp.com/hello)
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

- (BOOL) createRemote:(NSError **)error exclude:(NSArray *)exclude
{
	if (!self.modelID)
	{
#ifdef NSRLogErrors
		NSLog(@"error in creating %@ instance - object has no ID.",[self camelizedModelName]);
#endif
		return NO;
	}
	
	//we're gonna exclude whatever's in the "exclude" array, so remove from sendable props temporarily
	[sendableProperties removeObjectsInArray:exclude];
	//send a POST (for create) with myself in JSON
	NSString *json = [[self class] makeRequest:@"POST" requestBody:[self JSONRepresentation] method:nil error:error];
	//add properties back to sendable
	[sendableProperties addObjectsFromArray:exclude];
	
	
	//return true if json wasn't nil and if the setAttributes worked
	return (json && [self setAttributesAsPerJSON:json]);
}
- (BOOL) createRemote {	return [self createRemote:nil];	}
- (BOOL) createRemote:(NSError **)error {	return [self createRemote:error excluding:nil];	}
- (BOOL) createRemoteExcludingNilValues:(NSError **)error
{
	NSMutableArray *list = [NSMutableArray array];
	
	//go through each sendable property, see if it's nil, if it is, add it to the exclude list
	for (NSString *prop in sendableProperties)
		if (![self representationOfObjectForProperty:prop])
			[list addObject:prop];
	
	//run createRemote with the nil list as exclude
	return [self createRemote:error exclude:list];
}
- (BOOL) createRemote:(NSError **)error excluding:(NSString *)exc, ...
{	
	NSMutableArray *list = [NSMutableArray array];
	
	//just some fun with va_lists. actually the method that takes in the array might be more useful
	//go through va_arg and add it to the list,
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
	
	//then send it to the exclude method
	return [self createRemote:error exclude:list];
}

- (BOOL) checkForNilID:(NSError **)error
{
	//used as a helper for update/create
	//if no ID for this model, return error.
	if (!self.modelID)
	{
		NSError *e = [NSError errorWithDomain:@"rails" code:0 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Attempted to update or delete an object with no ID. (Instance of %@)",NSStringFromClass([self class])] forKey:NSLocalizedDescriptionKey]];
		if (error)
			*error = e;
		
#ifdef NSRLogErrors
		NSRLogError(e);
#endif
		return NO;
	}

	return YES;
}

- (BOOL) updateRemote:(NSError **)error exclude:(NSArray *)exclude
{
	if (![self checkForNilID:error])
		return NO;
	
	//exclude works same as above for create
	
	[sendableProperties removeObjectsInArray:exclude];
	BOOL success = !![self makeRequest:@"PUT" requestBody:[self JSONRepresentation] method:nil error:error];
	[sendableProperties addObjectsFromArray:exclude];
	
	return success;
}
- (BOOL) updateRemote {	return [self updateRemote:nil];	}
- (BOOL) updateRemote:(NSError **)error {	return [self updateRemote:error excluding:nil];	}
- (BOOL) updateRemoteExcludingNilValues:(NSError **)error
{
	//exclude works same as above for create

	NSMutableArray *list = [NSMutableArray array];
	
	for (NSString *prop in sendableProperties)
		if (![self representationOfObjectForProperty:prop])
			[list addObject:prop];
	
	return [self updateRemote:error exclude:list];
}
- (BOOL) updateRemote:(NSError **)error excluding:(NSString *)exc, ...
{	
	//exclude works same as above for create

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
	
	return [self updateRemote:error exclude:list];
}

- (BOOL) destroyRemote {	return [self destroyRemote:nil]; }
- (BOOL) destroyRemote:(NSError **)error
{
	if (![self checkForNilID:error])
		return NO;
	
	//makeRequest will actually return a result string, return if it's not nil (!! = not nil, nifty way to turn object to BOOL)
	return (!![self makeRequest:@"DELETE" requestBody:nil method:nil error:error]);
}

- (BOOL) getRemoteLatest {	return [self getRemoteLatest:nil]; }
- (BOOL) getRemoteLatest:(NSError **)error
{
	NSString *json = [self makeGETRequestWithMethod:nil error:error];
	if (!json)
	{
		return NO;
	}
	return ([self setAttributesAsPerJSON:json]); //will return true/false if conversion worked
}

+ (id) getRemoteObjectWithID:(int)mID	{ return [self getRemoteObjectWithID:mID error:nil]; }
+ (id) getRemoteObjectWithID:(int)mID error:(NSError **)error
{
	//instantiate the class
	RailsModel *obj = [[[self class] alloc] init];
	
	//set the ID to whatever was passed in - this will indicate where NSR should look on the server
	obj.modelID = [NSDecimalNumber numberWithInt:mID];
	
	//if the getRemote didn't work, make it nil
	if (![obj getRemoteLatest:error])
		obj = nil;
	
#ifndef NSRCompileWithARC
	[obj autorelease];
#endif

	return obj;
}

+ (NSArray *) getAllRemote {	return [self getAllRemote:nil]; }
+ (NSArray *) getAllRemote:(NSError **)error
{
	//make a class GET call (so just the controller - myapp.com/users)
	NSString *json = [self makeGETRequestWithMethod:nil error:error];
	
	if (!json)
	{
		return nil;
	}
	
	//transform result into array (via json)
	id arr = [json JSONValue];
	if (![arr isKindOfClass:[NSArray class]])
	{
#ifdef NSRLogErrors
		NSLog(@"getAll method (index) for %@ controller did not return an array - check your rails app.",[self getModelName]);
#endif
		return nil;
	}
	
	NSMutableArray *objects = [NSMutableArray array];
	
	//iterate through every object returned by Rails (as dicts)
	for (NSDictionary *dict in arr)
	{
		//make a new instance of this class for each dict,
		RailsModel *obj = [[[self class] alloc] init];	
		
		//and set its properties as per the dictionary defined in the json
		[obj setAttributesAsPerDictionary:dict];
		
		[objects addObject:obj];
		
#ifndef NSRCompileWithARC
		[obj release];
#endif
	}
	
	return objects;
}

- (NSString *) JSONRepresentation
{
	// enveloped meaning with the model name out front, {"user"=>{"name"=>"x", "password"=>"y"}}
	return [[self envelopedDictionaryOfRelevantProperties:[[self class] getModelName]] JSONRepresentation];
}

#ifndef NSRCompileWithARC

- (void) dealloc
{
	[modelID release];
	[attributes release];
	
	[sendableProperties release];
	[retrievableProperties release];
	[encodeProperties release];
	[decodeProperties release];
	[modelRelatedProperties release];
	[propertyEquivalents release];
	
	[super dealloc];
}

#endif

@end
