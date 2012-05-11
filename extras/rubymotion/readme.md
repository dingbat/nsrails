NSRails with RubyMotion
=======

To run this project you'll need [RubyMotion](http://www.rubymotion.com/) installed and licensed. This is the same demo app as the Objective-C version, also going to [nsrails.com](http://nsrails.com), just written in Ruby!

NSRails is **fully supported** in this environment but with a few quirks:

* Macros (like `NSRailsSync`) should be defined with a class method named after the macro. They should return a string
* Gets and sets have to be manually defined since RubyMotion doesn't integrate `attr_accessor` and `@property` quite that well (yet!)
** This also means `*` is not available for `NSRailsSync` - you'll have to explicitly define each property you want to share

Example:

```ruby
class Post < NSRailsModel
  def author; @author; end
  def responses; @responses; end
  def setAuthor(a); @author = a; end
  def setResponses(r); @responses = r; end
  
  def self.NSRailsSync
    'author, content, responses:Response'
  end
end
```

You're ready to ride Ruby on Rails riding Objective-C riding Ruby! (Have we come full circle...?)

```ruby
# setup
NSRConfig.defaultConfig.appURL = "http://nsrails.com"

# get all posts (synchronously)
error_ptr = Pointer.new(:object)
posts = Post.remoteAll(error_ptr)
error = error_ptr[0]               # retrieve error

# get all posts (asynchronously)
Post.remoteAllAsync(lambda do |posts, error| 
                      #stuff
                    end)
```