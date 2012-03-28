[![nsrails.com](http://i.imgur.com/3FFpT.png)](http://nsrails.com/)

***

Welcome!

NSRails is a light-weight, drop-in Objective-C framework (iOS or OS X) for simple but powerful communication with your Rails server.


What does NSRails do?
========

NSRails provides simple, high-level APIs that give your Objective-C classes ActiveResource-like support. This means CRUD and other operations on your corresponding Rails objects can be called natively via Objective-C methods.

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

**Features:**

* High-level APIs, yet flexible enough even to work with any RESTful server
* Keeping models and properties of your choice [in-sync](https://github.com/dingbat/nsrails/wiki/NSRailsSync) with those of Rails
* [Nesting](https://github.com/dingbat/nsrails/wiki/Nesting) your related models (has-many, etc)
* [Asynchronous](https://github.com/dingbat/nsrails/wiki/NSRailsModel) requests
* Support for [basic HTTP authentication](https://github.com/dingbat/nsrails/wiki/NSRConfig)

How do I get started?
========

It's fairly painless. Drop the source folder into your Xcode project, and see [this page](https://github.com/dingbat/nsrails/wiki/Getting-Started).

Some more resources:

* Easily translate Rails models into Objective-C classes using [autogen tool](https://github.com/dingbat/nsrails/tree/master/autogen)
* Watch the [screencast](http://vimeo.com/dq/nsrails)
* See the [Wiki](https://github.com/dingbat/nsrails/wiki)
* Browse the included demo iPhone app - it goes straight to a live Rails app at [nsrails.com](http://nsrails.com), so you won't even have to launch a server to get started. The source for this site is also included. Have fun and be civil!

Credits 
========

NSRails is published under the MIT license, meaning you can use the sources however you'd like.

Thanks a lot to the [SB JSON framework](https://github.com/stig/json-framework) for JSON parsing and writing, and to [ObjectiveResource](https://github.com/yfactorial/objectiveresource) for being largely the inspiration for NSRails.