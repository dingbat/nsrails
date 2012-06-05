/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|           
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_| 
 
 NSRMacros.h
 
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

/// Can anyone help? How can I make this its own page in Appledoc?


/// =============================================================================================
/// @name NSRMap
/// =============================================================================================

//helper for macro -> NSString
//adding a # before anything will simply make it a cstring
#define _MAKE_STR(...) \
	[NSString stringWithCString:(#__VA_ARGS__) encoding:NSUTF8StringEncoding]

//define to create a method called NSRMap, which returns the entire param list
#define NSRMap(...) \
	+ (NSString*) NSRMap { return _MAKE_STR(__VA_ARGS__); }

//define to use NSRMap, just pass in NSRNoCarryFromSuper as well (will be picked up later)
#define NSRMapNoInheritance(...) \
	NSRMap(__VA_ARGS__ NSRNoCarryFromSuper)

//returns the string version of NSRNoCarryFromSuper so we can find it when evaluating NSRMap string
#define _NSRNoCarryFromSuper_STR \
	_MAKE_STR(NSRNoCarryFromSuper)


/// =============================================================================================
/// @name NSRUseModelName
/// =============================================================================================

//helper trick to allow "overloading" macro functions thanks to orj's gist: https://gist.github.com/985501
//definitely check out how this works - it's cool
#define _CAT(a, b) _PRIMITIVE_CAT(a, b)
#define _PRIMITIVE_CAT(a, b) a##b
#define _N_ARGS(...) _N_ARGS_1(__VA_ARGS__, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0)
#define _N_ARGS_1(...) _N_ARGS_2(__VA_ARGS__)
#define _N_ARGS_2(x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16, n, ...) n

//define to concat either _NSR_Name1(x) or _NSR_Name2(x,y), depending on the number of args passed in
#define NSRUseModelName(...) \
	_CAT(_NSR_Name,_N_ARGS(__VA_ARGS__))(__VA_ARGS__)

//_NSR_Name1 (only with 1 parameter, ie, custom model name but default plurality), creates NSRUseModelName method that returns param, return nil for plural to make it go to default
#define _NSR_Name1(name) \
	_NSR_Name2((name), nil)

//_NSR_Name2 (2 parameters, ie, custom model name and custom plurality), creates NSRUseModelName and NSRUsePluralName
#define _NSR_Name2(name,plural) \
	+ (NSString*) NSRUseModelName { return (name); } \
	+ (NSString*) NSRUsePluralName { return (plural); }


/// =============================================================================================
/// @name NSRUseResourcePrefix
/// =============================================================================================

//define to concat either _NSR_Prefix1(x) or _NSR_Prefix2(x,...), depending on the number of args passed in
#define NSRUseResourcePrefix(...) \
	_CAT(_NSR_Prefix,_N_ARGS(__VA_ARGS__))(__VA_ARGS__)

#define _NSR_Prefix1(member) \
	_NSR_Prefix((member), nil)

//optional list of methods that this would apply to - simply return them as an array
#define _NSR_Prefix2(member, ...) \
	_NSR_Prefix((member), ([NSArray arrayWithObjects:__VA_ARGS__,nil]))

//define to return an instance variable whose controller name and ID shall be used as a prefix to path
//      and return an array of HTTP verbs where this will be used
#define _NSR_Prefix(member, array) \
	- (NSRRemoteObject *) NSRUseResourcePrefix { return member; }; \
	- (NSArray *) NSRUseResourcePrefixMethods { return array; }


