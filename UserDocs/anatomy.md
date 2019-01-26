---
title: "Template Anatomy"
category: "dsl"
weight: 4
anchors:
  - title: "Parameters"
    url: "#parameters"
  - title: "Mappings"
    url: "#mappings"
  - title: "Conditions"
    url: "#conditions"
  - title: "Resources"
    url: "#resources"
  - title: "Outputs"
    url: "#outputs"  
---

## Template Anatomy

The anatomy of a template is dependent on the specific implementation that is
targeted. Due to the freeform nature of the SparkleFormation DSL any orchestration
API accepting a serialized document to describe resources is inherently supported.
Due to that fact, this document will focus directly on the AWS CloudFormation
style template as it is the most widely implemented.

### AWS CloudFormation in SparkleFormation

- [Base Attributes](#base-attributes)
- [Parameters](#parameters)
- [Mappings](#mappings)
- [Conditions](#conditions)
- [Resources](#resources)
- [Outputs](#outputs)

#### Base Attributes

All templates must begin with the expected API version and may include a description
and or metadata:

~~~ruby
SparkleFormation.new(:template) do
  set!('AWSTemplateFormatVersion', '2010-09-09')
  description 'My New Stack'
  metadata.instances.description 'Awesome instances'
end
~~~

* [Format Version](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/format-version-structure.html)
* [Description](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-description-structure.html)
* [Metadata](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/metadata-section-structure.html)

#### Parameters

Parameters are named variables available within the template that users may
provide customized values when creating or updating a stack. This allows
"runtime" modifications to occur when the template is evaluated by the API.

~~~ruby
SparkleFormation.new(:template) do
  parameters do
    creator do
      type 'String'
      default ENV['USER']
    end
  end
end
~~~

* [Parameters](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html)

#### Mappings

Mappings are a nested key/value store. They provide an easy way to dynamically
specify what value should be used based on context available when the template
is evaluated by the API.

~~~ruby
SparkleFormation.new(:template) do
  mappings.platforms.set!('us-west-2'._no_hump) do
    centos6 'ami-b6bdde86'
    centos7 'ami-c7d092f7'
  end
end
~~~

These can then be referenced using the `map!` helper method:

~~~ruby
SparkleFormation.new(:template) do
  dynamic!(:ec2_instance, :foobar) do
    properties.image_id map!(:platforms, region!, :centos7)
  end
end
~~~

* [Mappings](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html)
* [Fn::FindInMap](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html)

#### Conditions

Named conditions are defined in this section and then referenced
elsewhere in the template. Conditions can be used to customize resource
properties values or to allow/restrict the creation of resources and
outputs.


~~~ruby
SparkleFormation.new(:template) do
  parameters.creator do
    type 'String'
    default 'spox'
  end
  conditions do
    creator_is_spox equals!(ref!(:creator), 'spox')
  end
end
~~~

This condition can then be used to provide a custom value for a property:

~~~ruby
SparkleFormation.new(:template) do
  parameters.creator do
    type 'String'
    default 'spox'
  end
  conditions do
    creator_is_spox equals!(ref!(:creator), 'spox')
  end
  dynamic!(:ec2_instance, :fubar).properties do
    key_name if!(:creator_is_spox, 'spox-key', 'default')
  end
end
~~~

The condition can also be used to restrict the creation of a resource:

~~~ruby
SparkleFormation.new(:template) do
  parameters.creator do
    type 'String'
    default 'spox'
  end
  conditions do
    creator_is_spox equals!(ref!(:creator), 'spox')
  end
  dynamic!(:ec2_instance, :fubar) do
    on_condition! :creator_is_spox
  end
end
~~~

* [Conditions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html)
* [Condition Functions](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html)

#### Resources

Resources are the infrastructure items and configurations to be
provisioned by the orchestration API:

~~~ruby
SparkleFormation.new(:template) do
  resources.my_instance do
    type 'AWS::EC2::Instance'
    properties do
      key_name 'default'
      ...
    end
  end
end
~~~

* [Resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html)

#### Outputs

Outputs are resultant values from the provisioned infrastructure stack.
It generally contains information about specific resource attributes.

~~~ruby
SparkleFormation.new(:template) do
  outputs do
    instance_address do
      description 'Public IP of my instance'
      value attr!(:my_instance, :public_ip)
    end
  end
end
~~~

Conditions can also be applied on outputs:

~~~ruby
SparkleFormation.new(:template) do
  outputs do
    instance_address do
      description 'Public IP of my instance'
      value attr!(:my_instance, :public_ip)
      on_condition! :my_condition
    end
  end
end
~~~

* [Outputs](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html)
