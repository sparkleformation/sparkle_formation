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
        complete_launch_config_lb_setups
        true
      end

      # Finalizer for the neutron load balancer resource. This
      # finalizer may generate new resources if the load balancer has
      # multiple listeners defined (neutron lb implementation defines
      # multiple isolated resources sharing a common virtual IP)
      #
      #
      # @param resource_name [String]
      # @param new_resource [Hash]
      # @param old_resource [Hash]
      # @return [Object]
      def neutron_loadbalancer_finalizer(resource_name, new_resource, old_resource)
        listeners = new_resource['Properties'].delete('listeners') || []
        healthcheck = new_resource['Properties'].delete('health_check')
        subnet = (new_resource['Properties'].delete('subnets') || []).first

        # if health check is provided, create resource and apply to
        # all pools generated
        if(healthcheck)
          healthcheck_name = "#{resource_name}HealthCheck"
          check = {
            healthcheck_name => {
              'Type' => 'OS::Neutron::HealthMonitor',
              'Properties' => {}.tap{ |properties|
                {'Timeout' => 'timeout', 'Interval' => 'delay', 'HealthyThreshold' => 'max_retries'}.each do |aws, hot|
                  if(healthcheck[aws])
                    properties[hot] = healthcheck[aws]
                  end
                end
                type, port, path = healthcheck['Target'].split(/(:|\/.*)/).find_all{|x| x != ':'}
                properties['type'] = type
                if(path)
                  properties['url_path'] = path
                end
              }
            }
          }
          translated['Resources'].merge!(check)
        end

        base_listener = listeners.shift
        base_pool_name = "#{resource_name}Pool"
        base_pool = {
          base_pool_name => {
            'Type' => 'OS::Neutron::Pool',
            'Properties' => {
              'lb_method' => 'ROUND_ROBIN',
              'monitors' => [
                {'get_resource' => healthcheck_name}
              ],
              'protocol' => base_listener['Protocol'],
              'vip' => {
                'protocol_port' => base_listener['LoadBalancerPort']
              },
              'subnet' => subnet
            }
          }
        }
        if(healthcheck)
          base_pool[base_pool_name]['Properties'].merge(
            'monitors' => [
              {'get_resource' => healthcheck_name}
            ]
          )
        end

        translated['Resources'].merge!(base_pool)
        new_resource['Properties']['pool_id'] = {'get_resource' => base_pool_name}
        new_resource['Properties']['protocol_port'] = base_listener['InstancePort']

        listeners.each_with_index do |listener, count|
          pool_name = "#{resource_name}PoolVip#{count}"
          pool = {
            pool_name => {
              'Type' => 'OS::Neutron::Pool',
              'Properties' => {
                'lb_method' => 'ROUND_ROBIN',
                'protocol' => listener['Protocol'],
                'subnet' => subnet,
                'vip' => {
                  'protocol_port' => listener['LoadBalancerPort']
                }
              }
            }
          }
          if(healthcheck)
            pool[pool_name]['Properties'].merge(
              'monitors' => [
                {'get_resource' => healthcheck_name}
              ]
            )
          end

          lb_name = "#{resource_name}Vip#{count}"
          lb = {lb_name => MultiJson.load(MultiJson.dump(new_resource))}
          lb[lb_name]['Properties']['pool_id'] = {'get_resource' => pool_name}
          lb[lb_name]['Properties']['protocol_port'] = listener['InstancePort']
          translated['Resources'].merge!(pool)
          translated['Resources'].merge!(lb)
        end
      end

      # Update any launch configuration which define load balancers to
      # ensure they are attached to the correct resources when
      # multiple listeners (ports) have been defined resulting in
      # multiple isolated LB resources
      def complete_launch_config_lb_setups
        translated['resources'].find_all do |resource_name, resource|
          resource['type'] == 'OS::Heat::AutoScalingGroup'
        end.each do |name, value|
          if(lbs = value['properties'].delete('load_balancers'))
            lbs.each do |lb_ref|
              lb_name = resource_name(lb_ref)
              lb_resource = translated['resources'][lb_name]
              vip_resources = translated['resources'].find_all do |k, v|
                k.match(/#{lb_name}Vip\d+/) && v['type'] == 'OS::Neutron::LoadBalancer'
              end
              value['properties']['load_balancers'] = vip_resources.map do |vip_name|
                {'get_resource' => vip_name}
              end
            end
          end
        end
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

      # Finalizer for the neutron subnet resource. Creates a stub
      # network to attach subnet if availability zones are defined
      # (aws classic)
      #
      # @param resource_name [String]
      # @param new_resource [Hash]
      # @param old_resource [Hash]
      # @return [TrueClass]
      def neutron_subnet_finalizer(resource_name, new_resource, old_resource)
        azs = new_resource['Properties'].delete('availability_zone')
        if(azs)
          network_name = "NetworkFor#{resource_name}"
          translated['Resources'][network_name] = {
            'type' => 'OS::Neutron::Network'
          }
          new_resource['Properties']['network'] = {'get_resource' => network_name}
        end
        true
      end

      # Finalizer for the neutron net resource. Scrub properties.
      #
      # @param resource_name [String]
      # @param new_resource [Hash]
      # @param old_resource [Hash]
      # @return [TrueClass]
      def neutron_net_finalizer(resource_name, new_resource, old_resource)
        new_resource['Properties'].clear
        true
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
          'AWS::AutoScaling::LaunchConfiguration' => :delete,
          'AWS::ElasticLoadBalancing::LoadBalancer' => {
            :name => 'OS::Neutron::LoadBalancer',
            :finalizer => :neutron_loadbalancer_finalizer,
            :properties => {
              'Instances' => 'members',
              'Listeners' => 'listeners',
              'HealthCheck' => 'health_check',
              'Subnets' => 'subnets'
            }
          },
          'AWS::EC2::VPC' => {
            :name => 'OS::Neutron::Net',
            :finalizer => :neutron_net_finalizer,
            :properties => {
              'CidrBlock' => 'cidr'
            }
          },
          'AWS::EC2::Subnet' => {
            :name => 'OS::Neutron::Subnet',
            :finalizer => :neutron_subnet_finalizer,
            :properties => {
              'CidrBlock' => 'cidr',
              'VpcId' => 'network',
              'AvailabilityZone' => 'availability_zone'
            }
          }
        }
      }

      REF_MAPPING = {
        'AWS::StackName' => 'OS::stack_name',
        'AWS::StackId' => 'OS::stack_id',
        'AWS::Region' => 'OS::stack_id' # @todo i see it set in source, but no function. wat
      }

      FN_MAPPING = {
        'Fn::GetAtt' => 'get_attr',
        'Fn::Join' => 'list_join'
      }

    end
  end
end
