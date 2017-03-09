# v3.0.16
* Allow data structure arguments in AWS helpers
* Add AWS sub intrinsic function helper

# v3.0.14
* Fix resource lookup helper when using full match

# v3.0.12
* Prevent parameter mappings applying to root template
* Add #import_value! helper for AWS templates (#193)
* Add #split! helper for AWS templates
* Add provider support for Terraform (#201)

# v3.0.10
* Extract pack name using previously extract path (#180)

# v3.0.8
* Fix pack loading on Windows (#178)

# v3.0.6
* Update builtin provider resource lists

# v3.0.4
* Extend allowed attributes for generation parameters (#173)

# v3.0.2
* Fix resource effect check when defaulted with boolean

# v3.0.0
_Major release includes breaking changes!_
* Builtin provider resources updates (#163)
 * New Resource and Propery types
 * Support for conditional logic to determine property modification effect
* New provider Google (#167)
* Inject nested stacks using dynamic style insertion (#167)
* Add sparkle aliases for dumps to allow non-provider formatted template dumps (#167)
* Allow sparkle pack to load as empty pack (#167)
* Generate nested stack resource name using key processing style of current context (#167)
* SparkleFormation#apply_nesting now returns compiled structure not Hash (#167)
* SparkleFormation#stack_template_extractor now sets compiled structure not Hash (#167)
* Remove helper method aliasing in Azure module to work on Ruby 2.3 (#170)
* Implement provider restrictions and naming uniqueness (#169)

_NOTE: If using non-AWS provider, files must be updated to include `:provider` flag._

# v2.1.8
* Add support for CFN list type with shallow nesting (#150)
* Fix deprecation warnings on Ruby 2.3 caused by TimeoutError constant
* Fix JSON dump behavior with pure ruby json library (#162)

# v2.1.6
* Update builtin resource lists (#156)
* Refactor internal template composition (#158)

# v2.1.4
* Fix struct value storage within internal table (#147)

# v2.1.2
* Add helper for copying SparkleFormation::Collection settings
* Use collections helper to ensure expected pack ordering
* Add support for template location via path within SparkleFormation::Collection

# v2.1.0
* Add template inheritance support (#145)
* Add layer merging support for templates, components, and dynamics (#145)
* Update allowed Ruby constraint to require version greater than or equal to 2.1

# v2.0.2
* Provide useful return value from `#dynamic!` (#137)
* Implement proper Azure resource generator (#141)
* Update internal Azure resource list (#141)
* Support provider specific resource splitting (#142)
* Allow provider specific resource modification on builtin inserts (#143)
* Enforce helper method convention. Always error if convention used and helper not found (#144)
* Always include parens on root of FunctionStruct dumps

# v2.0.0
* Fix sparkle pack usage in nested stacks (#140)
* Update value processing in attribute helpers for consistent behavior
* Extraction and isolation of provider specific functionalities (#138)
* Added provider support for Azure (#138)
* Added provider support for Heat (#138)
* Added provider support for Rackspace (#139)
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
