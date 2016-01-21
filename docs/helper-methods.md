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
  - title: "Output to STDOUT"
    url: "#output-to-stdout"
  - title: "Raise Exceptions"
    url: "#raise-exceptions"
  - title: "Provider specific helpers"
    url: "#provider-specific-heleprs"
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

##### Output to STDOUT

Use the `puts!` helper method to print content to the console:

~~~ruby
SparkleFormation.new(:test) do
  puts! 'Hi everybody!'
  ...
end
~~~

##### Raise Exceptions

Use the `raise!` helper method to raise exceptions:

~~~ruby
SparkleFormation.new(:test) do
  raise! 'ERROR'
end
~~~

### Generation Helpers

#### Provider specific helpers

SparkleFormation includes provider specific helpers based on the
provider defined when instantiating the SparkleFormation template
instance. For example:

~~~ruby
SparkleFormation.new(:my_stack, :provider => :aws) do
  ...
  output.instance_id.value ref!(:my_instance)
end
~~~

will make the AWS specific helper functions available within this
template instance. If the provider specified Azure, then the Azure
specific helper methods would be available:

~~~ruby
SparkleFormation.new(:my_stack, :provider => :azure) do
  ...
  outputs.instance_id do
    type 'string'
    value reference_id(:my_instance)
  end
end
~~~

To see all the available helpers for specific providers, refer
to the library documentation:

* [AWS helpers](http://sparkleformation.github.io/sparkle_formation/SparkleFormation/SparkleAttribute/Aws.html)
* [Azure helpers](http://sparkleformation.github.io/sparkle_formation/SparkleFormation/SparkleAttribute/Azure.html)
* [HEAT helpers](http://sparkleformation.github.io/sparkle_formation/SparkleFormation/SparkleAttribute/Heat.html)
* [Rackspace helpers](http://sparkleformation.github.io/sparkle_formation/SparkleFormation/SparkleAttribute/Rackspace.html)