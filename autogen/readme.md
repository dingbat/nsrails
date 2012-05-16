Usage:
----------

```
$ cd path/to/nsrails_repo
$ autogen/generate path/to/rails_project [options]
```

Files will be created in the `autogen/` directory with the extension `.gen`, whose contained files can then be added to your Xcode project.

Options
-------

Run the script without any arguments or use the `-h` (`--help`) flag for a list of these options. They are absolutely combinable!

<table>
  <tr>
    <th>Option</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><pre>--created-at<br/>--updated-at</pre></td>
    <td>Include <code>created_at</code> and/or <code>updated_at</code> properties. (Excluded by default)</td>
  </tr>
  <tr>
    <td><pre>--nesting-no-b-flag</pre></td>
    <td>Exclude <code>-b</code> flag to any belongs-to properties. (Flags included by default - read more about this <a href="https://github.com/dingbat/nsrails/wiki/Property-flags">here</a>)</td>
  </tr>
  <tr>
    <td><pre>--nesting-mutable-arrays</pre></td>
    <td>Make X-to-many properties use <code>NSMutableArray</code> instead of <code>NSArray</code></td>
  </tr>
  <tr>
    <td><pre>--nesting-retrievable-only</pre></td>
    <td>Make all nested properties <a href="https://github.com/dingbat/nsrails/wiki/Property-flags">retrievable-only</a>. (Use this if you don't want to <a href="https://github.com/dingbat/nsrails/wiki/Nesting">support accepting nested attributes)</a></td>
  </tr>
  <tr>
    <td><pre>--author, -a<br/>--company, -c<br/>--project -p</pre></td>
    <td>Metadata (for headers of files). Each expects a string following it.</td>
  </tr>
  <tr>
    <td><pre>--prefix, -x</pre></td>
    <td>Class prefix</td>
  </tr>
</table>

Example
------------

```
$ autogen/generate APP_PATH -a "Nikola Tesla" -c "Tesla ELM" -p "The Coil" -x "NSR" --created-at --mutable-arrays 
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

@implementation NSRPost
@synthesize content, author, createdAt, responses;
NSRailsSync(*, author -b, createdAt -r, responses:NSRResponse)

@end
```