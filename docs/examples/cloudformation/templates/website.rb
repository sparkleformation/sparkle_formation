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
