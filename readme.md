[![nsrails.com](http://i.imgur.com/3FFpT.png)](https://github.com/dingbat/nsrails/wiki/Getting-Started)

***

Welcome!

NSRails is a light-weight Objective-C framework (iOS or OS X) for simple but powerful communication with your Rails server.


What can NSRails do?
========

Once you've created Objective-C classes to match your Rails model structure, NSRails provides them with native ActiveResource-like support. This means CRUD and other operations can be called seamlessly via Objective-C methods:

``` objc
Article *newArticle = [[Article alloc] init];
newArticle.title = @"This article and its properties created right on your Rails server";
newArticle.content = @"All that's needed is the following method:";
[newArticle remoteCreate];
```

Instances inherit methods to remotely create, update, destroy, or read a corresponding Rails object - only with a single method call. They'll also inherit class methods to retrieve certain objects (or all of them):

``` objc
Article *articleNumber1 = [Article remoteObjectWithID:1];
// Display your article! It's ready with its properties populated directly from your remote DB
```


The framework is very flexible and can fit the specific needs of your Rails (or RESTful) server. Some features include:

* Keeping models and properties of your choice [in-sync](https://github.com/dingbat/nsrails/wiki/NSRailsSync) with those of Rails
* [Nesting](https://github.com/dingbat/nsrails/wiki/Nesting) your related models (has-many, etc)
* Support for [basic HTTP authentication](https://github.com/dingbat/nsrails/wiki/NSRConfig)
* [Asynchronous](https://github.com/dingbat/nsrails/wiki/NSRailsModel) requests
* A lot more...

How do I get started?
========

It's fairly painless. Add the source folder into your Xcode project, and see [this page](https://github.com/dingbat/nsrails/wiki/Getting-Started).

For more details:

*   Watch the [screencast](http://vimeo.com/37418882)
*   Browse the included demo iPhone app - it goes straight to a live Rails app at [nsrails.com](http://nsrails.com), so you won't even have to launch a server to get started. The source for this site is also included. Have fun and be civil!
*   See the [Wiki](https://github.com/dingbat/nsrails/wiki)

What's in the sources?
========

The main class (and the one from which to derive your classes) is [NSRailsModel](https://github.com/dingbat/nsrails/wiki/NSRailsModel) (defined in NSRails.h). Also included is the [NSRConfig](https://github.com/dingbat/nsrails/wiki/NSRConfig) class for server settings.

As per external frameworks, NSRails makes great use of the [SBJSON framework](https://github.com/stig/json-framework). And finally, I have to give a lot of credit to [ObjectiveResource](https://github.com/yfactorial/objectiveresource), whose framework was largely the inspiration for NSRails.