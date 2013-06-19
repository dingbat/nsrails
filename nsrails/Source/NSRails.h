/*
 
 _|_|_|    _|_|  _|_|  _|_|  _|  _|      _|_|   
 _|  _|  _|_|    _|    _|_|  _|  _|_|  _|_|    v2.0.3
 
 NSRails.h
 
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

// CoreData
// ============
// #define NSR_USE_COREDATA

// Uncomment the line above if you want to enable CoreData
// You can also add NSR_USE_COREDATA to "Preprocessor Macros Not Used in Precompiled Headers" in your target's build settings
//   See http://dingbat.github.com/nsrails/Classes/NSRRemoteManagedObject.html for more details


// Logging
// =============
//					As undefined, NSRails will log nothing
// #define NSRLog 1	//As 1, NSRails will log HTTP verbs with their outgoing URLs, as well as any server errors 
#define NSRLog 2	//As 2, NSRails will also log any JSON going out/coming in


// Imports
// =============
#import "NSRConfig.h"
#import "NSRRemoteObject.h"
#import "NSRRemoteManagedObject.h"
#import "NSMutableArray+NSRails.h"
#import "NSRRequest.h"

