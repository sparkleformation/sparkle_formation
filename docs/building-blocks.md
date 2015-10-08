---
title: "SparkleFormation Building Blocks"
category: "dsl"
weight: 3
anchors:
  - title: "Components"
    url: "#components"
  - title: "Dynamics"
    url: "#dynamics"
  - title: "Registry"
    url: "#registry"
  - title: "Templates"
    url: "#templates"
---

## SparkleFormation Building Blocks

### Building Blocks

SparkleFormation provides a collection of building blocks to
assist in applying [DRY][1] concepts to template generation. The
building blocks provided by SparkleFormation are:

- [Components](#components)
- [Dynamics](#dynamics)
- [Registry](#registry)
- [Templates](#templates)

### Components

Components are static pieces of template that are inserted once.
They do not provide any dynamic functionality and are intended
for common static content. Components are the second set of items
loaded during template compilation and are evaluated in the order
defined.

An example component for an AWS CloudFormation based implementation
may contain the template versioning information and a common stack
output value:

~~~ruby
SparkleFormation.component(:common) do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  outputs.creator do
    description 'Stack creator'
    value ENV['USER']
  end
end
~~~

There are two supported ways of creating components:

* Path based components
* Name based components

#### Path based components

Path based components are components that infer their name based on
the base name of a file. These types of components use the `SparkleFormation.build`
method, which does not accept a name argument. For example:

~~~ruby
# components/common.rb
SparkleFormation.build do
   ...
end
~~~

The name of this component will be `common`.

#### Name based components

Name based components are components whose names are explicitly
defined. These types of components use the `SparkleFormation.component`
method, which accepts a name argument. For example:

~~~ruby
# components/my-common-component.rb
SparkleFormation.component(:core) do
  ...
end
~~~

The name of this component will be `core` as it is explicitly provided
when creating the component. These name based components are specifically
geared towards usage in "sparkle packs" or any other implementations where
a single file may provide multiple components or building blocks, or where
the file name may be required to be different from the name of the component.

### Dynamics

Dynamics are reusable blocks of code that can be applied multiple times
within the same template to provide multiple discrete sets of content.
They provide the ability to refactor common template content out into
reusable and configurable dynamics that can then be re-inserted using
customized naming structures. Dynamics _always_ explicitly define their
name when creating unlike components which optionally supports explict
naming.

Dynamics are registered blocks which accept two parameters:

1. Name for the dynamic call
2. Configuration Hash for the dynamic call

Here is an example dynamic:

~~~ruby
# dynamics/node.rb
SparkleFormation.dynamic(:node) do |_name, _config={}|
  unless(_config[:ssh_key])
    parameters.set!("#{_name}_ssh_key".to_sym) do
      type 'String'
    end
  end
  dynamic!(:ec2_instance, _name).properties do
    key_name _config[:ssh_key] ? _config[:ssh_key] : ref!("#{_name}_ssh_key".to_sym)
  end
end
~~~

*NOTE: The underscore (`_`) prefix on the parameter names are simply a convention
and not required. It is a convention to make it easier to identify variables
used within the dynamic, and its usage is completely author dependent.*

The dynamic defines two parameters: `_name` and `_config`. The `_config`
parameter is defaulted to an empty Hash allowing the dynamic call to optionally
accept a configuration Hash. With this dynamic in place, it can be called
multiple times within a template:

~~~ruby
SparkleFormation.new(:node_stack) do
  dynamic!(:node, :fubar)
  dynamic!(:node, :foobar, :ssh_key => 'default')
end
~~~

#### Builtin Dynamics

SparkleFormation includes a lookup of known AWS resources which can be accessed
using the `dynamic!` method. This lookup is provided simply as a convenience
to speed development and compact implementations. When a builtin is inserted,
it will automatically set the `type` of the resource and evaluate an optionally
provided block within the resource. The following two template below will generate
equivalent results when compiled:

~~~ruby
SparkleFormation.new(:with_dynamic) do
  dynamic!(:ec2_instance, :fubar).properties.key_name 'default'
end
~~~

~~~ruby
SparkleFormation.new(:without_dynamic) do
  resources.fubar_ec2_instance do
    type 'AWS::EC2::Instance'
    properties.key_name 'default'
  end
end
~~~

##### Builtin Lookup Behavior

Builtin lookups are based on the resource type. Resource matching is performed
using a *suffix based* match. When searching for matching types, the _first_
match is used. For example:

~~~ruby
SparkleFormation.new(:class_only) do
  dynamic!(:instance, :foobar)
end
~~~

When the lookup is performed, this will match the `AWS::EC2::Instance` resource.
This may not be the correct match, however, since there is also an
`AWS::OpsWorks::Instance` resource type. The correct lookup can be forced (if
the `OpsWorks` resource is the desired resource) by providing the namespace
prefix:

~~~ruby
SparkleFormation.new(:with_namespace) do
  dynamic!(:opsworks_instance, :foobar)
end
~~~

This can also be taken a step further by including the `AWS` namespace as well:

~~~ruby
SparkleFormation.new(:with_namespace) do
  dynamic!(:aws_opsworks_instance, :foobar)
end
~~~

but will likely be a bit superfluous. It is also important to note the name
of the generated resource is dependent on the value of the first parameter.
The resultant resource names from the above three examples will be:

* FoobarInstance
* FoobarOpsworksInstance
* FoobarAwsOpsworksInstance

The value used for the suffix of the resource name can be provided with
the `dynamic!` call:

~~~ruby
SparkleFormation.new(:with_namespace) do
  dynamic!(:aws_opsworks_instance, :foobar,
    :resource_suffix_name => :instance
  )
end
~~~

which will result in a resource name: `FoobarInstance`

##### Dynamic Return Context

When defining custom dynamics, the result of the dynamic block is important.
Many times a dynamic can be making multiple modifications to a template when
inserted (addition of parameters, resources, and/or outputs). It is important
to be aware of the importance of the value returned from the dynamic block to
prevent surprise for users. When `dynamic!` is called and provided a block, that
block is evaluated within the context returned from the requested dynamic.

For example, this is a poor implementation of a dynamic:

~~~ruby
SparkleFormation.dynamic(:bad_dynamic) do |_name, _config|
  dynamic!(:ec2_instance, _name)
  outputs do
    address.value attr!("#{_name}_ec2_instance".to_sym, :public_ip)
  end
end
~~~

If a template attempts to use this dynamic and make an override modification
to the instance:

~~~ruby
SparkleFormation.new(:failed_template) do
  dynamic!(:bad_dynamic, :foobar) do
    properties.key_name 'default'
  end
end
~~~

The `properties.key_name` will be evaluated within the context of the `outputs`
because it is the returned value of the dynamic block. Instead the dynamic should
return the context of the referenced resource (if applicable). To make the
dynamic act as expected, the resource must be returned from the block:

~~~ruby
SparkleFormation.dynamic(:good_dynamic) do |_name, _config|
  _resource = dynamic!(:ec2_instance, _name)
  outputs do
    address.value attr!("#{_name}_ec2_instance".to_sym, :public_ip)
  end
  _resource
end
~~~

This ensures the instance resource is the context returned, and provided blocks
will work as expected:

~~~ruby
SparkleFormation.new(:successful_template) do
  dynamic!(:good_dynamic, :foobar) do
    properties.key_name 'default'
  end
end
~~~

##### Dynamic Lookup Behavior

Dynamics can be loaded from multiple locations. When SparkleFormation performs
a dynamic lookup, the following locations are checked in order of precedence:

1. Implementation local `dynamics` directory
2. SparklePack dynamics with reverse load order precedence
3. Builtin dynamics lookup table

### Registry

Registry entries are lightweight dynamics that are useful for storing items that
may be used in multiple locations. For example, the valid sizes of an instance
within an infrastructure will generally be restricted to a specific list.
This list can be stored within a registry to provide a single point of
contact for any changes:

~~~ruby
SfnRegistry.register(:instance_sizes) do
  [
    'm3.large',
    'm3.medium',
    't2.medium'
  ]
end
SfnRegistry.register(:instance_size_default){ 'm3.medium' }
~~~

With the value registered, it can then be referenced:

~~~ruby
SparkleFormation.new(:instance_stack) do
  parameters.instance_size do
    type 'String'
    allowed_values registry!(:instance_sizes)
    default registry!(:instance_size_default)
  end
end
~~~

### Templates

Templates are the files that pull all the building blocks together to produce
a final data structure to be serialized into a document which can then be
submitted to an orchestration API. There are three stages of template compilation:

1. Evaluate optional block given on instantiation
2. Evaluate any loaded components
3. Evaluate `override` block

#### Instantiation Block

A block provided on instantiation is the first block evaluated:

~~~ruby
SparkleFormation.new(:my_template) do
  dynamic!(:ec2_instance, :foobar)
end
~~~

#### Loaded Components

Components are evaluated in the order they are added to the template via
the `load` method:

~~~ruby
SparkleFormation.new(:my_template) do
  dynamic!(:ec2_instance, :foobar)
end.load(:common, :special)
~~~

On compilation, this will evaluate the instantiation block first, the `common`
component second, and finally the `special` component.

#### Overrides

Override blocks are the final blocks evaluated during compilation:

~~~ruby
SparkleFormation.new(:my_template) do
  dynamic!(:ec2_instance, :foobar)
end.load(:common, :special).overrides do
  resources.foobar_ec2_instance.properties.key_name 'default'
end
~~~

[1]: https://en.wikipedia.org/wiki/Don%27t_repeat_yourself
