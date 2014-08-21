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

Subclass model objects from `NSRRemoteObject`, or `NSRRemoteManagedObject` for CoreData integration:

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

Note: `@objc(Post)` is currently required for Swift so the class name bridges over nicely.

That's it! Instances inherit methods to remotely create, read, update, or destroy their corresponding remote object:

```swift
let post = Post()
post.author = "Me"
post.content = "Some text"

// POST /posts.json => {post:{author:"Me", content:"Some text"}}
post.remoteCreateAsync() { error in
    ...
}

// Push updates to remote
post.content = "Changed!"
post.remoteUpdateAsync() { error in }

// Fetch any latest data for this post
post.remoteFetchAsync() { error in }

// GET /posts.json
Post.remoteAllAsync() { allPosts, error in }

// GET /posts/1.json
Post.remoteObjectWithID(1) { post, error in }

// Retrieve a collection based on an object
// GET /posts/1/responses.json
Response.remoteAllViaObject(post) { responses, error in }
```

See the [documentation](http://dingbat.github.com/nsrails/) for more on what you can do with NSRails-charged classes, or the [cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook) for quick `NSRRemoteObject` recipes.

Support
--------

* [Documentation](http://dingbat.github.com/nsrails)
* [CoreData guide](http://dingbat.github.com/nsrails/Classes/NSRRemoteManagedObject.html)
* [Cookbook](https://github.com/dingbat/nsrails/wiki/Cookbook)
* [Issues](https//github.com/dingbat/nsrails/issues)
* [Gitter](https://gitter.im/dingbat/nsrails), if you need any help, or just want to talk!

Intallation
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

http://nsrails.com
