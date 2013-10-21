[![nsrails.com](http://i.imgur.com/3FFpT.png)](http://nsrails.com/)

***

NSRails is a light-weight Objective-C framework that provides your classes with a high-level, ActiveResource-like API. This means CRUD and other operations on your corresponding Rails objects can be called natively via Objective-C methods.

Instances will inherit methods to remotely create, read, update, or destroy a remote object:

```objc
Post *newPost = [[Post alloc] init];
newPost.author = @"Me";
newPost.content = @"Some text";
// Create this post with its properties right on a Rails server
// POST /posts.json
[newPost remoteCreateAsync:^(NSError *e) {
    if (e) { ... }
}];
```

Classes will inherit methods to retrieve all objects, or only certain ones:

```objc
// GET /posts.json
[Post remoteAllAsync:^(NSArray *allPosts, NSError *error) {
    //allPosts => [<#Post1#>, <#Post2#>]
}];

// GET /posts/1.json
[Post remoteObjectWithID:1 async:^(Post *post, NSError *error) {
    //post => <#Post#>
    //post.content => "First!!11!"
}];
```

NSRails is accessible while very flexible, and keeps your code clean and organized. It uses your classes' names and standard `@properties` to map to your remote models, so it's easy to fit into any project.

Features
--------

* High-level API, yet flexible enough even to work with any RESTful server
* Highly customizable property behaviors and nesting
* Seamless CoreData support
* Asynchronous requests
* Fully supported in RubyMotion and MacRuby
* Written with ARC
* [Autogenerate](https://github.com/dingbat/nsrails/tree/master/autogen) NSRails-ready classes from a Rails project

Quick links
--------

* [Documentation](http://dingbat.github.com/nsrails)
* [CoreData guide](http://dingbat.github.com/nsrails/Classes/NSRRemoteManagedObject.html)
* [Cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook)

Getting started - Objective-C
---------

1. Add NSRails to your project. You can:
  * Use CocoaPods (highly recommended). Add `pod 'NSRails'` to your Podfile.
  * Use a Git submodule, so you can `git pull` and always be up to date. The following will clone the entire NSRails repo, but you'll only need to add `nsrails/Source` to Xcode:
 
      ```
      $ git submodule add git@github.com:dingbat/nsrails.git NSRails
      ```
  * Drop the `Source` folder into your Xcode project. You'll also need the CoreData framework linked in Build Phases.
      

2. Make a class for your Rails model that subclasses **NSRRemoteObject** (you'll need to `#import NSRails.h`)

  ```objc
  #import "NSRails.h"

  @interface Post : NSRRemoteObject

  @property (nonatomic, strong) NSString *author, *content;
  @property (nonatomic, strong) NSDate *createdAt;
  
  @end
  ```

3. Set your server URL in your app setup:

  ```objc
  #import "NSRails.h"

  - (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
  {
        [NSRConfig defaultConfig].appURL = @"http://localhost:3000";
        // If you're using Rails 3
        [[NSRConfig defaultConfig] configureToRailsVersion:NSRRailsVersion3];
        ...
  }
  ```
  **Note:** By default, NSRails assumes you're using Rails 4. If not, make sure you configure to Rails 3 standards (ie, PUT instead of PATCH and a different date format) as shown above.

You're done! By subclassing NSRRemoteObject, your class gets instance and class methods that'll act on your remote objects. Here are a few of the things you can do with your new class:

```objc
// Retrieve post with ID 1
Post *post = [Post remoteObjectWithID:1 error:&error];

// Update this post remotely
post.content = @"Changed!";
[post remoteUpdate:&error];

// Fetch any latest data for this post
[post remoteFetch:&error];

// Retrieve a collection based on an object - will GET /posts/1/responses.json
NSArray *responses = [Response remoteAllViaObject:post error:&error];

// Async is also available for all commands, with blocks!
[post remoteDestroyAsync: ^(NSError *error) {  if (!error) ... }];
```

See the [documentation](http://dingbat.github.com/nsrails/) for more on what you can do with your new class, or the [cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook) for quick NSRRemoteObject recipes.

Getting started - Ruby
---------

1. In **MacRuby**, simply drag the `Source` folder into Xcode in your MacRuby project, and NSRails should be built with your project as normal. For **RubyMotion**, follow these steps to vendor NSRails:
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
2. Make a Ruby class for your Rails model and have it subclass **NSRRemoteObject**:

	```ruby
	class Post < NSRRemoteObject
	  attr_accessor :author, :content, :created_at

	  # Since the above list of Ruby instance variables can't be accessed from
	  # Obj-C, they have to be explicitly defined by overriding 'remoteProperties'
	  def remoteProperties
	    super + ["author", "content", "created_at"]
	  end
	end
	```

3. Setup. This can go in `app_delegate.rb`:

	```ruby
	NSRConfig.defaultConfig.appURL = "http://localhost:3000"

	# Don't look for camelCase when receiving remote underscored_properties, since we're in Ruby
	NSRConfig.defaultConfig.autoinflectsPropertyNames = false
	
	# If you're using Rails 3
	NSRConfig.defaultConfig.configureToRailsVersion NSRRailsVersion3
	```
	
Now have fun! These are just examples of how you can use pointers/blocks in Ruby, but see the Objective-C example above for more!

```ruby
# Get all posts (synchronously)
error_ptr = Pointer.new(:object)
posts = Post.remoteAll(error_ptr)
if !posts
  error = error_ptr[0]
  ...
end

# Get all posts (asynchronously)
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

NSRails is written and maintained by Dan Hassin. A lot of it was inspired by the [ObjectiveResource](https://github.com/yfactorial/objectiveresource) project, many thanks there!

http://nsrails.com
