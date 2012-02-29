Usage:
-----------

This autogen tool will generate NSRails Objective-C classes (`.m` and `.h`) for you, based on the models from a Rails app. Properties with `belongs_to`, `has_one`, and `has_many` relationships will also be included.
```
$ ruby nsrgen.rb  path/to/your/project
```

Classes will be created in a corresponding folder, which can then be added to your Xcode project:
```
+ my_project classes/
  + Post.h
  + Post.m
  + Response.h
  + Response.m
```

Options:
-----------

Use the `--help` flag for a list of these options.

### Property options

Include `created_at` or `updated_at`: (excluded by default)

```
$ ruby nsrgen.rb  path/to/your/project --include-created-at --include-updated-at
```

Exclude `-b` flag to any `belongs_to` properties: (included by default - read more about this [here](https://github.com/dingbat/nsrails/wiki/Property-flags))

```
$ ruby nsrgen.rb  path/to/your/project --exclude-belongs-to-flag
```

Make X-to-many properties NSMutableArrays instead of just NSArrays:

```
$ ruby nsrgen.rb  path/to/your/project --use-mutable-arrays
```

### File styling

Metadata for comments header at the top of the files:

```
$ ruby nsrgen.rb  path/to/your/project --author="Nikola Tesla" --company="Tesla ELM" --project="The Coil"
```

Add prefix for classes and filenames:

```
$ ruby nsrgen.rb  path/to/your/project --prefix="NSR"
```
