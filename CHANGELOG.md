## v0.2.10
* Add helper for generating no value
* Fix Fn::If generator (#35 thanks @yhuang !)

## v0.2.8
* Relax isolated nesting check (resources only)
* Include condition within generated hash within `if!` helper (#32)
* Auto process String arguments provided to `if!`
* Fix array nesting within `or!`

## v0.2.6
* Add initial nested stack implementation
* Update user docs generation

## v0.2.4
* Update builtin registry lookup to better handle all caps types
* Add helper methods for conditionals
* Provide better error message when dereferencing mappings that do not exist
* Add more coverage within heat translation

## v0.2.2
* Lots of translation updates (AWS -> RS "hot")
* User Documentation!

## v0.2.0
* Add Registry helper into Utils
* Add script for collecting cfn and hot resources
* Provide builtin dynamics
* Add helpers for registry and dynamic insertions
* Let dynamics provide metadata about themselves
* Start translation implementation
* Include bang helper method aliases
* Add hash dumping and JSON dumping helpers to formation instance

## v0.1.4
* Allow compile to return raw object instead of hash dump

## v0.1.2
* Fix syntax issue in cf helpers

## v0.1.0
* Initial release
