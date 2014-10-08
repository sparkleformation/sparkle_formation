class SparkleFormation
  class Translation
    # Translation for Heat (HOT)
    class Heat < Translation

      # Translate stack definition
      #
      # @return [TrueClass]
      # @note this is an override to return in proper HOT format
      # @todo still needs replacements of functions and pseudo-params
      def translate!
        super
        cache = MultiJson.load(MultiJson.dump(translated))
        # top level
        cache.each do |k,v|
          translated.delete(k)
          translated[snake(k).to_s] = v
        end
        # params
        cache.fetch('Parameters', {}).each do |k,v|
          translated['parameters'][k] = Hash[
            v.map do |key, value|
              if(key == 'Type')
                [snake(key).to_s, value.downcase]
              elsif(key == 'AllowedValues')
                # @todo fix this up to properly build constraints
                ['constraints', [{'allowed_values' => value}]]
              else
                [snake(key).to_s, value]
              end
            end
          ]
        end
        # resources
        cache.fetch('Resources', {}).each do |r_name, r_value|
          translated['resources'][r_name] = Hash[
            r_value.map do |k,v|
              [snake(k).to_s, v]
            end
          ]
        end
        # outputs
        cache.fetch('Outputs', {}).each do |o_name, o_value|
          translated['outputs'][o_name] = Hash[
            o_value.map do |k,v|
              [snake(k).to_s, v]
            end
          ]
        end
        translated.delete('awstemplate_format_version')
        translated['heat_template_version'] = '2013-05-23'
        # no HOT support for mappings, so remove and clean pseudo
        # params in refs
        if(translated['resources'])
          translated['resources'] = dereference_processor(translated['resources'], ['Fn::FindInMap', 'Ref'])
          translated['resources'] = rename_processor(translated['resources'])
        end
        if(translated['outputs'])
          translated['outputs'] = dereference_processor(translated['outputs'], ['Fn::FindInMap', 'Ref'])
          translated['outputs'] = rename_processor(translated['outputs'])
        end
        translated.delete('mappings')
        true
      end

      # Custom mapping for block device
      #
      # @param value [Object] original property value
      # @param args [Hash]
      # @option args [Hash] :new_resource
      # @option args [Hash] :new_properties
      # @option args [Hash] :original_resource
      # @return [Array<String, Object>] name and new value
      # @todo implement
      def nova_server_block_device_mapping(value, args={})
        ['block_device_mapping', value]
      end

      # Custom mapping for server user data
      #
      # @param value [Object] original property value
      # @param args [Hash]
      # @option args [Hash] :new_resource
      # @option args [Hash] :new_properties
      # @option args [Hash] :original_resource
      # @return [Array<String, Object>] name and new value
      def nova_server_user_data(value, args={})
        args[:new_properties][:user_data_format] = 'RAW'
        args[:new_properties][:config_drive] = 'true'
        [:user_data, Hash[value.values.first]]
      end

      # Finalizer for the nova server resource. Fixes bug with remotes
      # in metadata
      #
      # @param resource_name [String]
      # @param new_resource [Hash]
      # @param old_resource [Hash]
      # @return [Object]
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
                  if(args['source'].is_a?(String))
                    args['source'].replace("\"#{args['source']}\"")
                  else
                    args['source'] = {
                      'Fn::Join' => [
                        "", [
                          "\"",
                          args['source'],
                          "\""
                        ]
                      ]
                    }
                  end
                end
              end
            end
          end
        end
      end

      # Finalizer applied to all new resources
      #
      # @param resource_name [String]
      # @param new_resource [Hash]
      # @param old_resource [Hash]
      # @return [TrueClass]
      def resource_finalizer(resource_name, new_resource, old_resource)
        %w(DependsOn Metadata).each do |key|
          if(old_resource[key] && !new_resource[key])
            new_resource[key] = old_resource[key]
          end
        end
        true
      end

      # Custom mapping for ASG launch configuration
      #
      # @param value [Object] original property value
      # @param args [Hash]
      # @option args [Hash] :new_resource
      # @option args [Hash] :new_properties
      # @option args [Hash] :original_resource
      # @return [Array<String, Object>] name and new value
      # @todo implement
      def autoscaling_group_launchconfig(value, args={})
        ['resource', value]
      end

      # Default keys to snake cased format (underscore)
      #
      # @param key [String, Symbol]
      # @return [String]
      def default_key_format(key)
        snake(key)
      end

      # Heat translation mapping
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

      REF_MAPPING = {
        'AWS::StackName' => 'OS::stack_name',
        'AWS::StackId' => 'OS::stack_id',
        'AWS::Region' => 'OS::stack_id' # @todo i see it set in source, but no function. wat
      }

      FN_MAPPING = {
        'Fn::GetAtt' => 'get_attr',
        'Fn::Join' => 'list_join'  # @todo why is this not working?
      }

    end
  end
end
