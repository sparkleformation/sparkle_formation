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
          props['LaunchConfigurationName'] = :delete
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
        new_resource['Properties'] = {}.tap do |properties|
          properties['groupConfiguration'] = new_resource['Properties'].merge('name' => resource_name)

          properties['launchConfiguration'] = {}.tap do |config|
            launch_config_name = decode_resource_name(old_resource['Properties']['LaunchConfigurationName'])
            config_resource = original['Resources'][launch_config_name]
            config_resource['Type'] = 'AWS::EC2::Instance'
            translated = resource_translation(launch_config_name, config_resource)
            config['args'] = {}.tap do |lnch_args|
              lnch_args['server'] = {}.tap do |srv|
                # TODO: ADD HASH MAPPING
                srv['name'] = launch_config_name
                srv['imageRef'] = translated['Properties']['image']
                srv['flavorRef'] = translated['Properties']['flavor']
                srv['personality'] = build_personality(config_resource)
              end
            end
            config['type'] = 'launch_server'
          end
        end
      end

      def nova_server_user_data(value, args={})
        result = super
        args[:new_properties].delete(:user_data_format)
        args[:new_properties].delete(:config_drive)
        result
      end

      def dereference(obj)
        result = obj
        if(obj.is_a?(Hash))
          name = obj['Ref']
          if(name)
            p_val = parameters[name.to_s]
            if(p_val)
              result = p_val
            end
          end
        end
        result
      end

      def dereference_processor(obj)
        obj = dereference(obj)
        case obj
        when Array
          obj = obj.map{|v| dereference_processor(v)}
        when Hash
          new_hash = {}
          obj.each do |k,v|
            new_hash[k] = dereference_processor(v)
          end
          obj = apply_function(new_hash)
        end
        obj
      end

      def apply_function(hash)
        if(hash.size == 1 && hash.keys.first.start_with?('Fn'))
          k,v = hash.first
          case k
          when 'Fn::Join'
            v.last.join(v.first)
          else
            hash
          end
        else
          hash
        end
      end

      CHUNK_SIZE = 400
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
