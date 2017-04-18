[![nsrails.com](http://i.imgur.com/3FFpT.png)](http://nsrails.com/)

***

NSRails is a lightweight framework that makes mapping client-side objects to remote Rails objects a breeze, and calling CRUD operations and others super easy. It's accessible while also extremely flexible and customizable, to the point that it'll work with any RESTful server, not just Rails. Also, CoreData support is seamless.

Here's how easy it is to get started. Set the root URL of your app somewhere during launch:

```swift
NSRConfig.defaultConfig().rootURL = NSURL(string:"http://localhost:3000")
```

```objc
[NSRConfig defaultConfig].rootURL = [NSURL URLWithString:@"http://localhost:3000"];
```

Inherit model objects from `NSRRemoteObject`, or `NSRRemoteManagedObject` with CoreData:

```swift
@objc(Post) class Post : NSRRemoteObject {
  var author: String
  var content: String
  var createdAt: NSDate
  var responses: [Response]
}
```

```objc
@interface Post : NSRRemoteObject

@property (nonatomic, strong) NSString *author, *content;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSArray *responses;

@end
```

Note: `@objc(<ClassName>)` is currently required for Swift so the class name bridges over nicely.

That's it! Instances inherit methods to remotely create, read, update, or destroy their corresponding remote object:

```swift
let post = Post()
post.author = "Me"
post.content = "Some text"

// POST /posts.json => {post:{author:"Me", content:"Some text"}}
post.remoteCreateAsync() { error in
    ...
}

post.content = "Changed!"
// PATCH /posts/1.json => {post:{author:"Me", content:"Changed!"}}
post.remoteUpdateAsync() { error in ... }

// Fetch any latest data for this post and update locally
// GET /posts/1.json
post.remoteFetchAsync() { error in ... }

// DELETE /posts/1.json
post.remoteDestroyAsync() { error in ... }

// GET /posts.json
Post.remoteAllAsync() { allPosts, error in ... }

// GET /posts/1.json
Post.remoteObjectWithID(1) { post, error in ... }

// Retrieve a collection based on an object
// GET /posts/1/responses.json
Response.remoteAllViaObject(post) { responses, error in ... }
```

A lot of behavior is customized via overrides. For instance, in the previous example, in order to populate a Post's `responses` array with `Response` objects automatically when a Post is retrieved, we have to specify the `Response` class as the type for that property.

```objc
@implementation Post

//override
- (Class) nestedClassForProperty:(NSString *)property {
    if ([property isEqualToString:@"response"]) {
        return [Response class];
    }
    
    return [super nestedClassForProperty:property];
}

@end
```

(Sidenote: This is necessary for Objective-C of course, but at least in Swift, there's probably a good way to automatically infer the type from the generic specified in the array, which I haven't looked into it yet. Let me know if this is possible!)

See the [documentation](http://dingbat.github.com/nsrails/) for more on what you can do with NSRails-charged classes, or the [cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook) for quick `NSRRemoteObject` override recipes.

#### NSRRequest

Requests themselves can be customized with query parameters (`/?a=b&c=d`), additional HTTP headers, or to go to custom routes (i.e. for custom controller methods) using the [NSRRequest class](http://dingbat.github.io/nsrails/Classes/NSRRequest.html). The results of these requests can easily be converted from JSON into native model objects using inherited convenience methods such as `+[MyClass objectWithRemoteDictionary:]` and `+[MyClass objectsWithRemoteDictionaries:]`.

Support
--------

* [Documentation](http://dingbat.github.com/nsrails)
* [CoreData guide](http://dingbat.github.com/nsrails/Classes/NSRRemoteManagedObject.html)
* [Cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook) with various override recipes
* [Issues](https//github.com/dingbat/nsrails/issues)
* [Gitter](https://gitter.im/dingbat/nsrails), if you need any help, or just want to talk!

Installation
---------

The best way to install NSRails is to use the Great [CocoaPods](http://cocoapods.org/). Add `pod 'NSRails'` to your Podfile, or `pod 'NSRails/CoreData'` if you're using CoreData.

* Getting started using NSRails with Ruby has been moved [here](https://github.com/dingbat/nsrails/wiki/ruby).
* Also, [autogenerate](https://github.com/dingbat/nsrails/tree/master/autogen) NSRails-ready classes from a Rails project.

Dependencies
--------

* **iOS 5.0+** / **OS X 10.7+**
* **Automatic Reference Counting (ARC)**

Credits
----------

NSRails is written and maintained by Dan Hassin. A lot of it was inspired by the [ObjectiveResource](https://github.com/yfactorial/objectiveresource) project, many thanks there!

http://nsrails.com – an open forum -type thing running on Rails/Heroku and powered by the included NSRails demo app!
