//
//  NSRailsModel.m
//  NSRails
//
//  Created by Dan Hassin on 1/10/12.
//  Copyright (c) 2012 InContext LLC. All rights reserved.
//

#import "NSRails.h"

#import "NSString+InflectionSupport.h"
#import "NSData+Additions.h"
#import "NSObject+Properties.h"

// if it's too intimidating, remember that you can navigate this file quickly in xcode with #pragma marks


//this will be the NSRailsProperties for NSRailsModel
//tie modelID to rails property id
#define NSRAILS_BASE_PROPS @"modelID=id"


@interface NSRailsModel (internal)

+ (NSRConfig *) getRelevantConfig;

- (void) setAttributesAsPerDictionary:(NSDictionary *)dict;
- (NSDictionary *) dictionaryOfRelevantProperties;

+ (NSString *) railsProperties;
+ (NSString *) getModelName;
+ (NSString *) getPluralModelName;

@end

@interface NSRConfig (access)

+ (NSRConfig *) overrideConfig;
+ (void) crashWithError:(NSError *)error;
- (NSString *) resultForRequestType:(NSString *)type requestBody:(NSString *)requestStr route:(NSString *)route sync:(NSError **)error orAsync:(void(^)(NSString *result, NSError *error))completionBlock;

@end


@implementation NSRailsModel
@synthesize modelID, attributes, destroyOnNesting;






#pragma mark -
#pragma mark Meta-NSR stuff

//this will suppress the compiler warnings that come with ARC when doing performSelector
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"


+ (NSString *) NSRailsProperties
{
	return NSRAILS_BASE_PROPS;
}

+ (NSString *) railsProperties
{
	//this will be a master list of properties, including all superclasses
	//start it off with the NSRails base ("modelID=id")
	NSString *finalProperties = NSRAILS_BASE_PROPS;
	
	BOOL stopInheriting = NO;

	//go up the class hierarchy, starting at self, adding the property list from each class
	for (Class c = self; (c != [NSRailsModel class] && !stopInheriting); c = [c superclass])
	{
		if ([c respondsToSelector:@selector(NSRailsProperties)])
		{			
			//get that class's railsify string (properties)
			NSString *railsifyString = [c NSRailsProperties];
			
			//if that class defines NSRNoCarryFromSuper, mark that we should stop rising classes
			if ([railsifyString rangeOfString:_NSRNoCarryFromSuper_STR].location != NSNotFound)
			{
				//the for loop condition will fail
				stopInheriting = YES;
				
				//we strip the flag so that later on, we'll know exactly WHICH class defined the flag.
				//	otherwise, it'd be tacked on to every subclass.
				//this is why if this class is evaluating itself here, it shouldn't strip it, to signify that IT defined it
				if (c != self)
				{
					railsifyString = [railsifyString stringByReplacingOccurrencesOfString:_NSRNoCarryFromSuper_STR withString:@""];
				}
			}

			//tack the properties for that class onto our big list
			finalProperties = [finalProperties stringByAppendingFormat:@", %@", railsifyString];
		}
	}
	
	return finalProperties;
}

+ (NSString *) getModelName
{
	//if defined through NSRailsModelName() then use that instead
	SEL sel = @selector(NSRailsModelName);
	if ([self respondsToSelector:sel] && [self performSelector:sel])
	{
		return [self performSelector:sel];
	}
	
	//otherwise, return name of the class
	NSString *class = NSStringFromClass(self);
	if ([class isEqualToString:@"NSRailsModel"])
		class = nil;
	
	if ([self getRelevantConfig].automaticallyUnderscoreAndCamelize)
		return [[class underscore] lowercaseString];
	else
		return class;
}

+ (NSString *) getPluralModelName
{
	//if defined through NSRailsModelNameWithPlural(), use that instead
	SEL sel = @selector(NSRailsModelNameWithPlural);
	if ([self respondsToSelector:sel] && [self performSelector:sel])
	{
		return [self performSelector:sel];
	}
	//otherwise, pluralize ModelName
	return [[self getModelName] pluralize];
}

