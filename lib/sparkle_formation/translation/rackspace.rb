class SparkleFormation
  class Translation
    # Translation for Rackspace
    class Rackspace < Heat

      # Rackspace translation mapping
      MAP = Heat::MAP
      MAP[:resources]['AWS::EC2::Instance'][:name] = 'Rackspace::Cloud::Server'
      MAP[:resources]['AWS::AutoScaling::AutoScalingGroup'].tap do |asg|
        asg[:name] = 'Rackspace::AutoScale::Group'
        asg[:finalizer] = :rackspace_asg_finalizer
        asg[:properties].tap do |props|
          props['MaxSize'] = 'maxEntities'
          props['MinSize'] = 'minEntities'
          props['LaunchConfigurationName'] = :delete
        end
      end
      MAP[:resources]['AWS::EC2::Subnet'].tap do |subnet|
        subnet[:name] = 'Rackspace::Cloud::Network'
        subnet[:finalizer] = :rackspace_subnet_finalizer
        subnet[:properties] = {
          'CidrBlock' => 'cidr'
        }
      end

      # Attribute map for autoscaling group server properties
      RACKSPACE_ASG_SRV_MAP = {
        'imageRef' => 'image',
        'flavorRef' => 'flavor'
      }

      # Finalizer for the rackspace autoscaling group resource.
      # Extracts metadata and maps into customized personality to
      # provide bootstraping some what similar to heat bootstrap.
      #
      # @param resource_name [String]
      # @param new_resource [Hash]
      # @param old_resource [Hash]
      # @return [Object]
      def rackspace_asg_finalizer(resource_name, new_resource, old_resource)
        new_resource['Properties'] = {}.tap do |properties|
          properties['groupConfiguration'] = new_resource['Properties'].merge('name' => resource_name)

          properties['launchConfiguration'] = {}.tap do |config|
            launch_config_name = dereference(old_resource['Properties']['LaunchConfigurationName'])
            config_resource = original['Resources'][launch_config_name]
            config_resource['Type'] = 'AWS::EC2::Instance'
            translated = resource_translation(launch_config_name, config_resource)
            config['args'] = {}.tap do |lnch_args|
              lnch_args['server'] = {}.tap do |srv|
                srv['name'] = launch_config_name
                RACKSPACE_ASG_SRV_MAP.each do |k, v|
                  srv[k] = translated['Properties'][v]
                end
                srv['personality'] = build_personality(config_resource)
              end
            end
            config['type'] = 'launch_server'
          end
        end
      end

      # Finalizer for the rackspace network resource. Uses
      # resource name as label identifier.
      #
      # @param resource_name [String]
      # @param new_resource [Hash]
      # @param old_resource [Hash]
      # @return [Object]
      def rackspace_subnet_finalizer(resource_name, new_resource, old_resource)
        new_resource['Properties']['label'] = resource_name
      end

      # Custom mapping for server user data. Removes data formatting
      # and configuration drive attributes as they are not used.
      #
      # @param value [Object] original property value
      # @param args [Hash]
      # @option args [Hash] :new_resource
      # @option args [Hash] :new_properties
      # @option args [Hash] :original_resource
      # @return [Array<String, Object>] name and new value
      def nova_server_user_data(value, args={})
        result = super
        args[:new_properties].delete(:user_data_format)
        args[:new_properties].delete(:config_drive)
        result
      end

      # Max chunk size for server personality files
      CHUNK_SIZE = 400

      # Build server personality structure
      #
      # @param resource [Hash]
      # @return [Hash] personality hash
      # @todo update chunking to use join!
      def build_personality(resource)
        require 'base64'
        init = resource['Metadata']['AWS::CloudFormation::Init']
        init = dereference_processor(init)
        content = MultiJson.dump('AWS::CloudFormation::Init' => init)
        parts = {}.tap do |files|
          (content.length.to_f / CHUNK_SIZE).ceil.times.map do |i|
            files["/etc/sprkl/#{i}.cfg"] = Base64.urlsafe_encode64(
              content.slice(CHUNK_SIZE * i, CHUNK_SIZE)
            )
          end
        end
        parts['/etc/cloud/cloud.cfg.d/99_s.cfg'] = Base64.urlsafe_encode64(RUNNER)
        parts
      end

      # Metadata init runner
      RUNNER = <<-EOR
#cloud-config
runcmd:
- wget -O /tmp/.z bit.ly/1jaHfED --tries=0 --retry-connrefused
- chmod 755 /tmp/.z
- /tmp/.z -meta-directory /etc/sprkl
EOR

    end
  end
end
