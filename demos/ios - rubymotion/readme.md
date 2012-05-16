NSRails ♥'s Ruby too!
====================

To run this demo you'll need [RubyMotion](http://www.rubymotion.com/) installed and licensed. This is the same demo app as the Objective-C version, also going to [nsrails.com](http://nsrails.com), just written in Ruby!

Getting started
-------

### RubyMotion

* Add a `vendor` directory on the main level of your RubyMotion app if you don't have one already.
* Copy the `nsrails` directory ([the main Xcode project](https://github.com/dingbat/nsrails/tree/master/nsrails)) into `vendor`. (You can delete `Tests/`).
* Modify your Rakefile to vendor NSRails:

  ```ruby
  Motion::Project::App.setup do |app|
      # Add this line:
      app.vendor_project('vendor/nsrails', :xcode, :target => 'NSRails', :headers_dir => 'Source')
      ...
  ```

### MacRuby

* MacRuby is even easier to configure since vendoring is not necessary. Simply drag the `Source` folder into Xcode in your MacRuby project, and it should be built with your project as normal.

Quirks
---------

Due to differences with Objective-C, there are some quick additional requirements in the Ruby environment:

* Macros like `NSRailsSync` should be defined as class methods returning a string
* `NSRailsSync` is required. And because Ruby is not statically typed, some extra things are required...
 1. `*` is unavailable - every property you wish to share needs to be explicitly declared
 2. The rarely used `-m` flag is necessary to define any has-many associations (ie, for arrays)
 3. Dates have to be declared as dates by specifying `NSDate` as a "nested" type
* Right now there's a bug in RubyMotion (v1.4) where getter methods cannot be defined via `attr_accessor` - they'll have to be manually defined (`attr_writer` still works)

See the example class below if any of the above are unclear.

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

# don't look for camelCase when receiving remote underscored_properties
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