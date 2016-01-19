# UNRELEASED

* Extraction and isolation of provider specific functionalities
* Added provider support for Azure
* Added provider support for Heat
* Added provider support for Rackspace
* Enforce minimum supported Ruby version

# v1.2.0
* Fix pack registration helper method
* Provide easy access to Kernel.method (#122)
* Force error on ambiguous dynamic names (#133)
* Add resource name helper method (#128)
* Fix aws resource type collector script (#132)
* Introduce type checking where possible (#117)
* Load sparkle pack contents in single pass (#123)
* Extract provider specific helpers and provide generics (#124)
* Add tagging helper method (#121)

# v1.1.14
* Fix for multi depth hash loading within nested stacks (#118)

# v1.1.12
* New helper methods added `raise!` and `puts!` (#109)
* Fix for registry usage within components (#115)

# v1.1.10
* Join nesting arguments to template name. Allow optional replace.

# v1.1.8
* Raise error on name collisions within pack (#101)
* Extract registry items from pack during compile

# v1.1.6
* Fix `#root!` helper method usage (#98)

# v1.1.4
* Update resource information extractor (#92)
* Update builtin aws resource information (#92)
* Support subdirectories within packs (#94)

# v1.1.2
* Inject compile time state into outputs only if data set

# v1.1.0
* Add support for compile time parameters
* Fix usage of deprecated `SparkleFormation.insert` method
* Propagate parent stack parameter when output required output is in parent stack

# v1.0.4
* Fixes on testing (#66 #67 #68 thanks @matschaffer)
* Properly handle JSON templates within packs (#72)

# v1.0.2
* Support custom values for stack resource type matching

# v1.0.0

> NOTE: This is a major version release. It includes multiple
> implementation updates that may cause breakage.

* Add SparklePacks for isolation and distribution
* Add SparkleFormation.component method for defining components
* Support fully recursive nesting and parameter / output mapping
* Support previous nesting style (shallow) and new style (deep)
* Include support for in-line stack policy extraction

# v0.3.0
* Update `or!` helper method to take multiple arguments
* Support non-ref values in `map!` (#19)

_NOTE: This release *could* contain a breaking change. The `map!` method
will now only auto generate a `ref!` call if the passed value is a symbol._

# v0.2.12
* Stubs for template generation parameters
* Add `no_value!` helper method
* Force path resets with `sparkle_path` is set
* Include all missing pseudo parameter helpers
* Provide more control on dynamic naming

# v0.2.10
* Add helper for generating no value
* Fix Fn::If generator (#35 thanks @yhuang !)

# v0.2.8
* Relax isolated nesting check (resources only)
* Include condition within generated hash within `if!` helper (#32)
* Auto process String arguments provided to `if!`
* Fix array nesting within `or!`

# v0.2.6
* Add initial nested stack implementation
* Update user docs generation

# v0.2.4
* Update builtin registry lookup to better handle all caps types
* Add helper methods for conditionals
* Provide better error message when dereferencing mappings that do not exist
* Add more coverage within heat translation

# v0.2.2
* Lots of translation updates (AWS -> RS "hot")
* User Documentation!

# v0.2.0
* Add Registry helper into Utils
* Add script for collecting cfn and hot resources
* Provide builtin dynamics
* Add helpers for registry and dynamic insertions
* Let dynamics provide metadata about themselves
* Start translation implementation
* Include bang helper method aliases
* Add hash dumping and JSON dumping helpers to formation instance

# v0.1.4
* Allow compile to return raw object instead of hash dump

# v0.1.2
* Fix syntax issue in cf helpers

# v0.1.0
* Initial release
