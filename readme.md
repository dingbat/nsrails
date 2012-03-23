# RABL #

RABL (Ruby API Builder Language) is a Rails and [Padrino](http://padrinorb.com) ruby templating system for generating JSON, XML, MessagePack, PList and BSON. When using the ActiveRecord 'to_json' method, I tend to quickly find myself wanting a more expressive and powerful solution for generating APIs.
This is especially frustrating when the JSON representation is complex or doesn't match the exact schema defined in the database.

I wanted a simple and flexible system for generating my APIs. In particular, I wanted to easily:

 * Create arbitrary nodes named based on combining data in an object
 * Pass arguments to methods and store the result as a child node
 * Render partial templates and inherit to reduce code duplication
 * Rename or alias attributes to change the name from the model
 * Append attributes from a child into a parent node
 * Include nodes only if a certain condition has been met

Anyone who has tried the 'to_json' method used in ActiveRecord for generating a JSON response has felt the pain of this restrictive approach.
RABL is a general templating system created to solve these problems in an entirely new way.

## Installation ##

Install RABL as a gem:

```
gem install rabl
```

or add to your Gemfile:

```ruby
# Gemfile
gem 'rabl'
# Also add either `json` or `yajl-ruby` as the JSON parser
gem 'yajl-ruby'
```

and run `bundle install` to install the dependency.