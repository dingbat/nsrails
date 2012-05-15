NSRails ♥'s Ruby too!
====================

To run this demo you'll need [RubyMotion](http://www.rubymotion.com/) installed and licensed. This is the same demo app as the Objective-C version, also going to [nsrails.com](http://nsrails.com), just written in Ruby!

Getting started
-------

* Add a `vendor` directory on the main level of your RubyMotion app if you don't have one already.
* Copy the `nsrails` directory ([the main Xcode project](https://github.com/dingbat/nsrails/tree/master/nsrails)) into `vendor`. (You don't need anything but `source/` and the Xcode project - you can delete `tests/` and `demo/`).
* Modify your Rakefile to vendor NSRails:

  ```ruby
  Motion::Project::App.setup do |app|
      # Add this line:
      app.vendor_project('vendor/nsrails', :xcode, :target => "NSRails", :headers_dir => 'source')
      ...
  ```

* You're ready! Be aware of a few quirks in this environment:
 1. Macros should be defined with a class method named exactly like the macro and should return a string
 2. Right now there's a bug in RubyMotion (v1.4) where getter methods cannot be defined via `attr_accessor` - they'll have to be manually defined
 3. `NSRailsSync` is required. And because Ruby is not statically typed, some things are a bit different... (see example below if these are unclear)
  * `*` isn't available - every property needs to be explicitly declared
  * The rarely used `-m` flag is necessary to define any has-many associations (ie, for arrays)
  * Dates have to be declared as dates by specifying `NSDate` as a "nested" type


Example
--------

```ruby
class Post < NSRailsModel
  attr_writer :author, :content, :responses, :created_at

  # Hopefully soon you'll be able just do "attr_accessor" above instead of this
  def author; @author; end  
  def content; @content; end
  def responses; @responses; end
  def created_at; @created_at; end
  
  def self.NSRailsSync
    'author, content, created_at:NSDate, responses:Response -m'
  end
end
```

You're riding Ruby on Rails riding Objective-C riding Ruby! (Have we come full circle...?)

```ruby
# setup
NSRConfig.defaultConfig.appURL = "http://nsrails.com"

# don't inflect underscored_properties into camelCase
NSRConfig.defaultConfig.autoinflectsPropertyNames = false

# get all posts (synchronously)
error_ptr = Pointer.new(:object)
posts = Post.remoteAll(error_ptr)
error = error_ptr[0]

# get all posts (asynchronously)
Post.remoteAllAsync(lambda do |posts, error| 
                      ...
                    end)
```

MacRuby
--------

MacRuby is even easier to configure since vendoring is not necessary. Simply drag the `source` folder into Xcode in your MacRuby project, and it should be built with your project as normal.
Now simply follow the example above!
* The quirks are still relevant besides manually writing gets and sets - MacRuby allows `attr_accessor`.