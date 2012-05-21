[![nsrails.com](http://i.imgur.com/3FFpT.png)](http://nsrails.com/)

***

NSRails is a light-weight Objective-C framework that provides your classes with a high-level, ActiveResource-like API. This means CRUD and other operations on your corresponding Rails objects can be called natively via Objective-C methods.

Instances will inherit methods to remotely create, read, update, or destroy a remote object:

```objc
Post *newPost = [[Post alloc] init];
newPost.author = @"Me";
newPost.content = @"Some text";
[newPost remoteCreate:&error];     //This post and its properties created right on a Rails server
```

Classes will inherit methods to retrieve all objects, or only certain ones:

```objc
NSArray *allPosts = [Post remoteAll:&error];
Post *postNumber1 = [Post remoteObjectWithID:1 error:&error];

// Display your article(s)! They're ready with their properties populated directly from your remote DB
```

Features
--------

* [High-level API](http://dingbat.github.com/nsrails/html/Classes/NSRailsModel.html), yet flexible enough even to work with any RESTful server
* [Highly customizable “syncing”](https://github.com/dingbat/nsrails/wiki/NSRailsSync) with your Rails attributes
* [Nesting](https://github.com/dingbat/nsrails/wiki/Nesting) supported for relations like has-many, belongs-to, etc
* [Asynchronous requests](http://dingbat.github.com/nsrails/html/Classes/NSRailsModel.html)
* [Autogenerate](https://github.com/dingbat/nsrails/tree/master/autogen) NSRails-ready classes from a Rails project
* [Supported in RubyMotion and MacRuby](https://github.com/dingbat/nsrails/tree/master/demos/rubymotion)

Getting started
---------

### Objective-C

1. Drop the `Source` folder into your Xcode project.
2. Make an Objective-C class for your Rails model. Make sure it subclasses **NSRailsModel** (you'll need to `#import NSRails.h`)

  ```objc
  #import "NSRails.h"

  @interface Post : NSRailsModel

  @property (nonatomic, strong) NSString *author, *content;
  @property (nonatomic, strong) NSDate *createdAt;
  
  @end
  ```

3. Somewhere in your app setup, set your server URL using the `defaultConfig` singleton:

  ```objc
  #import "NSRails.h"

  - (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
  {
        [[NSRConfig defaultConfig] setAppURL:@"http://localhost:3000"];
        ...
  ```
  
You're ready!
  
### RubyMotion & MacRuby

  * See [this](https://github.com/dingbat/nsrails/tree/master/demos/rubymotion) readme for instructions on getting started in Ruby

Getting warmed up
----------

By subclassing NSRailsModel, your class gets tons of instance and class methods that'll act on your remote objects. Here are a few of the things you can do with your new class:

```objc
//retrieve post with ID 1
Post *post = [Post remoteObjectWithID:1 error:&error];
post.content = @"Changed!";

//update this post remotely
[post remoteUpdate:&error];

//fetch any latest data for this post (the boolean reference will tell you if anything changed)
BOOL ch;
[post remoteFetch:&error changes:&ch];

//call custom method - would GET http://myapp.com/posts/1/something
[post remoteGET:@"something" error:&error];

//all of these are also available async:
[post remoteDestroyAsync: ^(NSError *error) 
                          {
                            if (!error)
                              ...
                          }];

```

See the [documentation](http://dingbat.github.com/nsrails/) for more details.

### NSRailsSync

Use the **NSRailsSync()** macro if you want to define special behaviors for certain properties:

```objc
@implementation Post
@synthesize author, content, createdAt, responses;
NSRailsSync(*, createdAt -r, responses:Response);

...
```

- The `*` includes all of this class's properties as remote-relevant (default if NSRailsSync isn't defined). 
- `createdAt -r` makes `createdAt` retrievable-only (so that it's never *sent* to Rails - only retrieved).
- `responses:Response` tells NSRails to fill the `responses` array with instances of the Response class (also an NSRailsModel subclass, whose NSRailsSync will also be considered when nested).


See the [NSRailsSync wiki page](https://github.com/dingbat/nsrails/wiki/NSRailsSync) for even more options!

Dependencies
--------

* iOS 5.0+ (ARC)
* JSON framework (pre-bundled)

Credits
----------

Version 1.0.

I'd like to acknowledge [SBJson](https://github.com/stig/json-framework) for great JSON reading and writing, and thank the [ObjectiveResource](https://github.com/yfactorial/objectiveresource) project for being largely the inspiration for NSRails.

License (MIT)
---------

Copyright (c) 2012 Dan Hassin.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.