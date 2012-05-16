[![nsrails.com](http://i.imgur.com/3FFpT.png)](http://nsrails.com/)

***

NSRails is a light-weight Objective-C framework that provides your classes with a high-level, ActiveResource-like API. This means CRUD and other operations on your corresponding Rails objects can be called natively via Objective-C methods.

Instances will inherit methods to remotely create, read, update, or destroy a remote object:

```objc
Article *newArticle = [[Article alloc] init];
newArticle.title = @"Title";
newArticle.content = @"Some text";
[newArticle remoteCreate:&error];     //This article and its properties created right on a Rails server
```

Classes will inherit methods to retrieve all objects, or only certain ones:

```objc
NSArray *allArticles = [Article remoteAll:&error];
Article *articleNumber1 = [Article remoteObjectWithID:1 error:&error];

// Display your article(s)! They're ready with their properties populated directly from your remote DB
```

Features:
--------

* High-level API, yet flexible enough even to work with any RESTful server
* Keeping models and properties of your choice [in-sync](https://github.com/dingbat/nsrails/wiki/NSRailsSync) with those of Rails
* [Nesting](https://github.com/dingbat/nsrails/wiki/Nesting) your related models (has-many, etc)
* [Asynchronous](https://github.com/dingbat/nsrails/wiki/NSRailsModel) requests
* [Basic HTTP authentication](https://github.com/dingbat/nsrails/wiki/NSRConfig)
* [Supported](https://github.com/dingbat/nsrails/tree/master/extras/rubymotion) in RubyMotion and MacRuby
* No dependencies besides a JSON framework (already bundled)

Getting started
---------

It's fairly painless. Drop the `Source` folder into your Xcode project and see [this page](https://github.com/dingbat/nsrails/wiki/Getting-Started).

Some more resources:

* Easily translate Rails models into Objective-C classes using [autogen tool](https://github.com/dingbat/nsrails/tree/master/extras/autogen)
* See the [documentation](http://dingbat.github.com/nsrails/) and [wiki](https://github.com/dingbat/nsrails/wiki)
* Watch the [screencast](http://vimeo.com/dq/nsrails)
* Browse the included [demo iPhone app](https://github.com/dingbat/nsrails/tree/master/nsrails) - it goes straight to a live Rails app at [nsrails.com](http://nsrails.com), so you won't even have to launch a server to get started. The [source for this site](https://github.com/dingbat/nsrails/tree/master/extras/nsrails.com) is also included. Have fun and be civil!

License & Credits
----------

NSRails is written & maintained by Dan Hassin and published under the MIT license (ie, use the sources however you'd like.)

I'd like to acknowledge [SBJson](https://github.com/stig/json-framework) for great JSON reading and writing, and thank the [ObjectiveResource](https://github.com/yfactorial/objectiveresource) project for being largely the inspiration for NSRails.