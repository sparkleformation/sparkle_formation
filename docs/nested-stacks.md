---
title: "Nested Stacks"
category: "dsl"
weight: 6
anchors:
  - title: "Shallow Nesting"
    url: "#shallow-nesting"
  - title: "Deep Nesting"
    url: "#deep-nesting"
---

## Nested Stacks

Most orchestration API templating systems provide support for a
"stack" resource which allows for a stack to define one or more
_nested_ stacks within its resources. SparkleFormation expands
stack nesting by adding extra functionality when compiling
SparkleFormation templates. Currently two styles of expanded
functionality are available and are explained in depth below:

- [Shallow Nesting](#shallow-nesting)
- [Deep Nesting](#deep-nesting)

The interface for using SparkleFormation's nested stack functionality
is via the `nest!` helper method. The method accepts a template
name and will insert the stack resource into the current template:

~~~ruby
SparkleFormation.new(:root_template) do
  nest!(:networking)
  nest!(:applications)
end
~~~

### Shallow Nesting

Shallow stack nesting is the original style of nesting functionality
implemented within SparkleFormation. Key features/restrictions of
shallow nesting:

* Support nesting _one_ level deep
* Automatic parameter bubbling to root stack
* Automatic output mapping

#### Shallow Nesting Depth

Shallow nesting is restricted to single level nesting. This restriction
is in place due to the shallow nesting style being the first successfully
implemented nesting strategy. The restriction remains due to the unique
behavior this style of nesting provides which does not work well past
a single level of nesting.

#### Nested Parameter Bubbling

On compilation SparkleFormation will process nested stacks in a top-down
order. It will first extract parameter names from the nested stack. If
the root stack has no matching parameter, the parameter will automatically
be added to the root stack. For example:

~~~ruby
SparkleFormation.new(:template_a) do
  ...
  parameters.fubar do
    type 'String'
    default 'FOOBAR'
  end
end
~~~

~~~ruby
SparkleFormation.new(:root) do
  nest!(:template_a)
end
~~~

when when compiled would result in:

~~~json
...
  "Parameters": {
    "Fubar": {
      "Type": "String",
      "Default": "FOOBAR"
    }
  },
  "Resources": {
    "TemplateA": {
      "Type": "AWS::CloudFormation::Stack",
      "Properties": {
        "Parameters": {
          "Fubar": {
            "Ref": "Fubar"
          }

...
~~~

If a second stack is nested and it defines a parameter
with the same name as a previously defined parameter,
only the original parameter will be used and both stacks
will reference it.

This _parameter bubbling_ behavior allows all contained stacks
to be controlled from the root stack providing a single point
of interaction.

#### Nested Output Mapping

During compilation and processing of nested stacks, SparkleFormation
will also keep list of outputs available from previously processed
nested stack resources. If a parameter name on a nested stack
matches the name of an output defined in a nested stack, SparkleFormation
will automatically update the nested stack resource parameter to
use the output value. For example:

~~~ruby
SparkleFormation.new(:template_a) do
  ...
  outputs.address do
    description 'Address of thing'
    value ref!(:thing)
  end
  ...
end
~~~

~~~ruby
SparkleFormation.new(:template_b) do
  ...
  parameters.address do
    type 'String'
  end
  ...
end
~~~

~~~ruby
SparkleFormation.new(:root_template) do
  nest!(:template_a)
  nest!(:template_b)
end
~~~

When the final template file is compiled SparkleFormation will not
bubble the `Address` parameter to the root stack. Because `template_b`
defines an output with a matching name, SparkleFormation automatically
uses that output value:

~~~json
...
    "TemplateB": {
      "Type": "AWS::CloudFormation::Stack",
      "Properties": {
        "Parameters": {
          "Address": {
            "Fn:GetAtt": [
              "TemplateA",
              "Outputs.Address"
            ]
          }
...
~~~

Shallow nesting easily exposes the power of nesting stack resources
while maintaining a single point of access for managing a stack. This
is important to note when looking at the ease of use for updating
running stacks. Unless a template change is required, parameter changes
can be made via a single update call to the root stack. It also means
that parameter based updates can be provided from any acceptable interface,
be it a CLI tool, or web based UI.

_NOTE: One issue quickly encountered with parameter heavy nested stacks
is resource limits on the number of parameters allowed within a single
stack. Using deep stack nesting prevents this issue._

#### Shallow Nesting Usage

Shallow nesting is performed by calling `SparkleFormation#apply_nesting`.
The method expects a block to be provided. This block handles storage
of the nested stack template (if required) and any updates to the
original stack resource.

~~~ruby
sfn = SparkleFormation.compile(template_path, :sparkle)

sfn.apply_nesting(:shallow) do |stack_name, nested_stack_sfn, original_stack_resource|
  template_content = nested_stack_cfn.compile.dump!
  # store the template content as required, set remote location as `template_url`
  original_stack_resource.properites.delete!(:stack)
  original_stack_resource.properties.set!('TemplateURL', template_url)
end
~~~

### Deep Nesting

Deep stack nesting is an expansion of the shallow stack nesting functionality.
It loses some ease of use but gains greater functionality. Key features/
restrictions of deep stack nesting:

* No parameter bubbling
* Supports unlimited nesting depths*
* Automatic output mapping
  * Automatic output bubbling

#### Deep Nested Parameters

Deep stack nesting does not provide parameter bubbling. The biggest issue
in providing this type of behavior for deeply nested stacks are the limits
applied by the API. It also introduces more complexity to the implementation
since parameters would have to be propagated from the root stack to the
leaf stacks requiring the parameters.

Instead of bubbling parameters to the root stack, deep nesting behavior
does nothing with the parameters defined for nested stacks. It shifts that
responsibility to the application which can update resource's parameters
as it decides using its registered callback handler.

#### Unlimited Nesting Depth

Deep stack nesting does not enforce a limit on the number of levels deep
stacks may be nested. This _may_ not be true for the targeted API.
Supporting multiple levels of nesting makes it easy to logically
compartmentalize related resources into stacks, which can then be
collected and compartmentalized into category-style stacks which can be
nested into the root stack. This can make it easier to not only develop
stacks but easier to reason about as well.

#### Automatic Output Mapping and Bubbling

Much like the shallow nesting behavior, deep nesting provides automatic
output value mapping to parameters of a matching name. This behavior is
more challenging when using deep nesting behavior due to the possibility
of outputs being defined in a resource tree that is isolated from a
nested stack requiring its value. To solve this problem SparkleFormation
will automatically add an output entry to the parent stack(s) "bubbling"
the value until the output is available at the same level requesting stack.
If the requesting stack is nested from the common depth, then parameters
are added to the stacks to "push" the value down.

##### Output Bubbling Behavior

This example will illustrate the behavior seen when outputs are "bubbled":

~~~ruby
SparkleFormation.new(:networking) do
  ...
  outputs.subnet do
    description 'Networking subnet'
    value ref!(:subnet_resource)
  end
  ...
end
~~~

~~~ruby
SparkleFormation.new(:infrastructure) do
  ...
  nest!(:networking)
  ...
end
~~~

~~~ruby
SparkleFormation.new(:applications) do
  ...
  nest!(:moneymaker)
  ...
end
~~~

~~~ruby
SparkleFormation.new(:moneymaker) do
  parameters.subnet do
    type 'String'
  end
  ...
end
~~~

~~~ruby
SparkleFormation.new(:root) do
  nest!(:infrastructure)
  nest!(:applications)
end
~~~

When the `root` stack is compiled, it will first process the `infrastructure`
nesting, which will in turn process the `networking` nesting. After processing
those stacks, SparkleFormation will know the location of the `Subnet` output.
It will then process the `application` nesting, which has a `Subnet` parameter
matching a known output. Because the `Subnet` output from `networking` stack
is not accessible from the root stack to provide to the `application` stack,
SparkleFormation will add an output to the `infrastructure` stack "bubbling"
the output to the root stack. Once it is available at the root stack, it can
be passed to the `application` stack resource:

_NOTE: The below example includes the nested stack contents. A real template
will simply include a URL endpoint for fetching the document._

~~~json
{
  "Resources": {
    "Infrastructure": {
      "Type": "AWS::CloudFormation::Stack",
      "Properties": {
        "Stack": {
          "Resources": {
            "Networking": {
              "Type": "AWS::CloudFormation::Stack",
              "Properties": {
                "Stack": {
                  ...
                  "Outputs": {
                    "Subnet": {
                      "Description": "Networking subnet",
                      "Value": {
                        "Ref": "SubnetResource"
                      }
                    }
                  }
                }
              }
            },
            "TemplateURL": "http://example.com/Networking.json"
          },
          "Outputs": {
            "Subnet": {
              "Value": {
                "Fn::Att": [
                  "Networking",
                  "Outputs.Subnet"
                ]
              }
            }
          }
        },
        "TemplateURL": "http://example.com/Infrastructure.json"
      }
    },
    "Applications": {
      "Type": "AWS::CloudFormation::Stack",
      "Properties": {
        "Stack": {
          "Parameters": {
            "Subnet": {
              "Type": "String"
            }
          },
          "Resources": {
            "Moneymaker": {
              "Type": "AWS::CloudFormation::Stack",
              "Properties": {
                "Stack": {
                  "Parameters": {
                    "Subnet": {
                      "Type": "String"
                    }
                  }
                  ...
                },
                "Parameters": {
                  "Subnet": {
                    "Ref": "Subnet"
                  }
                },
                "TemplateURL": "http://example.com/Moneymaker.json"
              }
            }
          }
        },
        "Parameters": {
          "Subnet": {
            "Fn::Att": [
              "Infrastructure",
              "Outputs.Subnet"
            ]
          }
        },
        "TemplateURL": "http://example.com/Applications.json"
      }
    }
  }
}
~~~

When the `root` template is compiled, it nests the `infrastructure` template, which in turn
nests the `networking` template. The `Subnet` output is found, registered, and the compilation
continues. At this point the `networking` template is the last of this "branch", so compilation
returns to the `root` template and starts on the nested `applications` template. It has
`moneymaker` nested and when the `moneymaker` template is processed, the parameter `Subnet` is
checked in the registered outputs. Since a match is found, two things happen:

1. The `Subnet` output is "bubbled" to the `infrastructure` template
2. The `Subnet` output from the `infrastructure` template is "dripped" into the `applications`
template and passed to the `moneymaker` template

When a parameter is encountered and a matching output has been registered, SparkleFormation will
add stack outputs to parent templates until a common context can be found between the requesting
template (template with the parameter) and the providing template (template with the output). The
common context for the two templates may not make it accessible to the requesting template, which is
where the "dripping" method is employed.

Since the requesting template may not have access to the common context (as the example above illustrates),
SparkleFormation will "drip" the value down to the template. It does this by injecting a `Subnet` parameter
into child templates and passing the value in the stack resource until it reaches a common depth with
the requesting template. Once this is completed, the requesting template will have access to the output
from the provider template.

#### Deep Nesting Usage

Deep nesting is performed by calling `SparkleFormation#apply_nesting`.
The method expects a block to be provided. This block handles storage
of the nested stack template (if required) and any updates to the
original stack resource.

~~~ruby
sfn = SparkleFormation.compile(template_path, :sparkle)

sfn.apply_nesting(:deep) do |stack_name, nested_stack_sfn, original_stack_resource|
  template_content = nested_stack_cfn.compile.dump!
  # store the template content as required, set remote location as `template_url`
  original_stack_resource.properites.delete!(:stack)
  original_stack_resource.properties.set!('TemplateURL', template_url)
end
~~~
