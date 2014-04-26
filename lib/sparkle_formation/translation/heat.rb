class SparkleFormation
  class Translation
    class Heat < Translation

      # TODO: implement
      def nova_server_block_device_mapping(value, args={})
        ['block_device_mapping', value]
      end

      def nova_server_user_data(value, args={})
        args[:new_properties][:user_data_format] = 'RAW'
        args[:new_properties][:config_drive] = 'true'
        [:user_data, Hash[value.values.first]]
      end

      def nova_server_finalizer(resource_name, new_resource, old_resource)
        if(old_resource['Metadata'] && old_resource)
          new_resource['Properties'][:user_data] = cloud_init(resource_name, 'OS')
          new_resource['Properties'][:user_data_format] = 'RAW'
          new_resource['Properties'][:config_drive] = 'true'
        end
        new_resource['Metadata'] = old_resource['Metadata']
      end

      # TODO: implement
      def autoscaling_group_resource(value, args={})
        ['resource', value]
      end

      MAP = {
        :resources => {
          'AWS::EC2::Instance' => {
            :name => 'OS::Nova::Server',
            :finalizer => :nova_server_finalizer,
            :properties => {
              'AvailabilityZone' => 'availability_zone',
              'BlockDeviceMappings' => :nova_server_block_device_mapping,
              'ImageId' => 'image',
              'InstanceType' => 'flavor',
              'KeyName' => 'key_name',
              'NetworkInterfaces' => 'networks',
              'SecurityGroups' => 'security_groups',
              'SecurityGroupIds' => 'security_groups',
              'Tags' => 'metadata',
              'UserData' => :nova_server_user_data
            }
          },
          'AWS::AutoScaling::AutoScalingGroup' => {
            :name => 'OS::Heat::AutoScalingGroup',
            :properties => {
              'Cooldown' => 'cooldown',
              'DesiredCapacity' => 'desired_capacity',
              'MaxSize' => 'max_size',
              'MinSize' => 'min_size',
              'LaunchConfigurationName' => :autoscaling_group_resource
            }
          }
        }
      }
    end
  end
end