+ (NSRConfig *) getRelevantConfig
{
	//get the config for this class
	
	//if there's an overriding config in this context (an -[NSRConfig use] was called (explicitly or implicity via a block))
	//use the overrider
	if ([NSRConfig overrideConfig])
	{
		return [NSRConfig overrideConfig];
	}
	
	//if this class defines NSRailsSetConfigAuth, use it over whatever NSRailsSetConfig (no auth) is defined
	//moreover, if a subclass implements NSRailsUseDefaultConfig, it'll implement this method and simply return the default, as to override whatever a parents may declare this to be
	else if ([[self class] respondsToSelector:@selector(NSRailsSetConfigAuth)])
	{
		return [[self class] performSelector:@selector(NSRailsSetConfigAuth)];
	}
	else if ([[self class] respondsToSelector:@selector(NSRailsSetConfig)])
	{
		return [[self class] performSelector:@selector(NSRailsSetConfig)];
	} 
	
	//otherwise, use the default config
	else
	{
		return [NSRConfig defaultConfig];
	}
}

- (id) initWithRailsifyString:(NSString *)props
{
	if ((self = [super init]))
	{
		//log on param string for testing
		//NSLog(@"found props %@",props);
		
		//initialize property categories
		sendableProperties = [[NSMutableArray alloc] init];
		retrievableProperties = [[NSMutableArray alloc] init];
		nestedModelProperties = [[NSMutableDictionary alloc] init];
		propertyEquivalents = [[NSMutableDictionary alloc] init];
		encodeProperties = [[NSMutableArray alloc] init];
		decodeProperties = [[NSMutableArray alloc] init];
		
		destroyOnNesting = NO;
		
		//here begins the code used for parsing the NSRailsify param string
		
		//character set that'll be used later on
		NSCharacterSet *wn = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		
		//exclude array for any properties declared as -x (will later remove properties from * definition)
		NSMutableArray *exclude = [NSMutableArray array];
		
		//check to see if we should even consider *
		BOOL markedAll = ([props rangeOfString:@"*"].location != NSNotFound);
		
		//marked as NO for the first time in the loop
		//if a * appeared (markedAll is true), this will enable by the end of the loop and the whole thing will loop again, for the *
		BOOL onStarIteration = NO;
		
		do
		{
			NSMutableArray *elements;
			//if we're on the * run,
			if (onStarIteration)
			{
				//make sure we don't loop again
				onStarIteration = NO;
				markedAll = NO;
				
				NSMutableArray *relevantIvars = [NSMutableArray array];
				
				//start with the current class
				Class c = [self class];
				
				//loop going up the class hierarchy all the way up to NSRailsModel
				while (c != [NSRailsModel class])
				{
					//get the property list for that specific class
					NSString *properties = [c NSRailsProperties];
					
					//if there's a *, add all ivars from that class
					if ([properties rangeOfString:@"*"].location != NSNotFound)
						[relevantIvars addObjectsFromArray:[c classPropertyNames]];
					
					//if there's a NoCarryFromSuper, stop the loop right there since we don't want stuff from any more superclasses
					if ([properties rangeOfString:_NSRNoCarryFromSuper_STR].location != NSNotFound)
						break;
					
					//move up in the hierarchy for next iteration
					c = [c superclass];
				}
				
				
				elements = [NSMutableArray array];
				//go through all the ivars we found
				for (NSString *ivar in relevantIvars)
				{
					//if it hasn't been declared as -x or declared at all (from the first run), add it to the list we have to process
					if (![exclude containsObject:ivar] && ![propertyEquivalents objectForKey:ivar])
					{
						[elements addObject:ivar];
					}
				}
			}
			else
			{
				//if on the first run, split properties by commas ("username=user_name, password"=>["username=user_name","password"]
				elements = [NSMutableArray arrayWithArray:[props componentsSeparatedByString:@","]];
			}
			for (int i = 0; i < elements.count; i++)
			{
				NSString *str = [elements objectAtIndex:i];
				//remove any whitespace along with trailing NSRNoCarryFromSuper's to not screw anything up
				NSString *prop = [[str stringByTrimmingCharactersInSet:wn] stringByReplacingOccurrencesOfString:_NSRNoCarryFromSuper_STR withString:@""];
				
				if (prop.length > 0)
				{
					if ([prop rangeOfString:@"*"].location != NSNotFound)
					{
						//if there's a * in this piece, skip it (we already accounted for stars above)
						
						continue;
					}
					
					//prop can be something like "username=user_name:Class -etc"
					//find string sets between =, :, and -
					NSArray *opSplit = [prop componentsSeparatedByString:@"-"];
					NSArray *modSplit = [[opSplit objectAtIndex:0] componentsSeparatedByString:@":"];
					NSArray *eqSplit = [[modSplit objectAtIndex:0] componentsSeparatedByString:@"="];
					
					prop = [[eqSplit objectAtIndex:0] stringByTrimmingCharactersInSet:wn];
					
					//check to see if a class is redefining modelID (modelID from NSRailsModel is the first property checked - if it's not the first, give a warning)
					if ([prop isEqualToString:@"modelID"] && i > 0)
					{
#ifdef NSRLogErrors
						NSLog(@"NSR Warning: Found attempt to define 'modelID' in NSRailsify for class %@. This property is reserved by the NSRailsModel superclass and should not be modified. Please fix this; element ignored.", NSStringFromClass([self class]));
#endif
						continue;
					}
					
					NSString *options = [opSplit lastObject];
					if (opSplit.count > 1)
					{
						//if it was marked exclude, add to exclude list in case * was declared
						if ([options rangeOfString:@"x"].location != NSNotFound)
						{
							[exclude addObject:prop];
							continue;
						}
						
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
					
					//if no options are defined or some are but neither -s nor -r are defined, by default add sendable+retrievable
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
								NSLog(@"NSR Warning: Failed to find class for nested model %@ (declared for property %@ of class %@) - please fix this. Nesting relation not set. ",otherModel,prop,NSStringFromClass([self class]));
#endif
							}
							//class entered is not a subclass of NSRailsModel
							else if (![NSClassFromString(otherModel) isSubclassOfClass:[NSRailsModel class]])
							{
#ifdef NSRLogErrors
								NSLog(@"NSR Warning: %@ was declared for the nested model property %@ of class %@, but %@ is not a subclass of NSRailsModel - please fix this. Nesting relation not set.",otherModel,prop, NSStringFromClass([self class]),otherModel);
#endif
							}
							else
								[nestedModelProperties setObject:otherModel forKey:prop];
						}
					}
					else
					{
						//if no : was declared for this property, check to see if we should link it anyway
						NSString *ivarType = [self getPropertyType:prop];
						
						if ([ivarType isEqualToString:@"NSArray"] ||
							[ivarType isEqualToString:@"NSMutableArray"])
						{
#if NSRLog > 2
							NSLog(@"NSR Warning: Property '%@' in class %@ was found to be an array, but no nesting model was set. Note that without knowing with which models NSR should populate the array, NSDictionaries with the retrieved Rails attributes will be set. If NSDictionaries are desired, to suppress this warning, simply add a colon with nothing following to the property in NSRailsify... '%@:'",prop,NSStringFromClass([self class]),str);
#endif
						}
						else if (!([ivarType isEqualToString:@"NSString"] ||
								   [ivarType isEqualToString:@"NSMutableString"] ||
								   [ivarType isEqualToString:@"NSDictionary"] ||
								   [ivarType isEqualToString:@"NSMutableDictionary"] ||
								   [ivarType isEqualToString:@"NSNumber"] ||
								   [ivarType isEqualToString:@"NSDate"]))
						{
							//must be custom obj, see if its a railsmodel, if it is, link it automatically
							Class c = NSClassFromString(ivarType);
							if (c && [c isSubclassOfClass:[NSRailsModel class]])
							{
								//automatically link that ivar type (ie, Pet) for that property (ie, pets)
								[nestedModelProperties setObject:ivarType forKey:prop];
							}
						}
					}
					
					//see if there are any = declared
					NSString *equivalent = prop;
					if (eqSplit.count > 1)
					{
						//set the equivalence to the last element after the =
						equivalent = [[eqSplit lastObject] stringByTrimmingCharactersInSet:wn];
						
						[propertyEquivalents setObject:equivalent forKey:prop];
					}
					else
					{
						//if no property explicitly set, make it blank
						//later on we'll see if automaticallyCamelize is on for the config and get the equivalence accordingly
						[propertyEquivalents setObject:@"" forKey:prop];
					}
				}
			}

			//if markedAll (a * was encountered somewhere), loop again one more time to add all properties not already listed (*)
			if (markedAll)
				onStarIteration = YES;
		} 
		while (onStarIteration);
		
	// for testing's sake
