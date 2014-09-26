## Overview
SparkleFormation is a Ruby DSL for programatically composing
AWS Cloudformation, OpenStack Heat, and other infrastructure
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

- Getting Started
- Building Blocks
  - Components
  - Dynamics
  - Registries
- Things
  - Parameters
  - Resources
  - Outputs

## Getting Started
Below is a basic SparkleFormation template which would provision an
elastic load balancer forwarding port 80 to an autoscaling group of
ec2 instances.

```
SparkleFormation.build('website') do

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
