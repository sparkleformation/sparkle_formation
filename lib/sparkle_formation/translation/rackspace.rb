class SparkleFormation
  class Translation
    class Rackspace < Heat

      MAP = Heat::MAP
      MAP[:resources]['AWS::EC2::Instance'][:name] = 'Rackspace::Cloud::Server'
      MAP[:resources]['AWS::AutoScaling::AutoScalingGroup'].tap do |asg|
        asg[:name] = 'Rackspace::AutoScale::Group'
        asg[:finalizer] = :rackspace_asg_finalizer
        asg[:properties].tap do |props|
          props['MaxSize'] = 'maxEntities'
          props['MinSize'] = 'minEntities'
        end
      end

      def nova_server_finalizer(resource_name, new_resource, old_resource)
        if(old_resource['Metadata'])
          new_resource['Metadata'] = old_resource['Metadata']
          proceed = new_resource['Metadata'] &&
            new_resource['Metadata']['AWS::CloudFormation::Init'] &&
            config = new_resource['Metadata']['AWS::CloudFormation::Init']['config']
          if(proceed)
            # NOTE: This is a stupid hack since HOT gives the URL to
            # wget directly and if special characters exist, it fails
            if(files = config['files'])
              files.each do |key, args|
                if(args['source'])
                  args['source'].replace("\"#{args['source']}\"")
                end
              end
            end
          end
        end
      end

      def rackspace_asg_finalizer(resource_name, new_resource, old_resource)
        new_resource['Properties'] = {
          'groupConfiguration' => new_resource['Properties']
        }
      end

      def nova_server_user_data(value, args={})
        result = super
        args[:new_properties].delete(:user_data_format)
        args[:new_properties].delete(:config_drive)
        result
      end

      def autoscaling_group_resource(value, args={})
        args[:launchConfiguration] = {}.tap do |config|
          launch_config_name = decode_resource_name(config['LaunchConfigurationName'])
          config_resource = original['Resource'][launch_config_name]
          config_resource['Type'] = 'AWS::EC2::Instance'
          translated = resource_translation(launch_config_name, config_resource)
        end
      end

    end
  end
end
