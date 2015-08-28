## SparklePacks

SparklePacks are a way to package and ship SparkleFormation collections
for direct use, or to extend in customized usage. A SparklePack can be
composed of all the building blocks defined by SparkleFormation. Once
a SparklePack is built, it can then be loaded and registered making
its building blocks available in the current usage context. Multiple
SparklePacks can be loaded, and SparkleFormation performs its lookup
action based on load order (last loaded retains highest precedence).

### Cheatsheet Breakdown

* Composed of SparkleFormation any/all building blocks:
  * Components
  * Dynamics
  * Registries
  * Templates
* Packaged and distributed for reuse
* Supports standalone usage _and_ project integration
* Allows loading of multiple SparklePacks
  * SparklePacks affect building block lookup behavior of SparkleFormation
  * Last loaded SparklePack retains highest precedence

### Requirements

#### Explicit Building Block Methods

The [explicit building block methods](building-blocks.md#name-based-components)
 must be used when creating a SparklePack. Usage of implicit methods (like
`SparkleFormation.build` instead of `SparkleFormation.component`) is currently working but
should be considered un-supported. The explicit methods also allow
more flexibility on the layout of files since the file system structure
and file naming are decoupled.

### Layout

A SparklePack is simply a directory containing a `sparkleformation`
subdirectory which contains all distributed building blocks:

```
> tree
.
|____sparkleformation
| |____dynamics
| |____components
| |____registries
```

### Usage

On instantiation, `SparkleFormation` will automatically generate a
SparklePack based on global configuration and current working directory.
A customized pack can be provided on instantiation to override this
behavior:

```ruby
root_pack = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)
sfn = SparkleFormation.new(:my_template, :sparkle => root_pack) do
  # Define template
end
```

It is also possible to add additional SparklePacks to an existing
SparkleFormation.

> NOTE: The SparklePack used on instantiation of a SparkleFormation
> instance is considered the *root* SparklePack and will _*always*_
> have the highest precedence.

Building from the previous example, adding a additional pack:

```ruby
root_pack = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)
custom_pack = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)

sfn = SparkleFormation.new(
  :my_template,
  :sparkle => custom_pack
)
sfn.sparkle.add_sparkle(custom_pack)
```

With this `custom_pack` added to the collection, the SparkleFormation
lookup for building blocks will follow the order:

1. `root_pack`
2. `custom_pack`

By default new packs added will retain higher precedence than existing
packs already added:

```ruby
root_pack = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)
custom_pack = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)
override_patck = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)

sfn = SparkleFormation.new(
  :my_template,
  :sparkle => custom_pack
)
sfn.sparkle.add_sparkle(custom_pack)
sfn.sparkle.add_sparkle(override_pack)
```


In the above example `override_pack` holds the second highest precedence
(the `root_pack` always holding the highest). Lookups will now have the
following order:

1. `root_pack`
2. `override_pack`
3. `custom_pack`

It is possible to force a pack to the lowest precedence level when
adding:

```ruby
root_pack = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)
custom_pack = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)
base_patck = SparkleFormation::SparklePack.new(
  :root => PATH_TO_PACK
)

sfn = SparkleFormation.new(
  :my_template,
  :sparkle => custom_pack
)
sfn.sparkle.add_sparkle(custom_pack)
sfn.sparkle.add_sparkle(base_pack, :low)
```

This example demonstrates how to add a pack at the lowest precedence
level allowing currently registered SparklePacks to retain their
existing precedence. Lookups in this example will have the
following order:

1. `root_pack`
2. `custom_pack`
3. `base_pack`

This behavior is _non-default_ so ensure it is the expected behavior
within an implementation.
