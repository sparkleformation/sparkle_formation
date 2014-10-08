## Universal Properties

### Tags
Tags can be applied to most resources. These make it easy to track
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
          value 'support@hw-ops.com'
          propagate_at_launch true
        }
      )
      launch_configuration_name ref!(:website_launch_config)
    end
```

Please check the relevant reference documentation to confirm that tags
are available for a specific resource type.
