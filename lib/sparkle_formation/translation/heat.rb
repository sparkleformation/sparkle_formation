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

      def nova_server_finalizer(*_)
        true
      end

      def resource_finalizer(resource_name, new_resource, old_resource)
        %w(DependsOn Metadata).each do |key|
          if(old_resource[key] && !new_resource[key])
            new_resource[key] = old_resource[key]
          end
        end
        true
      end

      # TODO: implement
      def autoscaling_group_launchconfig(value, args={})
        ['resource', value]
      end

      def default_key_format(key)
        snake(key)
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
              'LaunchConfigurationName' => :autoscaling_group_launchconfig
            }
          },
          'AWS::AutoScaling::LaunchConfiguration' => :delete
        }
      }

    end
  end
end
