## Overview
SparkleFormation is a Ruby DSL for programatically composing
[AWS Cloudformation][cloudformation], [OpenStack Heat][heat]
provisioning templates for the purpose of interacting with cloud
infrastructure orchestration APIs.

SparkleFormation templates describe the creation and configuration of
collections of cloud resources (a stack) as code, allowing you to
provision stacks in a predictable and repeatable manner. Stacks can be
managed as single unit, allowing you to create, modify, or delete
collections of resources via a single API call.

SparkleFormation composes templates in the native cloud orchestration
formats for AWS, Rackspace, Google Compute, and similar services.

## Table of Contents

- [Getting Started](#getting-started)
- [Template Anatomy](#template-anatomy)
  - [Parameters](#parameters)
  - [Resources](#resources)
  - [Mappings](#mappings)
  - [Outputs](#outputs)
- [Intrinsic Functions](#intrinsic-functions)
  - [Ref](#ref)
  - [Attr](#attr)
  - [Join](#join)
- [Universal Properties](#universal-properties)
 - [Tags](#tags)
- [Building Blocks](#sparkleformation-building-blocks)
  - [Components](#components)
  - [Dynamics](#dynamics)
  - [Registries](#registries)

## Getting Started
Below is a basic SparkleFormation template which would provision an
elastic load balancer forwarding port 80 to an autoscaling group of
ec2 instances.

```ruby
SparkleFormation.new('website') do

  set!('AWSTemplateFormatVersion', '2010-09-09')

  description 'Supercool Website'

  parameters.web_nodes do
    type 'Number'
    description 'Number of web nodes for ASG.'
    default '2'
  end

  resources.cfn_user do
    type 'AWS::IAM::User'
    properties.path '/'
    properties.policies _array(
      -> {
        policy_name 'cfn_access'
        policy_document.statement _array(
          -> {
            effect 'Allow'
            action 'cloudformation:DescribeStackResource'
            resource '*' 
          }
        )
      }
    )
  end

  resources.cfn_keys do
    type 'AWS::IAM::AccessKey'
    properties.user_name ref!(:cfn_user)
  end

  resources.website_autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      availability_zones({'Fn::GetAZs' => ''})
      launch_configuration_name ref!(:website_launch_config)
      min_size ref!(:web_nodes)
      max_size ref!(:web_nodes)
    end
  end

  resources.website_launch_config do
    type 'AWS::AutoScaling::LaunchConfiguration'
    properties do
      image_id 'ami-123456'
      instance_type 'm3.medium'
    end
  end

  resources.website_elb do
    type 'AWS::ElasticLoadBalancing::LoadBalancer'
    properties do
      availability_zones._set('Fn::GetAZs', '')
      listeners _array(
        -> {
          load_balancer_port '80'
          protocol 'HTTP'
          instance_port '80'
          instance_protocol 'HTTP'
        }
      )
      health_check do
        target 'HTTP:80/'
        healthy_threshold '3'
        unhealthy_threshold '3'
        interval '5'
        timeout '15'
      end
    end
  end
end
```

## Template Anatomy

### Parameters
Parameters are prompts for stack specific values. A default may be
specified, but is not required. Every parameter must have a value at runtime.
- web_nodes: The number of nodes for the autoscaling group.

### Resources
Resources are the infrastructure resources that are provisioned with
the stack. Every resource must have a type that corresponds to a
supported cloud resource. Resources typically have a properties hash
that configures the resource. Some resources also have metadata. For
the complete list of required and optional options, see the
individual resource documentation.
- cfn_user: The IAM user for the stack, which will be used to
provision stack resources.
- cfn_key: The IAM keys for the stack IAM user.
- website_asg: The autoscaling group containing website nodes. The
size of the autoscaling group is set to the value of the web_nodes parameter. 
- website_launch_configuration: The launch configuration for
website_asg nodes. The AMI image ID and instance type (size) are
required. 
- website_elb: The elastic load balancer for the website. The
listeners array configures port forwarding. The health check
configures the load balancer health check target and thresholds.


### Mappings
Mappings allow you to create key/value pairs which can be referenced
at runtime. This is useful for things like an AMI value that differs
by region or environment. 

Mappings for the 2014.09 Amazon Linux PV Instance Store 64-bit AMIs
for each US region:
```ruby
mappings.region_map do
  set!('us-east-1', :ami => 'ami-8e852ce6')
  set!('us-west-1', :ami => 'ami-03a8a146')
  set!('us-west-2', :ami => 'ami-f786c6c7')
end
```
These can be referenced, in turn, with the following:
```ruby
map!(:region_map, ref!('AWS::Region'), :ami)
```
'AWS::Region' is a psuedo parameter. We could also perform a lookup
based on a parameter we provide, e.g. an instance size based on the environment:

```ruby
parameters.environment do
  type 'String'
  allowed_values ['development', 'staging', 'production']                
end

mappings.instance_size do
  set!('development', :instance => 'm3.small')
  set!('staging', :instance => 'm3.medium')
  set!('production', :instance => 'm3.large')
end

resources.website_launch_config do
  type 'AWS::AutoScaling::LaunchConfiguration'
  properties do
    image_id map!(:region_map, 'AWS::Region', :ami)
    instance_type map!(:instance_size, ref!(:environment), :instance)
  end
end
```
### Outputs
Outputs are similar to tags, but apply to the entire stack, rather
than individual resources. These are provided as key/value pairs
within an outputs block. Note that this block lives outside the
resource blocks. This will retrieve the DNSName attribute for our load
balancer, and provide it as a value for an 'Elb Dns' output.
```ruby
  outputs do
    elb_dns do
      value attr!(:website_elb, 'DNSName')
      description "Website ELB DNS name"
    end
  end
```
Future versions of SparkleFormation and the knife-cloudformation
plugin will support  ingesting an existing stack's outputs as
parameters in another stack.

## Intrinsic Functions
The following are all intrinsic AWS Cloudformation functions that are
supported with special syntax in SparkleFormation. Note that these may
not be implemented for all providers. 

### Ref
Ref allows you to reference parameter and resource values. We did this
earlier with the autoscaling group size:
```ruby
parameters.web_nodes do
  type 'Number'
  description 'Number of web nodes for ASG.'
  default '2'
end

...

min_size ref!(:web_nodes)
```
It also works for resource names. The following returns the name of
the launch configuration so we can use it in the autoscaling group
properties. 
```ruby
ref!(:website_launch_config)
```  

### Join
A Join combines strings. You can use Refs and Mappings within a Join.
```ruby
join!(ref!(:environment), '-', map!(:region_map, ref!('AWS::Region'), :ami))
```
Would return 'development-us-east-1', if we built a stack in the
AWS  Virgnia region and provided 'development' for the environment
parameter. 

### Attr
Certain resources attributes can be retrieved directly. To access an
IAM user's (in this case, :cfn_user) secret key:
```ruby
attr!(:cfn_user, :secret_access_key)
```

## Universal Properties

### Tags
Tags can be applied to any resource. These make it easy to track
resource usage across stacks. They may be used for cost tracking as
well as configuration tools that are cloud-infrastructure aware. Tags
are provided as key/value pairs within an array. In this example we
provide the stack name and a contact email:
```ruby
  resources.website_autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      availability_zones({ 'Fn::GetAZs' => '' })
      tags _array(
        -> {
          key 'StackName'
          value ref!('AWS::StackName'))
          propagate_at_launch true
        },
        -> {
          key 'ContactEmail'
          value support@hw-ops.com'
          propagate_at_launch true
        }
      )
      launch_configuration_name ref!(:website_launch_config)
    end
```

## SparkleFormation Building Blocks

Using SparkleFormation for the above template has already saved us
many keystrokes, but what about reusing SparkleFormation code between
similar stacks? This is where SparkleFormation concepts like
components, dynamics, and registries come into play.

### Components

Components are static configuration which can be reused between many
stack templates. In our example case we have decided that all our
stacks will need to make use of IAM credentials, so we will create
a component which allows us to inserts the two IAM resources into any
template in a resuable fashion. The component, which we will call
'base' and put in a file called 'base.rb,' would look like this:

```ruby
SparkleFormation.build do
  set!('AWSTemplateFormatVersion', '2010-09-09')

  resources.cfn_user do
    type 'AWS::IAM::User'
    properties.path '/'
    properties.policies _array(
      -> {
        policy_name 'cfn_access'
        policy_document.statement _array(
          -> {
            effect 'Allow'
            action 'cloudformation:DescribeStackResource'
            resource '*' 
          }
        )
      }
    )
  end

  resources.cfn_keys do
    type 'AWS::IAM::AccessKey'
    properties.user_name ref!(:cfn_user)
  end
end
```

After moving these resources out of the initial template and into a
component, we will update the template so that the base component is
loaded on the first line, and the resources it contains are no longer
present in the template itself:

```ruby
SparkleFormation.new(:website).load(:base).overrides do

  description 'Supercool Website'

  parameters.web_nodes do
    type 'Number'
    description 'Number of web nodes for ASG.'
    default '2'
  end

  resources.website_autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      availability_zones({'Fn::GetAZs' => ''})
      launch_configuration_name ref!(:website_launch_config)
      min_size ref!(:web_nodes)
      max_size ref!(:web_nodes)
    end
  end

  resources.website_launch_config do
    type 'AWS::AutoScaling::LaunchConfiguration'
    properties do
      image_id 'ami-123456'
      instance_type 'm3.medium'
    end
  end

  resources.website_elb do
    type 'AWS::ElasticLoadBalancing::LoadBalancer'
    properties do
      availability_zones._set('Fn::GetAZs', '')
      listeners _array(
        -> {
          load_balancer_port '80'
          protocol 'HTTP'
          instance_port '80'
          instance_protocol 'HTTP'
        }
      )
      health_check do
        target 'HTTP:80/'
        healthy_threshold '3'
        unhealthy_threshold '3'
        interval '5'
        timeout '15'
      end
    end
  end
end
```

### Dynamics

Like components, dynamics are another SparkleFormation feature which
enables code reuse between stack templates. Where components are
static, dynamics are useful for creating unique resources via
the passing of arguments.

In our example scenario we have decided that we want to use elastic
load balancer resources in many of our stack templates, we want to
create a dynamic which makes inserting ELB resources much easier than
copying the full resource configuration between templates.

The resulting implementation would look something like this:

```ruby
SparkleFormation.dynamic(:elb) do |_name, _config={}|
  resources("#{_name}_elb".to_sym) do
    type 'AWS::ElasticLoadBalancing::LoadBalancer'
    properties do
      availability_zones._set('Fn::GetAZs', '')
      listeners _array(
        -> {
          load_balancer_port _config[:load_balancer_port] || '80'
          protocol _config[:protocol] || 'HTTP'
          instance_port _config[:instance_port] || '80'
          instance_protocol _config[:instance_protocol] || 'HTTP'
        }
      )
      health_check do
        target _config[:target] || 'HTTP:80/'
        healthy_threshold _config[:healthy_threshold] || '3'
        unhealthy_threshold _config[:unhealthy_threshold] || '3'
        interval _config[:interval] || '5'
        timeout _config[:timeout] || '15'
      end
    end
  end
end
```

This dynamic accepts two arguments: a name (a string, required) and configuration
(a hash, optional). The dynamic will use the values passed in these
arguments to generate a new ELB resource, and override the default ELB
properties wherever a corresponding key/value pair is provided in the
_config hash.

Once updated to make use of the new ELB dynamic, our template looks
like this:

```ruby
SparkleFormation.new(:website).load(:base).overrides do

  description 'Supercool Website'

  parameters.web_nodes do
    type 'Number'
    description 'Number of web nodes for ASG.'
    default '2'
  end

  resources.website_autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      availability_zones({'Fn::GetAZs' => ''})
      launch_configuration_name ref!(:website_launch_config)
      min_size ref!(:web_nodes)
      max_size ref!(:web_nodes)
    end
  end

  resources.website_launch_config do
    type 'AWS::AutoScaling::LaunchConfiguration'
    properties do
      image_id 'ami-123456'
      instance_type 'm3.medium'
    end
  end

  dynamic!(:elb, 'website')
end
```

If we wanted to override the default configuration for the ELB,
e.g. to configure the ELB to listen on and communicate with back-end
node on port 8080 instead of 80, we can specify these override values
in the configuration passed to the ELB dynamic:

```ruby
  dynamic!(:elb, 'website', :load_balancer_port => 8080,
  :instance_port => 8080)
```

The arguments being passed here are as follows:

1. :elb is the name of the dynamic to be inserted, as a ruby symbol
2. the name (referred to as _name in our dynamic code) to be used when generating unique resource names
3. one or more key/value pairs which are passed into the dynamic as
the _config hash.

### Registries

Similar to dynamics, registries are reusable resource configuration
code which can be reused inside different resource definitions.

Registries are useful for defining properties that may be reused
between resources of different types. For example, the
LaunchConfiguration and Instance resource types make use of metadata
properties which inform both resource types how to bootstrap one or
more instances.

In our example scenario we would like our new instances to run
'sudo apt-get update && sudo apt-get upgrade -y' at first boot,
regardless of whether or not the instances are members of an
autoscaling group.

Because these resources are of different types, placing the metadata
required for this task directly inside a dynamic isn't going to work
quite the way we need. Instead we can put this inside a registry which
can be inserted into the resources defined in one or more dynamics:

```ruby
SparkleFormation::Registry.register(:apt_get_update) do
  metadata('AWS::CloudFormation::Init') do
    _camel_keys_set(:auto_disable) do
    commands('01_apt_get_update') do
      command 'sudo apt-get update'
    end
    commands('02_apt_get_upgrade') do
      command 'sudo apt-get upgrade -y'
    end
  end
end
```

Now we can insert this registry entry into our existing template:

```ruby
SparkleFormation.new(:website).load(:base).overrides do

  description 'Supercool Website'

  parameters.web_nodes do
    type 'Number'
    description 'Number of web nodes for ASG.'
    default '2'
  end

  resources.website_autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      availability_zones({'Fn::GetAZs' => ''})
      launch_configuration_name ref!(:website_launch_config)
      min_size ref!(:web_nodes)
      max_size ref!(:web_nodes)
    end
  end

  resources.website_launch_config do
    type 'AWS::AutoScaling::LaunchConfiguration'
    registry!(:apt_get_update, 'website')
    properties do
      image_id 'ami-123456'
      instance_type 'm3.medium'
    end
  end

  dynamic!(:elb, 'website')
end
```

[cloudformation]: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-guide.html
[heat]:
http://docs.openstack.org/developer/heat/template_guide/index.html

