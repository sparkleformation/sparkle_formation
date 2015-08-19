## SparkleFormation Building Blocks

SparkleFormation provides a collection of building blocks to
assist in applying DRY concepts to template generation. The
building blocks provided by SparkleFormation are:

- [Components](#components)
- [Dynamics](#dynamics)
- [Registries](#registries)
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

```ruby
SparkleFormation.component(:common) do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  outputs.creator do
    description 'Stack creator'
    value ENV['USER']
  end
end
```

There are two supported ways of creating components:

* Path based components
* Name based components

#### Path based components

Path based components are components that infer their name based on
the base name of a file. These types of components use the `SparkleFormation.build`
method, which does not accept a name argument. For example:

```ruby
# components/common.rb
SparkleFormation.build do
   ...
end
```

The name of this component will be `common`.

#### Name based components

Name based components are components whose names are explicitly
defined. These types of components use the `SparkleFormation.component`
method, which accepts a name argument. For example:

```ruby
# components/my-common-component.rb
SparkleFormation.component(:core) do
  ...
end
```

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

```ruby
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
```

_NOTE: The underscore (`_`) prefix on the parameter names are simply a convention
and not required. It is a convention to make it easier to identify variables
used within the dynamic, and its usage is completely author dependent._

The dynamic defines two parameters: `_name` and `_config`. The `_config`
parameter is defaulted to an empty Hash allowing the dynamic call to optionally
accept a configuration Hash. With this dynamic in place, it can be called
multiple times within a template:

```ruby
SparkleFormation.new(:node_stack) do
  dynamic!(:node, :fubar)
  dynamic!(:node, :foobar, :ssh_key => 'default')
end
```

#### Builtin Dynamics

SparkleFormation includes a lookup of known AWS resources which can be accessed
using the `dynamic!` method. This lookup is provided simply as a convenience
to speed development and compact implementations. When a builtin is inserted,
it will automatically set the `type` of the resource and evaluate an optionally
provided block within the resource. The following two template below will generate
equivalent results when compiled:

```ruby
SparkleFormation.new(:with_dynamic) do
  dynamic!(:ec2_instance, :fubar).properties.key_name 'default'
end
```

```ruby
SparkleFormation.new(:without_dynamic) do
  resources.fubar_ec2_instance do
    type 'AWS::EC2::Instance'
    properties.key_name 'default'
  end
end
```

##### Builtin Lookup Behavior

Builtin lookups are based on the resource type. Resource matching is performed
using a *suffix based* match. When searching for matching types, the _first_
match is used. For example:

```ruby
SparkleFormation.new(:class_only) do
  dynamic!(:instance, :foobar)
end
```

When the lookup is performed, this will match the `AWS::EC2::Instance` resource.
This may not be the correct match, however, since there is also an
`AWS::OpsWorks::Instance` resource type. The correct lookup can be forced (if
the `OpsWorks` resource is the desired resource) by providing the namespace
prefix:

```ruby
SparkleFormation.new(:with_namespace) do
  dynamic!(:opsworks_instance, :foobar)
end
```

This can also be taken a step further by including the `AWS` namespace as well:

```ruby
SparkleFormation.new(:with_namespace) do
  dynamic!(:aws_opsworks_instance, :foobar)
end
```

but will likely be a bit superfluous. It is also important to note the name
of the generated resource is dependent on the value of the first parameter.
The resultant resource names from the above three examples will be:

* FoobarInstance
* FoobarOpsworksInstance
* FoobarAwsOpsworksInstance

The value used for the suffix of the resource name can be provided with
the `dynamic!` call:

```ruby
SparkleFormation.new(:with_namespace) do
  dynamic!(:aws_opsworks_instance, :foobar,
    :resource_suffix_name => :instance
  )
end
```
which will result in a resource name: `FoobarInstance`

##### Dynamic Lookup Behavior

##### Dynamic Return Context