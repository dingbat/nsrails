Usage:
----------

```
$ cd path/to/nsrails_repo
$ autogen/generate [options] path/to/rails_project
```

Files will be created in the `autogen/` directory with the extension `.gen`, whose contained files can then be added to your Xcode project.

Options
-------

Use the `-h` (`--help`) flag for a list of these options.

<table>
  <tr>
    <th>Option</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><pre>--ruby</pre></td>
    <td>Generate classes for RubyMotion or MacRuby (.rb). (Objective-C by default)</td>
  </tr>
  <tr>
    <td><pre>--created-at<br/>--updated-at</pre></td>
    <td>Include <code>created_at</code> and/or <code>updated_at</code> properties. (Excluded by default)</td>
  </tr>
  <tr>
    <td><pre>--mutable-arrays</pre></td>
    <td>Use <code>NSMutableArray</code> for properties that are has-many (<code>NSArray</code> by default)</td>
  </tr>
  <tr>
    <td><pre>--nesting-retrievable-only</pre></td>
    <td>Make all nested properties <a href="https://github.com/dingbat/nsrails/wiki/NSRailsSync">retrievable-only</a>. (Use this if you don't want to <a href="https://github.com/dingbat/nsrails/wiki/Nesting">support accepting nested attributes</a>)</td>
  </tr>
  <tr>
    <td><pre>--author, -a<br/>--company, -c<br/>--project, -p</pre></td>
    <td>Metadata (for headers of files). Each expects a string following it</td>
  </tr>
  <tr>
    <td><pre>--prefix, -x</pre></td>
    <td>Class and filename prefix. Expects a string following it</td>
  </tr>
</table>

Example
------------

```
$ autogen/generate -a "Nikola Tesla" -c "Tesla ELM" -p "The Coil" -x "NSR" --created-at --mutable-arrays APP_PATH
```

Could generate files like these:

```objc
//
//  NSRPost.h
//  The Coil
//
//  Created by Nikola Tesla on 1/29/12.
//  Copyright (c) 2012 Tesla ELM. All rights reserved.
//

#import "NSRails.h"

@class NSRResponse;

@interface NSRPost : NSRailsModel

@property (nonatomic, strong) NSRAuthor *author;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSMutableArray *responses;

@end
```

```objc
//
//  NSRPost.m
//  The Coil
//
//  Created by Nikola Tesla on 1/29/12.
//  Copyright (c) 2012 Tesla ELM. All rights reserved.
//

#import "NSRPost.h"
#import "NSRResponse.h"

@implementation NSRPost
@synthesize content, author, createdAt, responses;
NSRailsSync(*, author -b, createdAt -r, responses:NSRResponse);

@end
```