//		NSLog(@"-------- %@ ----------",[[self class] getModelName]);
//		NSLog(@"list: %@",props);
//		NSLog(@"sendable: %@",sendableProperties);
//		NSLog(@"retrievable: %@",retrievableProperties);
//		NSLog(@"NMP: %@",nestedModelProperties);
//		NSLog(@"eqiuvalents: %@",propertyEquivalents);
//		NSLog(@"\n");
	}

	return self;
}

- (id) init
{
	//read in properties defined through NSRailsProperties
	NSString *props = [[self class] railsProperties];
	
	if ((self = [self initWithRailsifyString:props]))
	{
	}
	return self;
}





#pragma mark -
#pragma mark Internal NSR stuff

- (NSString *) description
{
	return [attributes description];
}

- (NSString *) JSONRepresentation
{
	return [self JSONRepresentation:nil];
}

- (NSString *) JSONRepresentation:(NSError **)e
{
	// enveloped meaning with the model name out front, {"user"=>{"name"=>"x", "password"=>"y"}}

	NSDictionary *enveloped = [NSDictionary dictionaryWithObject:[self dictionaryOfRelevantProperties]
														  forKey:[[self class] getModelName]];
	
	NSString *json = [enveloped JSONRepresentation:e];
	if (!json)
		[NSRConfig crashWithError:*e];
	return json;
}

