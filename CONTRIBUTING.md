# Contributing

## Branches

### `master` branch

The master branch is the current stable released version.

### `develop` branch

The develop branch is the current edge of development.

## Pull requests

* https://github.com/sparkleformation/sparkle_formation/pulls

Please base all pull requests off the `develop` branch. Merges to
`master` only occur through the `develop` branch. Pull requests
based on `master` will likely be cherry picked.

## Tests

Add a test to your changes.
Tests can be run with bundler:

```
bundle
bundle exec rake
bundle exec ruby test/specs/attribute_spec.rb
bundle exec ruby test/specs/attribute_spec.rb -n '/should generate Fn::Join with custom delimiter/'
```

## Issues

Need to report an issue? Use the github issues:

* https://github.com/sparkleformation/sparkle_formation/issues
