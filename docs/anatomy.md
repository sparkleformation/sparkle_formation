## Template Anatomy

### Parameters
Parameters are prompts for stack specific values. A default may be
specified, but is not required. Every parameter must have a value at runtime.

In the Getting Started example we had one parameter, `web_nodes` which
set the min and max for the autoscaling group:

```ruby
parameters.web_nodes do
  type 'Number'
  description 'Number of web nodes for ASG.'
  default 2
end
```

Every parameter must have a type and a description. Available types are `String`,
`Number` (an integer), and `CommaDelimitedList` (an array of
strings, as-in: `['alpha', 'beta', '1', 2']`). The description is a
string describing the resource. 

Parameters support optional default values, declared as
above. An array of accepted values may be set, as well:

```ruby
parameters.web_nodes do
  type 'Number'
  description 'Number of web nodes for ASG.'
  default 2
  allowed_values [1, 2, 3, 5]
end
```

### Resources
Resources are the infrastructure resources that are provisioned with
the stack. Every resource must have a type that corresponds to a
supported cloud resource. Resources typically have a properties hash
that configures the resource. Some resources also have metadata. For
the complete list of required and optional options, see the
individual resource documentation.

Resource availability is not consistent across
providers. SparkleFormation's resources support is based on AWS, and
not all resources will be available on other platforms. See the
[resource reference](resource-reference.md) table for more information.

The prior example included the following resources:
- cfn_user: The IAM user for the stack, which will be used to
provision stack resources.

```ruby
resources.cfn_user do
  type 'AWS::IAM::User'
  properties.path '/'
  properties.policies _array(
    -> {
      policy_name 'cfn_access'
      policy_document.statement array!(
        -> {
          effect 'Allow'
          action 'cloudformation:DescribeStackResource'
          resource '*' 
        }
      )
    }
  )
end
```

- cfn_key: The IAM keys for the stack IAM user.

```ruby
resources.cfn_keys do
  type 'AWS::IAM::AccessKey'
  properties.user_name ref!(:cfn_user)
end
```

- website_asg: The autoscaling group containing website nodes. The
size of the autoscaling group is set to the value of the web_nodes
parameter. 

```ruby
resources.website_autoscale do
  type 'AWS::AutoScaling::AutoScalingGroup'
  properties do
    availability_zones az!
    launch_configuration_name ref!(:website_launch_config)
    min_size ref!(:web_nodes)
    max_size ref!(:web_nodes)
  end
end
```

- website_launch_configuration: The launch configuration for
website_asg nodes. The AMI image ID and instance type (size) are
required. `azs!` is a helper method for AWS's 'Fn::GetAZs' intrinsic
function, which returns all the availability zones available to an
account within the given region.

```ruby
resources.website_launch_config do
  type 'AWS::AutoScaling::LaunchConfiguration'
  properties do
    image_id 'ami-123456'
    instance_type 'm3.medium'
  end
end
```

- website_elb: The elastic load balancer for the website. The
listeners array configures port forwarding. The health check
configures the load balancer health check target and thresholds.

```ruby
resources.website_elb do
  type 'AWS::ElasticLoadBalancing::LoadBalancer'
  properties do
    availability_zones azs!
    listeners array!(
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
```

### Mappings
Mappings allow you to create key/value pairs which can be referenced
at runtime. This is useful for things like an image id that differs
by region or environment. 

Mappings for the 2014.09 Amazon Linux PV Instance Store 64-bit AMIs
for each US region:

```ruby
mappings.region_map do
  set!('us-east-1'._no_hump, :ami => 'ami-8e852ce6')
  set!('us-west-1'._no_hump, :ami => 'ami-03a8a146')
  set!('us-west-2'._no_hump, :ami => 'ami-f786c6c7')
end
```

These can be referenced, in turn, with the following:

```ruby
map!(:region_map, ref!('AWS::Region'), :ami)
```

'AWS::Region' is a psuedo parameter, which returns the AWS region. The
`_no_hump` method is used above to prevent automatic camel casing, so
the mapping key matches the region that is returned. Camel casing may
also be disabled for the entier block with `_camel_keys_set(:auto_disable)`.

We could also perform a lookup based on a parameter we provide,
e.g. an instance size based on the environment:

```ruby
parameters.environment do
  type 'String'
  allowed_values ['development', 'staging', 'production']                
end

mappings.instance_size do
_camel_keys_set(:auto_disable)
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
Outputs provide metadata for the stack, as key/value pairs within an
outputs block. Note that this block lives outside the resource
blocks. This will retrieve the DNSName attribute for our load
balancer, and provide it as a value for an 'Elb Dns' output:

```ruby
outputs do
  elb_dns do
    value attr!(:website_elb, 'DNSName')
    description "Website ELB DNS name"
  end
end
```

Outputs are not simply informational. You can interact with them
during [provisioning](provisioning.md#knife-cloudformation) using the [knife-cloudformation
plugin](https://rubygems.org/gems/knife-cloudformation). 


