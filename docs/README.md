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
- [Building Blocks](building-blocks.md)
  - [Components](building-blocks.md#components)
  - [Dynamics](building-blocks.md#dynamics)
  - [Registries](building-blocks.md#registries)
- [Template Anatomy](anatomy.md)
  - [Parameters](anatomy.md#parameters)
  - [Resources](anatomy.md#resources)
  - [Mappings](anatomy.md#mappings)
  - [Outputs](anatomy.md#outputs)
- [Intrinsic Functions](functions.md)
  - [Ref](functions.md#ref)
  - [Attr](functions.md#attr)
  - [Join](functions.md#join)
- [Universal Properties](properties.md)
 - [Tags](properties.md#tags)

## Getting Started
Below is a basic SparkleFormation template which would provision an
elastic load balancer forwarding port 80 to an autoscaling group of
ec2 instances.

```ruby
SparkleFormation.new('website') do

  set!('AWSTemplateFormatVersion', '2010-09-09')

  description 'Supercool Website'

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

  parameters.web_nodes do
    type 'Number'
    description 'Number of web nodes for ASG.'
    default 2
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

This template is 74 lines long (with generous spacing for
readability). The [json template this
renders](examples/template_json/website.json) is 88 lines, without
spacing). This can be improved, though. SparkleFormation allows you to
create resusable files such that the above template can become :

```ruby
SparkleFormation.new(:website).load(:base).overrides do

  description 'Supercool Website'

  dynamic!(:autoscale, 'website', :nodes => 2)
  dynamic!(:launch_config, 'website', :image_id => 'ami-123456', :instance_type => 'm3.medium')
  dynamic!(:elb, 'website')

end
```

[cloudformation]: http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-guide.html
[heat]:
http://docs.openstack.org/developer/heat/template_guide/index.html

