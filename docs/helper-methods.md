---
title: "Helper Methods"
category: "dsl"
weight: 5
anchors:
  - title: "Dynamics"
    url: "#dynamics"
  - title: "Registries"
    url: "#registries"
  - title: "Nests"
    url: "#nests"
  - title: "Local System Call"
    url: "#local-system-call"
  - title: "AWS Helpers"
    url: "#aws-helpers"
---

## Helper methods

SparkleFormation provides a collection of helper methods
for facilitating faster development and cleaner code. Some
helpers provide easier access to underlying SparkleFormation
functionality, while others provide automatic generation of
known template data structures.

### Functionality Helpers

#### Dynamics

Inserting a dynamic directly requires calling out to the
singleton method and providing the local context, which
looks like this:

~~~ruby
SparkleFormation.new(:test) do
  SparkleFormation.insert(:my_dynamic, self, :some => [:value])
end
~~~

The helper compacts this call to:

~~~ruby
SparkleFormation.new(:test) do
  dynamic!(:my_dynamic, :some => [:value])
end
~~~

#### Registries

Registries are used by calling out the singleton method and
providing the local context:

~~~ruby
SparkleFormation.new(:test) do
  SparkleFormation::Registry.insert(:my_registry, self, :some => [:value])
end
~~~

and can be compacted to:

~~~ruby
SparkleFormation.new(:test) do
  registry!(:my_registry, :some => [:value])
end
~~~

#### Nests

Nests are used by calling out to the singleton method and
providing the local context:

~~~ruby
SparkleFormation.new(:test) do
  SparkleFormation.nest(:my_template, self, :some => [:value])
end
~~~

and can be compacted to:

~~~ruby
SparkleFormation.new(:test) do
  nest!(:my_template, :some => [:value])
end
~~~

#### Other

##### Local system call

Use the `system!` helper method to shell out to the local system,
execute a command, and return the string output:

~~~ruby
SparkleFormation.new(:test) do
  parameters.creator.default system!('whoami')
end
~~~

### Generation Helpers

#### AWS Helpers

Data generation helpers are available for all the AWS
intrinsic functions and pseudo parameters:


##### Base intrinsic functions

* `base64!(VAL)`
* `find_in_map!(A, B, C)`
* `attr!(RESOURCE, ATTRIBUTE)`
* `azs!(REGION)`
* `join!(VAL1, VAL2, ...)`
* `select!(INDEX, ITEM)`
* `ref!(NAME)`

##### Pseudo Parameters

* `account_id!`
* `notification_arns!`
* `no_value!`
* `region!`
* `stack_id!`
* `stack_name!`

##### Conditional functions

AWS CFN supports runtime conditions. Helpers for building conditions:

* `and!(VAL1, VAL2, ...)`
* `equals!(VAL1, VAL2)`
* `not!(VAL)`
* `or!(VAL1, VAL2, ...)`
* `condition!(CONDITION_NAME)`

Helpers for using conditions:

* `if!(CONDITION_NAME)`

~~~ruby
SparkleFormation.new(:test) do
...
  some_value if!(:my_condition, TRUE_VALUE, FALSE_VALUE)
...
end
~~~

* `on_condition!(CONDITION_NAME)`

~~~ruby
SparkleFormation.new(:test) do
...
  resources.my_cool_resource do
    on_condition!(:stack_is_cool)
...
end
~~~
