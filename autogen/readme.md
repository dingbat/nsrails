This autogen tool will generate NSRails Objective-C classes (`.m` and `.h`) for you, based on the models from a Rails app. Properties with `belongs_to`, `has_one`, and `has_many` relationships will also be included.

Usage:
==========

```
$ cd path/to/nsrails_repo
$ autogen/generate path/to/your_rails_project [options]
```

Files will be created in the `autogen/` directory with the extension `.gen`, whose contained files can then be added to your Xcode project. Sample output for our [demo app](https://github.com/dingbat/nsrails/tree/master/demo/iOS):

```
Making directory your_rails_project.gen/
Writing files to /Users/dan/projects/nsrails/autogen/your_rails_project.gen/
  + Post.h
  + Post.m
  + Response.h
  + Response.m
  + MyRailsProject.h
```

Options:
==========

Run the script without any arguments or use the `-h` (`--help`) flag for a list of these options. They are absolutely combinable!

Property translation
------------

Include `created_at` or `updated_at`: (excluded by default)

```
$ autogen/generate APP_PATH --created-at --updated-at
```

### Nested properties

Exclude `-b` flag to any `belongs_to` properties: (flags included by default - read more about this [here](https://github.com/dingbat/nsrails/wiki/Property-flags))

```
$ autogen/generate APP_PATH --nesting-no-b-flag
```

Make X-to-many properties use `NSMutableArray` instead of `NSArray`:

```
$ autogen/generate APP_PATH --nesting-mutable-arrays
```

Make all nested properties [retrievable-only](https://github.com/dingbat/nsrails/wiki/Property-flags) (if you don't want to [support accepting nested attributes](https://github.com/dingbat/nsrails/wiki/Nesting)):

```
$ autogen/generate APP_PATH --nesting-retrievable-only
```

File styling
--------------

Metadata for comments header at the top of the files:

```
$ autogen/generate APP_PATH --author "Nikola Tesla" --company "Tesla ELM" --project "The Coil"
or
$ autogen/generate APP_PATH -a "Nikola Tesla" -c "Tesla ELM" -p "The Coil"
```

Add prefix for classes and filenames:

```
$ autogen/generate APP_PATH --prefix NSR
or
$ autogen/generate APP_PATH -x NSR
```
Use quotes if your argument has spaces in it.