---
title: "Compile Time Parameters"
category: "dsl"
weight: 10
anchors:
  - title: "Usage"
    url: "#usage"
  - title: "Template Nesting"
    url: "#template-nesting"
---

## Compile Time Parameters

Compile time parameters are parameters utilized during the compilation
of a template. These parameters can _only_ be used via the SparkleFormation
library. It is for this reason that compile time parameters are generally
discouraged from use. In most situations the structure of the template
can be refactored to remove any requirement of compile time parameters. To
handle the cases that fall outside of "most situations", SparkleFormation
provides support for compile time parameters.

### Usage

Compile time parameters are defined during the instantiation of a template:

~~~ruby
SparkleFormation.new(:test,
  :compile_time_parameters => {
    :number_of_nodes => {
      :type => :number,
      :default => 1
    }
  }
) do

  state!(:number_of_nodes).times do |i|
    dynamic!(:ec2_instance, "node_#{i}")
  end

end
~~~

#### Parameter Declaration

Declaring compile time parameters is done via the `:compile_time_parameters`
option when instantiating a new template. This option expects a `Hash` value
with the compile time parameter names as the key, and the parameter options
as the value. The available items within the option `Hash` for compile time
parameters:

* `:type` - Data type of parameter
  * Required: yes
  * Valid: `:number`, `:string`
  * Default: none
* `:description` - Description of the parameter
  * Required: no
  * Valid: `String`
  * Default: none
* `:default` - Default value for parameter
  * Required: no
  * Valid: `String`, `Integer`
  * Default: none
* `:multiple` - Accept multiple values
  * Required: no
  * Valid: `TrueClass`, `FalseClass`
  * Default: `false`
* `:prompt_when_nested` - Prompt for value when template is nested
  * Required: no
  * Valid: `TrueClass`, `FalseClass`
  * Default: `true`

##### Multiple value support

The `:multiple` option for compile time parameters will automatically convert
a received comma-delimited list into an `Array` of items. Each item in the list
must be the expected type for the parameter. For example, a compile time parameter
defined as:

~~~ruby
SparkleFormation.new(:test,
  :compile_time_parameters => {
    :network_ids => {
      :type => :string,
      :multiple => true
    }
  }
)
~~~

If the value provided for this parameter is:

~~~
network-a2413, network-cs214, network-as113
~~~

The resulting value when accessed will be:

~~~ruby
[
  "network-a2413",
  "network-cs214",
  "network-as113"
]
~~~

##### Prompting when nested

The `:prompt_when_nested` is used by implementations to suppress parameter prompts
when the template is encountered in a nested context. This allows for parent templates
to handle compile time parameters for a nested template, but the nested template still
retains its ability to be built in a standalone context.

#### Accessing Parameter Values

Compile time parameter values can be accessed via the `state!` method. If a compile time
parameter has been defined for a template, and no value has been provided when that template
is compiled, `state!` will raise an `ArgumentError`. This exception will only be raised on
defined compile time parameters, and not other values that may be persisted within the state.

Example usage:

~~~ruby
SparkleFormation.new(:test,
  :compile_time_parameters => {
    :number_of_nodes => {
      :type => :number,
      :default => 1
    }
  }
) do

  state!(:number_of_nodes).times do |i|
    dynamic!(:ec2_instance, "node_#{i}")
  end

end
~~~

#### Template Modification

When compile time parameters are present SparkleFormation will automatically adjust the outputs
of the template to include a `CompileState` output. The output will contain a JSON dump of the
compile time parameter values used to generate the template. This allows update requests to
fetch the previous state and seed the compilation of the updated template. This approach provides
consistency and removes any requirement of prior knowledge about how a template was used to build
a stack.

### Template Nesting

Compile time parameters are local to a given template instance. A parent template can provide
compile time parameters when nesting a template. This is done using the `:parameters` option
when nesting:

~~~ruby
SparkleFormation.new(:node_generator,
  :parameters => {
    :number_of_nodes => {
      :type => :number,
      :prompt_when_nested => false
    }
  }
) do
  state!(:number_of_nodes).times do |i|
    dynamic!(:ec2_instance, "node_#{i}")
  end

end

SparkleFormation.new(:root) do
  nest!(:nested_template,
    :parameters => {
      :number_of_nodes => 5
    }
  )
end
~~~

In this example the `:root` template is providing the compile time parameter `:number_of_nodes`
explicitly to the `:node_generator` template. Due to the compile time parameter option
`:prompt_when_nested` being set to false, when the `:root` template is compiled, no prompt
will be received for the `:number_of_nodes` compile time parameter. However, if the
`:node_generator` template is compiled directly, the prompt will be received.