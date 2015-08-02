## Nested Stacks

SparkleFormation includes a `nest!` method which extends
Cloudformation's nested stack functionality to allow programmatic
generation of child stacks as well as the parent stack. When used
alongside the `sfn` CLI, this enables you to provision an entire
multi-template infrastructure via a single command. 

## Syntax

The `nest!` method takes a template path argument, and an optional name
argument. At its simplest, this will create a nested stack with one
child, the website template whose local path is  `cloudformation/templates/website.rb`.
```ruby
SparkleFormation.new('nested_stack') do
  
  nest!(:templates__website)

end
```
The symbol that represents the template path uses a double underscore
`__` to denote a `/` and dashes `-` are replaced with an underscore
`_`. In the above example, the nested stack resource name will be
`TemplatesWebsite`. You can include an optional name argument which is
appended:
```ruby
SparkleFormation.new('nested_stack') do
  
  nest!(:templates__website, 'my_homepage')

end
```
Now the stack resource name is `TemplatesWebsiteMyHomepage`

## Parameters and Outputs
When building a collection of stacks, there are frequently values from
one child stack that you need to pass to another child stack. For
example, an Auto Scaling Group stack may need one or more Subnet IDs from a
VPC stack, or an ELB name from a standalone ELB stack. With nested
stacks, these can be passed along automatically, using outputs and
parameters.

When a child stack in a collection of nested stacks has an output that matches the
parameter in another child stack, that parameter default is set to the
value of the output. For example, suppose the following ELB stack
outputs and ASG stack parameters:

```ruby
SparkleFormation.new('my_elb').load(:base).overrides do

  resources.elb do                                                     
    type 'AWS::ElasticLoadBalancing::LoadBalancer'
    ...
  end

  outputs(:elb_name) do
    value ref!(:elb)
  end

  outputs(:elb_dns) do
    value attr!(:elb, 'DNSName')
  end 

end
---
SparkleFormation.new('my_asg').load(:base).overrides do

  parameters(:elb_name) do
    type 'String'
    description 'ELB Name'
  end                                                     
  
  resources.autoscale do
    type 'AWS::AutoScaling::AutoScalingGroup'
    properties do
      load_balancer_names [ ref!(:elb_name) ]
    ...
  end

end
```
Including these in a nested stack will allow the Auto Scaling Group
child stack to automatically populate its `:elb_name` parameter with
the value of the `:elb_name` output in the ELB stack.
```ruby
SparkleFormation.new('nested') do
  
  nest!(:templates__my_elb)
  nest!(:templates__my_asg)

end
```
You can also access child stack outputs, and add them to the parent
stack where needed. In the above example, the ELB DNS Name is
available as an output on the ELB stack. To expose this in the parent
stack outputs, use an `attr!` on the stack resource:
```ruby
SparkleFormation.new('nested') do
  
  nest!(:templates__my_elb)
  nest!(:templates__my_asg)

  outputs(:elb_dns)
    value attr!(:templates__my_elb, 'Outputs.ElbDns')
  end
end
```
## Updating Nested Stacks

One of the powerful things about nested stacks, is that updates to one
child stack will trigger updates to other stacks, if necessary. For
example, if Security Group rules in an ASG stack are based on the
instance ports in an ELB stack, an update to the ports in the ELB
stack will trigger an update to the Security Group rules, even if the
ASG template has not changed. 
