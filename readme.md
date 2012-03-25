[![nsrails.com](http://i.imgur.com/3FFpT.png)](http://nsrails.com/)

***

Welcome!

NSRails is a light-weight Objective-C framework (iOS or OS X) for simple but powerful communication with your Rails server.


What does NSRails do?
========

Once you've created Objective-C classes to match your Rails model structure, NSRails gives them native, ActiveResource-like support. This means CRUD and other operations can be called seamlessly via Objective-C methods:

```objc
Article *newArticle = [[Article alloc] init];
newArticle.title = @"Title";
newArticle.content = @"Some text";
[newArticle remoteCreate:&error];     //This article and its properties created right on a Rails server
```

Instances inherit methods to remotely create, update, destroy, or read a corresponding Rails object - only with a single method call. They'll also inherit class methods to retrieve certain objects (or all of them):

```objc
NSArray *allArticles = [Article remoteAll:&error];
Article *articleNumber1 = [Article remoteObjectWithID:1 error:&error];

// Display your article(s)! They're ready with their properties populated directly from your remote DB
```


The framework is very flexible and can fit the specific needs of your Rails (or RESTful) server. Some features include:

* Keeping models and properties of your choice [in-sync](https://github.com/dingbat/nsrails/wiki/NSRailsSync) with those of Rails
* [Nesting](https://github.com/dingbat/nsrails/wiki/Nesting) your related models (has-many, etc)
* Support for [basic HTTP authentication](https://github.com/dingbat/nsrails/wiki/NSRConfig)
* [Asynchronous](https://github.com/dingbat/nsrails/wiki/NSRailsModel) requests
* A lot more...

How do I get started?
========

It's fairly painless. Drop the source folder into your Xcode project, and see [this page](https://github.com/dingbat/nsrails/wiki/Getting-Started).

Some more resources:

* Get a head start in translating Rails models into Objective-C using the [autogen tool](https://github.com/dingbat/nsrails/tree/master/autogen)
* Watch the [screencast](http://vimeo.com/dq/nsrails)
* Browse the included demo iPhone app - it goes straight to a live Rails app at [nsrails.com](http://nsrails.com), so you won't even have to launch a server to get started. The source for this site is also included. Have fun and be civil!
* See the [Wiki](https://github.com/dingbat/nsrails/wiki)

Credits 
========

NSRails is published under the MIT license, meaning you can use the sources however you'd like.

Thanks a lot to the [SB JSON framework](https://github.com/stig/json-framework) for JSON parsing and writing, and to [ObjectiveResource](https://github.com/yfactorial/objectiveresource) for being largely the inspiration for NSRails.