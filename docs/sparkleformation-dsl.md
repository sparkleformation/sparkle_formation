## SparkleFormation DSL

The SparkleFormation DSL (domain specific language) is based
on (and built on top of) the [AttributeStruct](https://github.com/chrisroberts/attribute_struct)
library. This provides SparkleFormation with its free-form behavior
and allows immediate support of any template style or API
updates requiring modifications to existing templates.

For a closer look at the underlying features provided by
the AttributeStruct library, please refer to the
[AttributeStruct documentation](https://chrisroberts.github.io/attribute_struct).

### Behavior

The behavior of the SparkleFormation DSL is largely dictated by the
AttributeStruct library, and as such are not specific to SparkleFormation
alone. Some optional features of the AttributeStruct library are automatically
enabled when using SparkleFormation, most notably the automatic camel casing
of key values.

#### Key Alteration

The default behavior of SparkleFormation is to camel case all Hash keys.
This is done via:

```ruby
AttributeStruct.camel_keys = true
```

And results in all Hash keys in the resultant compile Hash being converted
to a camel cased format:

```ruby
SparkleFormation.new(:test) do
  parameters.creator.default 'spox'
end
```

The resultant data structure after compiling:

```ruby
{
  "Parameters": {
    "Creator": {
      "Default": "spox"
    }
  }
}
```

In some cases it may be desired to have a key _not_
be automatically camel cased. Camel casing can be
disabled via a helper method that is attached to the
Symbol and String instances:

```ruby
SparkleFormation.new(:test) do
  parameters.set!(:creator.disable_camel!).default 'spox'
end
```

The resultant data structure after compiling:

```ruby
{
  "Parameters": {
    "creator": {
      "Default": "spox"
    }
  }
}
```

Depending on the formatting of the target template there
may be lack of consistency within certain locations. A
classic example of this inconsistency can be seen in the
`AWS::CloudFormation::Init` metadata section on compute
type resources. Within the context of this `Init` section
the format of the keys change from the standard camel casing
to a snake cased format. It is possible to handle this by using
the `disable_camel!` method for all defined keys, but it is
clunky and reduces the readability of the code.

As the data structure is built when compiling the SparkleFormation
template state is tracked at each "level" of the data structure.
When the camel casing is enabled on AttributeStruct, this is merely
the default behavior and can be overridden, even from within
the DSL. For example:

```ruby
SparkleFormation.new(:test) do
  parameters do
    camel_keys_set!(:auto_disable)
    creator.default 'spox'
  end
  outputs.creator.value ref!(:creator.disable_camel!)
end
```

The resultant data structure after compiling:

```ruby
{
  "Parameters": {
    "creator": {
      "default": "spox"
    }
  },
  "Outputs": {
    "Value": {
      "Ref": "creator"
    }
  }
}
```

This example shows how the behavior of the Hash key modification
can be altered at a specific context within the data structure.
New values added (as well as nested) will not the camel casing
modification applied. The behavior can be adjusted at multiple
depth locations, and that behavior will persist on re-entry:

```ruby
SparkleFormation.new(:test) do
  parameters do
    camel_keys_set!(:auto_disable)
    creator do
      camel_keys_set!(:auto_enable)
      default 'spox'
    end
  end
  outputs.creator.value ref!(:creator.disable_camel!)
  parameters.creator.type 'String'
  parameters.author.default 'John Doe'
end
```

The resultant data structure after compiling:

```ruby
{
  "Parameters": {
    "creator": {
      "Default": "spox"
      "Type": "String"
    },
    "author": {
      "default": "John Doe"
    }
  },
  "Outputs": {
    "Value": {
      "Ref": "creator"
    }
  }
}
```
## Features

### Data Access

As a SparkleFormation template is compiled it is dynamically
building the data structure defined by the template. Because
this data structure is being generated during compilation, the
template itself has access to this data and can inspect the
state of the data structure as it exists _at that specific
time_. This allows for inspecting previously defined data
and using that data for decision making, or to copy/modify into
other locations.
