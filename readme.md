[![nsrails.com](http://i.imgur.com/3FFpT.png)](http://nsrails.com/)

***

NSRails is a light-weight Objective-C framework that provides your classes with a high-level, ActiveResource-like API. This means CRUD and other operations on your corresponding Rails objects can be called natively via Objective-C methods.

Instances will inherit methods to remotely create, read, update, or destroy a remote object:

```objc
Post *newPost = [[Post alloc] init];
newPost.author = @"Me";
newPost.content = @"Some text";
[newPost remoteCreate:&error];     // This post and its properties created right on a Rails server
```

Classes will inherit methods to retrieve all objects, or only certain ones:

```objc
NSArray *allPosts = [Post remoteAll:&error];
Post *postNumber1 = [Post remoteObjectWithID:1 error:&error];

// Display your article(s)! They're ready with their properties populated directly from your remote DB
```

Features
--------

* High-level API, yet flexible enough even to work with any RESTful server
* Highly customizable property behaviors and nesting
* Asynchronous requests
* [Autogenerate](https://github.com/dingbat/nsrails/tree/master/autogen) NSRails-ready classes from a Rails project
* Fully supported in RubyMotion and MacRuby

Quick links
--------

* [Documentation](http://dingbat.github.com/nsrails)
* [CoreData guide](http://dingbat.github.com/nsrails/Classes/NSRRemoteManagedObject.html)
* [Cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook)

Getting started
---------

### Objective-C

1. Drop the `Source` folder into your Xcode project. You'll also need the CoreData framework linked in Build Phases.
  * If you're using Git, you should add NSRails as a submodule to your project so you can `git pull` and always be up to date:
   
      ```
      $ git submodule add git@github.com:dingbat/nsrails.git NSRails
      ```
  
      This will clone the entire NSRails repo, but you'll only need to add `nsrails/Source` to your project in Xcode.

2. Make an Objective-C class for your Rails model and have it subclass **NSRRemoteObject** (you'll need to `#import NSRails.h`)

  ```objc
  #import "NSRails.h"

  @interface Post : NSRRemoteObject

  @property (nonatomic, strong) NSString *author, *content;
  @property (nonatomic, strong) NSDate *createdAt;
  
  @end
  ```

3. Somewhere in your app setup, set your server URL using the `defaultConfig` singleton:

  ```objc
  #import "NSRails.h"

  - (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
  {
        [NSRConfig defaultConfig].appURL = @"http://localhost:3000";
        ...
  }
  ```

4. By subclassing NSRRemoteObject, your class gets tons of instance and class methods that'll act on your remote objects. Here are a few of the things you can do with your new class:

	```objc
	// Retrieve post with ID 1
	Post *post = [Post remoteObjectWithID:1 error:&error];

	// Update this post remotely
	post.content = @"Changed!";
	[post remoteUpdate:&error];

	// Fetch any latest data for this post (and know if anything changed)
	BOOL objectDidChange;
	[post remoteFetch:&error changes:&objectDidChange];

	// Retrieve a collection based on an object - will GET /posts/1/responses.json
	NSArray *responses = [Response remoteAllViaObject:post error:&error];

	// Async is also available:
	[post remoteDestroyAsync: ^(NSError *error) {  if (!error) ... }];
	```

	See the [documentation](http://dingbat.github.com/nsrails/) for more on what you can do with your new class, or the [cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook) for quick NSRRemoteObject recipes.
    
### Ruby

1. Vendor NSRails. The following steps are for **RubyMotion**. **MacRuby** is easier to configure - simply drag the `Source` folder into Xcode in your MacRuby project, and NSRails should be built with your project as normal.
  * Add a `vendor` directory on the main level of your RubyMotion app if you don't have one already
  * Copy the `nsrails` directory ([the one with the main Xcode project](https://github.com/dingbat/nsrails/tree/master/nsrails)) into `vendor`. (You can delete `Tests/`, but keep `Source/` and the Xcode project file).
  * Modify your Rakefile to include NSRails and the CoreData framework:

	  ```ruby
	  Motion::Project::App.setup do |app|
	      # Add CoreData as a linked framework (required even if CoreData isn't used)
	      app.frameworks << "CoreData"

	      # Add this line:
	      app.vendor_project('vendor/nsrails', :xcode, :target => 'NSRails', :headers_dir => 'Source')
	      # OR this line, if you wish to use NSRails with CoreData
	      #app.vendor_project('vendor/nsrails', :xcode, :target => 'NSRailsCD', :headers_dir => 'Source')

	      ...
	  end
	  ```

2. Make a Ruby class for your Rails model and have it subclass **NSRRemoteObject**

	```ruby
	class Post < NSRRemoteObject
	  attr_accessor :author, :content, :created_at

	  # Since Ruby only creates instance variables during runtime, properties have to be explicit
	  def remoteProperties
	    super + ["author", "content", "created_at"]
	  end
	end
	```

3. Setup. This can go in `app_delegate.rb`:

	```ruby
	NSRConfig.defaultConfig.appURL = "http://localhost:3000"

	# don't look for camelCase when receiving remote underscored_properties, since we're in ruby
	NSRConfig.defaultConfig.autoinflectsPropertyNames = false
	```
	
4. Have fun!

	```ruby
	# get all posts (synchronously)
	error_ptr = Pointer.new(:object)
	posts = Post.remoteAll(error_ptr)
	if !posts
	  error = error_ptr[0]
	  ...
	end

	# get all posts (asynchronously)
	Post.remoteAllAsync(lambda do |posts, error| 
	                      ...
	                    end)
	```
	
	See the [documentation](http://dingbat.github.com/nsrails/) for more on what you can do with your new class, or the [cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook) for quick NSRRemoteObject recipes.


Dependencies
--------

* **iOS 5.0+**
* **Automatic Reference Counting (ARC)**: If your project isn't using ARC, you'll need to selectively specify it for NSRails. Go to your active target, select the "Build Phases" tab, and in the "Compile Sources" section, set `-fobjc-arc` as a compiler flag for each NSRails source file.

Credits
----------

Version 2.0.

A lot of NSRails was inspired by the [ObjectiveResource](https://github.com/yfactorial/objectiveresource) project. Thanks!

License (MIT)
---------

Copyright (c) 2012 Dan Hassin.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.