- (id) makeRelevantModelFromClass:(NSString *)classN basedOn:(NSDictionary *)dict
{
	//make a new class to be entered for this property/array (we can assume it subclasses RM)
	NSRailsModel *model = [[NSClassFromString(classN) alloc] init];
	if (!model)
	{
#ifdef NSRLogErrors
		NSLog(@"NSR Warning: Could not find %@ class to nest into class %@; leaving property null.",classN, NSStringFromClass([self class]));
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
	//if the object is of class NSDate and the representation in JSON is a string, automatically convert it to string
	else if ([[self getPropertyType:prop] isEqualToString:@"NSDate"] && [rep isKindOfClass:[NSString class]])
	{
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		
		//format to whatever date format is defined in the config
		NSString *format = [[self class] getRelevantConfig].dateFormat;
		[formatter setDateFormat:format];
		
		NSDate *date = [formatter dateFromString:rep];

		if (!date)
		{
#ifdef NSRLogErrors
			NSLog(@"NSR Warning: Attempted to convert date string returned by Rails (%@) into an NSDate* object for the property '%@' in class %@, but conversion failed. Please check your config's dateFormat (using format \"%@\" for this operation).",rep,prop,NSStringFromClass([self class]),format);
#endif
		}
		
#ifndef NSRCompileWithARC
		[formatter release];
#endif
		return date;
	}
	
	//otherwise, return whatever it is
	return rep;
}

- (id) representationOfObjectForProperty:(NSString *)prop
{
	//get the value of the property
	SEL sel = [self getPropertyGetter:prop];
	if ([self respondsToSelector:sel])
	{
		id val = [self performSelector:sel];
		
		//see if this property actually links to a custom NSRailsModel subclass
		if ([nestedModelProperties objectForKey:prop])
		{
			//if the ivar is an array, we need to make every element into JSON and then put them back in the array
			if ([val isKindOfClass:[NSArray class]])
			{
				NSMutableArray *new = [NSMutableArray arrayWithCapacity:[val count]];
				//go through every nested object in the array
				for (int i = 0; i < [val count]; i++)
				{
					//use the NSRailsModel instance method -dictionaryOfRelevantProperties to get that object back in dictionary form
					id obj = [[val objectAtIndex:i] dictionaryOfRelevantProperties];
					if (!obj)
					{
						obj = [NSNull null];
					}
					[new addObject:obj];
				}
				return new;
			}
			//otherwise, make that nested object a dictionary through NSRailsModel
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
		//if the object is of class NSDate, we need to automatically convert it to string for the JSON framework to handle correctly
		else if ([val isKindOfClass:[NSDate class]])
		{
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			
			//format to whatever date format is defined in the config
			[formatter setDateFormat:[[self class] getRelevantConfig].dateFormat];
			
			NSString *dateValue = [formatter stringFromDate:val];
			
#ifndef NSRCompileWithARC
			[formatter release];
#endif
			return dateValue;
		}
		
		return val;
	}
	return nil;
}

- (void) setAttributesAsPerDictionary:(NSDictionary *)dict
{
	attributes = dict;
	
	for (NSString *objcProperty in retrievableProperties)
	{
		NSString *railsEquivalent = [propertyEquivalents objectForKey:objcProperty];
		if (railsEquivalent.length == 0)
		{
			//means there was no equivalence defined.
			//if config supports underscoring and camelizing, guess the rails equivalent by underscoring
			if ([[self class] getRelevantConfig].automaticallyUnderscoreAndCamelize)
			{
				railsEquivalent = [objcProperty underscore];
			}
			//otherwise, assume that the rails equivalent is precisely how it's defined in obj-c
			else
			{
				railsEquivalent = objcProperty;
			}
		}
		SEL sel = [self getPropertySetter:objcProperty];
		if ([self respondsToSelector:sel])
			//means its marked as retrievable and is settable through setEtc:.
		{
			id val = [dict objectForKey:railsEquivalent];
			//skip if the key doesn't exist (we probably guessed wrong above (or if the explicit equivalence was wrong))
			if (!val)
				continue;
			
			//get the intended value
			val = [self objectForProperty:objcProperty representation:([val isKindOfClass:[NSNull class]] ? nil : val)];
			if (val)
			{
				NSString *nestedClass = [[nestedModelProperties objectForKey:objcProperty] toClassName];
				//instantiate it as the class specified in NSRailsProperties
				if (nestedClass)
				{
					//if the JSON conversion returned an array for the value, instantiate each element
					if ([val isKindOfClass:[NSArray class]])
					{
						NSMutableArray *array = [NSMutableArray array];
						for (NSDictionary *dict in val)
						{
							id model = [self makeRelevantModelFromClass:nestedClass basedOn:dict];
							[array addObject:model];
						}
						val = array;
					}
					//if it's not an arry and just a dict, make a new class based on that dict
					else
					{
						val = [self makeRelevantModelFromClass:nestedClass basedOn:[dict objectForKey:railsEquivalent]];
					}
				}
				//if there was no nested class specified, simply give it what JSON decoded (in the case of a nested model, it will be a dictionary, or, an array of dictionaries. don't worry, the user got ample warning)
				[self performSelector:sel withObject:val];
			}
			else
			{
				[self performSelector:sel withObject:nil];
			}
		}
	}
}

- (NSDictionary *) dictionaryOfRelevantProperties
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	//loop through all properties marked as sendable
	for (NSString *objcProperty in sendableProperties)
	{
		NSString *railsEquivalent = [propertyEquivalents objectForKey:objcProperty];
		
		//if the equivalence is blank, means there was none explicitly set
		if (railsEquivalent.length == 0)
		{
			//if automaticallyUnderscoreAndCamelize for this config, use underscore+lowercase'd version of it
			if ([[self class] getRelevantConfig].automaticallyUnderscoreAndCamelize)
			{
				railsEquivalent = [[objcProperty underscore] lowercaseString];
			}
			//otherwise, use exactly the property name
			else
			{			
				railsEquivalent = objcProperty;
			}
		}
		
		id val = [self representationOfObjectForProperty:objcProperty];
		BOOL null = !val;
		if (!val && ![railsEquivalent isEqualToString:@"id"]) 
			//if ID is null, simply bypass it, don't stick in "null" - it could be for create
		{
			NSString *string = [self getPropertyType:objcProperty];
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
			if ([nestedModelProperties objectForKey:objcProperty] && !null) //if its null/empty(for arrays), dont append _attributes
				railsEquivalent = [railsEquivalent stringByAppendingString:@"_attributes"];
			//check to see if it was already set (ie, there are multiple properties pointing to the same rails attr)
			if ([dict objectForKey:railsEquivalent])
			{
				if ([railsEquivalent isEqualToString:@"id"])
				{
#ifdef NSRLogErrors
					NSLog(@"NSR Warning: Obj-C property %@ (class %@) found to set equivalence with 'id'. this is fine for retrieving but should not be marked as sendable. Ignoring this property on send.", objcProperty, NSStringFromClass([self class]));
#endif
				}
				else
				{
#ifdef NSRLogErrors
					NSLog(@"NSR Warning: Multiple Obj-C properties found pointing to the same Rails attribute (%@). Only using data from the first Obj-C property listed. Please fix by only having one sendable property per Rails attribute (you can make the others retrieve-only with the -r flag).", railsEquivalent);
#endif
				}
			}
			else
			{
				[dict setObject:val forKey:railsEquivalent];
			}
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
	if (!json)
	{
		NSLog(@"NSR Warning: Can't set attributes to nil JSON");
		return NO;
	}
	
	NSError *e;
	NSDictionary *dict = [json JSONValue:&e];
	
	if (!dict)
	{
		[NSRConfig crashWithError:e];
		return NO;
	}
	
	[self setAttributesAsPerDictionary:dict];
	
	return YES;
}

//pop the warning suppressor defined above (for calling performSelector's in ARC)
#pragma clang diagnostic pop




#pragma mark -
#pragma mark HTTP Request stuff

+ (NSString *) routeForMethod:(NSString *)method
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
		//this means this method was called on NSRailsModel (to access a "root method")
		//eg, ([NSRailsModel makeGET:@"hello"] => myapp.com/hello)
		route = method;
	}
	
	return route;
}

- (NSString *) routeForInstanceMethod:(NSString *)method
{
	//make request on instance, so set "method" for above method to be "1", or "1/method" if there's a method included
	NSString *idAndMethod = [NSString stringWithFormat:@"%@%@",self.modelID,(method ? [@"/" stringByAppendingString:method] : @"")];
	
	return [[self class] routeForMethod:idAndMethod];
}


#pragma mark Performing actions on instances

- (NSString *) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error
{
	return [[[self class] getRelevantConfig] makeRequestType:httpVerb requestBody:requestStr route:[self routeForInstanceMethod:method] sync:error orAsync:nil];
}

- (void) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method async:(void(^)(NSString *result, NSError *error))block
{
	[[[self class] getRelevantConfig] makeRequestType:httpVerb requestBody:requestStr route:[self routeForInstanceMethod:method] sync:nil orAsync:block];
}

//these are really just convenience methods that'll call the above method with pre-built "GET" and no body

- (NSString *) makeGETRequestWithMethod:(NSString *)method error:(NSError **)error
{
	return [self makeRequest:@"GET" requestBody:nil method:[self routeForInstanceMethod:method] error:error];
}
- (void) makeGETRequestWithMethod:(NSString *)method async:(void(^)(NSString *result, NSError *error))completionBlock
{
	[self makeRequest:@"GET" requestBody:nil method:[self routeForInstanceMethod:method] async:completionBlock];
}


#pragma mark Performing actions on classes


+ (void) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method async:(void (^)(NSString *result, NSError *))block
{ 
	[[self getRelevantConfig] makeRequestType:httpVerb requestBody:requestStr route:[self routeForMethod:method] sync:nil orAsync:block];
}
+ (NSString *) makeRequest:(NSString *)httpVerb requestBody:(NSString *)requestStr method:(NSString *)method error:(NSError **)error
{ 
	return [[self getRelevantConfig] makeRequestType:httpVerb requestBody:requestStr route:[self routeForMethod:method] sync:error orAsync:nil];
}

//these are really just convenience methods that'll call the above method with pre-built "GET" and no body

+ (void) makeGETRequestWithMethod:(NSString *)method async:(void (^)(NSString *result, NSError *))completionBlock
{ 
	[self makeRequest:@"GET" requestBody:nil method:method async:completionBlock];
}
+ (NSString *) makeGETRequestWithMethod:(NSString *)method error:(NSError **)error
{ 
	return [self makeRequest:@"GET" requestBody:nil method:method error:error];
} 







#pragma mark -
#pragma mark External stuff (CRUD)

- (BOOL) checkForNilID:(NSError **)error
{
	//used as a helper for update/create
	//if no ID for this model, return error.
	if (!self.modelID)
	{
		NSError *e = [NSError errorWithDomain:@"NSRails" code:0 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Attempted to update or delete an object with no ID. (Instance of %@)",NSStringFromClass([self class])] forKey:NSLocalizedDescriptionKey]];
		if (error)
			*error = e;
		
		[NSRConfig crashWithError:e];
		return NO;
	}

	return YES;
}

#pragma mark Create

- (BOOL) createRemote {	return [self createRemote:nil];	}
- (BOOL) createRemote:(NSError **)error
{
	NSString *jsonBody = [self JSONRepresentation:error];
	if (*error)
		return NO;
	
	NSString *jsonResponse = [[self class] makeRequest:@"POST" requestBody:jsonBody method:nil error:error];
	
	//check to see if json exists, and if it does, set all of my attributes to it (like to add the new ID), and return if it worked
	return (jsonResponse && [self setAttributesAsPerJSON:jsonResponse]);
}
- (void) createRemoteAsync:(void (^)(NSError *))completionBlock
{
	NSError *jsonError;
	NSString *jsonBody = [self JSONRepresentation:&jsonError];
	if (!jsonBody)
	{
		completionBlock(jsonError);
	}
	else
	{
		[[self class] makeRequest:@"POST" requestBody:jsonBody method:nil async:^(NSString *result, NSError *error) 
		{
			if (result)
				[self setAttributesAsPerJSON:result];
			completionBlock(error);
		}];
	}
}

#pragma mark Update

- (BOOL) updateRemote {	return [self updateRemote:nil];	}
- (BOOL) updateRemote:(NSError **)error
{
	if (![self checkForNilID:error])
		return NO;
	
	NSString *jsonBody = [self JSONRepresentation:error];
	if (*error)
		return NO;
	
	//makeRequest will actually return a result string, return if it's not nil (!! = not nil, nifty way to turn object to BOOL)
	return !![self makeRequest:@"PUT" requestBody:jsonBody method:nil error:error];
}
- (void) updateRemoteAsync:(void (^)(NSError *))completionBlock
{
	NSError *error;
	if (![self checkForNilID:&error])
	{
		completionBlock(error);
	}
	else
	{
		NSError *jsonError;
		NSString *jsonBody = [self JSONRepresentation:&jsonError];
		if (!jsonBody)
		{
			completionBlock(jsonError);
		}
		else
		{
			[self makeRequest:@"PUT" requestBody:jsonBody method:nil async:^(NSString *result, NSError *error) 
			{
				completionBlock(error);
			}];
		}
	}
}

#pragma mark Destroy

- (BOOL) destroyRemote { return [self destroyRemote:nil]; }
- (BOOL) destroyRemote:(NSError **)error
{
	if (![self checkForNilID:error])
		return NO;
	
	return (!![self makeRequest:@"DELETE" requestBody:nil method:nil error:error]);
}
- (void) destroyRemoteAsync:(void (^)(NSError *))completionBlock
{
	NSError *error;
	if (![self checkForNilID:&error])
	{
		completionBlock(error);
	}
	else
	{
		[self makeRequest:@"DELETE" requestBody:nil method:nil async:^(NSString *result, NSError *error) {
			completionBlock(error);
		}];
	}
}

#pragma mark Get latest

- (BOOL) getRemoteLatest {	return [self getRemoteLatest:nil]; }
- (BOOL) getRemoteLatest:(NSError **)error
{
	NSString *json = [self makeGETRequestWithMethod:nil error:error];
	return (json && [self setAttributesAsPerJSON:json]); //will return true/false if conversion worked
}
- (void) getRemoteLatestAsync:(void (^)(NSError *error))completionBlock
{
	[self makeGETRequestWithMethod:nil async:^(NSString *result, NSError *error) 
	{
		if (result)
			[self setAttributesAsPerJSON:result];
		completionBlock(error);
	}];
}

#pragma mark Get specific object (class-level)

+ (id) getRemoteObjectWithID:(int)mID	{ return [self getRemoteObjectWithID:mID error:nil]; }
+ (id) getRemoteObjectWithID:(int)mID error:(NSError **)error
{
	//instantiate the class
	NSRailsModel *obj = [[[self class] alloc] init];
	
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
+ (void) getRemoteObjectWithID:(int)mID async:(void (^)(id object, NSError *error))completionBlock
{
	//see comments for previous method
	NSRailsModel *obj = [[[self class] alloc] init];
	obj.modelID = [NSDecimalNumber numberWithInt:mID];
	
#ifndef NSRCompileWithARC
	[obj autorelease];
#endif
	
	[obj getRemoteLatestAsync:^(NSError *error) {
		if (error)
			completionBlock(nil, error);
		else
			completionBlock(obj, error);
	}];
}

#pragma mark Get all objects (class-level)

+ (NSArray *) arrayOfModelsFromJSON:(NSString *)json error:(NSError **)error
{
	NSError *jsonError;
	
	//transform result into array (via json)
	id arr = [json JSONValue:&jsonError];
	
	if (!arr)
	{
		*error = jsonError;
		return nil;
	}
	
	//helper method for both sync+async for getAllRemote
	if (![arr isKindOfClass:[NSArray class]])
	{
		NSError *e = [NSError errorWithDomain:@"NSRails" 
										 code:0 
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"getAll method (index) for %@ controller did not return an array - check your rails app.",[self getPluralModelName]]
																		  forKey:NSLocalizedDescriptionKey]];
		
		if (error)
			*error = e;
		
		[NSRConfig crashWithError:e];
		
		return nil;
	}
	
	NSMutableArray *objects = [NSMutableArray array];
	
	//iterate through every object returned by Rails (as dicts)
	for (NSDictionary *dict in arr)
	{
		//make a new instance of this class for each dict,
		NSRailsModel *obj = [[[self class] alloc] init];	
		
		//and set its properties as per the dictionary defined in the json
		[obj setAttributesAsPerDictionary:dict];
		
		[objects addObject:obj];
		
#ifndef NSRCompileWithARC
		[obj release];
#endif
	}
	
	return objects;
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
	return [self arrayOfModelsFromJSON:json error:error];
}

+ (void) getAllRemoteAsync:(void (^)(NSArray *, NSError *))completionBlock
{
	[self makeGETRequestWithMethod:nil async:^(NSString *result, NSError *error) 
	{
		if (error || !result)
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




#pragma mark -
#pragma mark Dealloc for non-ARC
#ifndef NSRCompileWithARC

- (void) dealloc
{
	[modelID release];
	[attributes release];
	
	[sendableProperties release];
	[retrievableProperties release];
	[encodeProperties release];
	[decodeProperties release];
	[nestedModelProperties release];
	[propertyEquivalents release];
	
	[super dealloc];
}

#endif

@end
