class SparkleFormation
  class Translation
    # Translation for Rackspace
    class Rackspace < Heat

      # Custom mapping for network interfaces
      #
      # @param value [Object] original property value
      # @param args [Hash]
      # @option args [Hash] :new_resource
      # @option args [Hash] :new_properties
      # @option args [Hash] :original_resource
      # @return [Array<String, Object>] name and new value
      def rackspace_server_network_interfaces_mapping(value, args={})
        networks = [value].flatten.map do |item|
          {:uuid => item['NetworkInterfaceId']}
        end
        ['networks', networks]
      end

      # Translate override to provide finalization of resources
      #
      # @return [TrueClass]
      def translate!
        super
        complete_launch_config_lb_setups
        true
      end

      # Update any launch configuration which define load balancers to
      # ensure they are attached to the correct resources when
      # multiple listeners (ports) have been defined resulting in
      # multiple isolated LB resources
      def complete_launch_config_lb_setups
        translated['resources'].find_all do |resource_name, resource|
          resource['type'] == 'Rackspace::AutoScale::Group'
        end.each do |name, value|
          if(lbs = value['properties'].delete('load_balancers'))
            lbs.each do |lb_ref|
              lb_name = resource_name(lb_ref)
              lb_resource = translated['resources'][lb_name]
              vip_resources = translated['resources'].find_all do |k, v|
                k.match(/#{lb_name}Vip\d+/) && v['type'] == 'Rackspace::Cloud::LoadBalancer'
              end
              value['properties']['launchConfiguration']['args'].tap do |lnch_config|
                lnch_config['loadBalancers'] = [
                  'loadBalancerId' => lb_ref,
                  'port' => lb_resource['cache_instance_port']
                ]
                vip_resources.each do |vip_name, vip_resource|
                  lnch_config['loadBalancers'].push(
                    'loadBalancerId' => {
                      'Ref' => vip_name
                    },
                    'port' => vip_resource['cache_instance_port']
                  )
                end
              end
            end
          end
        end
        translated['resources'].find_all do |resource_name, resource|
          resource['type'] == 'Rackspace::Cloud::LoadBalancer' &&
            !resource['properties']['nodes'].empty?
        end.each do |resource_name, resource|
          resource['properties']['nodes'].map! do |node_ref|
            {
              'addresses' => [
                {
                  'get_attr' => [
                    resource_name(node_ref),
                    'accessIPv4'
                  ]
                }
              ],
              'port' => resource['cache_instance_port'],
              'condition' => 'ENABLED'
            }
          end
        end
        translated['resources'].values.find_all do |resource|
          resource['type'] == 'Rackspace::Cloud::LoadBalancer'
        end.each do |resource|
          resource.delete('cache_instance_port')
        end
        true
      end

      # Rackspace translation mapping
      MAP = Heat::MAP
      MAP[:resources]['AWS::EC2::Instance'][:name] = 'Rackspace::Cloud::Server'
      MAP[:resources]['AWS::EC2::Instance'][:properties]['NetworkInterfaces'] = :rackspace_server_network_interfaces_mapping
      MAP[:resources]['AWS::AutoScaling::AutoScalingGroup'].tap do |asg|
        asg[:name] = 'Rackspace::AutoScale::Group'
        asg[:finalizer] = :rackspace_asg_finalizer
        asg[:properties].tap do |props|
          props['MaxSize'] = 'maxEntities'
          props['MinSize'] = 'minEntities'
          props['LoadBalancerNames'] = 'load_balancers'
          props['LaunchConfigurationName'] = :delete
        end
      end
      MAP[:resources]['AWS::EC2::Subnet'] = {}.tap do |subnet|
        subnet[:name] = 'Rackspace::Cloud::Network'
        subnet[:finalizer] = :rackspace_subnet_finalizer
        subnet[:properties] = {
          'CidrBlock' => 'cidr'
        }
      end
      MAP[:resources]['AWS::ElasticLoadBalancing::LoadBalancer'] = {
        :name => 'Rackspace::Cloud::LoadBalancer',
        :finalizer => :rackspace_lb_finalizer,
        :properties => {
          'LoadBalancerName' => 'name',
          'Instances' => 'nodes',
          'Listeners' => 'listeners',
          'HealthCheck' => 'health_check'
        }
      }

      # Attribute map for autoscaling group server properties
      RACKSPACE_ASG_SRV_MAP = {
        'imageRef' => 'image',
        'flavorRef' => 'flavor',
        'networks' => 'networks'
      }

      # Finalizer for the rackspace load balancer resource. This
      # finalizer may generate new resources if the load balancer has
      # multiple listeners defined (rackspace implementation defines
      # multiple isolated resources sharing a common virtual IP)
      #
      #
      # @param resource_name [String]
      # @param new_resource [Hash]
      # @param old_resource [Hash]
      # @return [Object]
      #
      # @todo make virtualIp creation allow servnet/multiple?
      def rackspace_lb_finalizer(resource_name, new_resource, old_resource)
        listeners = new_resource['Properties'].delete('listeners') || []
        source_listener = listeners.shift
        if(source_listener)
          new_resource['Properties']['port'] = source_listener['LoadBalancerPort']
          new_resource['Properties']['protocol'] = source_listener['Protocol']
          new_resource['cache_instance_port'] = source_listener['InstancePort']
        end
        new_resource['Properties']['virtualIps'] = ['type' => 'PUBLIC', 'ipVersion' => 'IPV4']
        new_resource['Properties']['nodes'] = [] unless new_resource['Properties']['nodes']
        health_check = new_resource['Properties'].delete('health_check')
        health_check = nil
        if(health_check)
          new_resource['Properties']['healthCheck'] = {}.tap do |check|
            check['timeout'] = health_check['Timeout']
            check['attemptsBeforeDeactivation'] = health_check['UnhealthyThreshold']
            check['delay'] = health_check['Interval']
            check_target = dereference_processor(health_check['Target'])
            check_args = check_target.split(':')
            check_type = check_args.shift
            if(check_type == 'HTTP' || check_type == 'HTTPS')
              check['type'] = check_type
              check['path'] = check_args.last
            else
              check['type'] = 'TCP_STREAM'
            end
          end
        end
        unless(listeners.empty?)
          listeners.each_with_index do |listener, idx|
            port = listener['LoadBalancerPort']
            proto = listener['Protocol']
            vip_name = "#{resource_name}Vip#{idx}"
            vip_resource = MultiJson.load(MultiJson.dump(new_resource))
            vip_resource['Properties']['name'] = vip_name
            vip_resource['Properties']['protocol'] = proto
            vip_resource['Properties']['port'] = port
            vip_resource['Properties']['virtualIps'] = [
              'id' => {
                'get_attr' => [
                  resource_name,
                  'virtualIps',
                  0,
                  'id'
                ]
              }
            ]
            vip_resource['cache_instance_port'] = listener['InstancePort']
            translated['Resources'][vip_name] = vip_resource
          end
        end
      end

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
          if(lbs = new_resource['Properties'].delete('load_balancers'))
            properties['load_balancers'] = lbs
          end
          properties['groupConfiguration'] = new_resource['Properties'].merge('name' => resource_name)
          properties['launchConfiguration'] = {}.tap do |config|
            launch_config_name = resource_name(old_resource['Properties']['LaunchConfigurationName'])
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
      DEFAULT_CHUNK_SIZE = 950
      # Max number of files to create (by default this is n-1 since we
      # require one of the files for injecting into cloud init)
      DEFAULT_NUMBER_OF_CHUNKS = 4

      # Build server personality structure
      #
      # @param resource [Hash]
      # @return [Hash] personality hash
      # @todo update chunking to use join!
      def build_personality(resource)
        max_chunk_size = options.fetch(
          :serialization_chunk_size,
          DEFAULT_CHUNK_SIZE
        ).to_i
        num_personality_files = options.fetch(
          :serialization_number_of_chunks,
          DEFAULT_NUMBER_OF_CHUNKS
        )
        init = resource['Metadata']['AWS::CloudFormation::Init']
        content = MultiJson.dump('AWS::CloudFormation::Init' => init)
        # Break out our content to extract items required during stack
        # execution (template functions, refs, and the like)
        raw_result = content.scan(/(?=(\{\s*"(Ref|Fn::[A-Za-z]+)"((?:[^{}]++|\{\g<3>\})++)\}))/).map(&:first)
        result = [].tap do |filtered|
          until(raw_result.empty?)
            item = raw_result.shift
            filtered.push(item)
            check_item = nil
            until(raw_result.empty? || !item.include?(check_item = raw_result.shift))
              check_item = nil
            end
            if(check_item && !item.include?(check_item))
              raw_result.unshift(check_item)
            end
          end
        end

        # Cycle through the result and format entries where required
        objects = result.map do |string|
          # Format for load and make newlines happy
          string = string.strip.split(
            /\n(?=(?:[^"]*"[^"]*")*[^"]*\Z)/
          ).join.gsub('\n', '\\\\\n')
          # Check for nested join and fix quotes
          if(string.match(/^[^A-Za-z]+Fn::Join/))
            string.gsub!("\\\"", "\\\\\\\\\\\"") # HAHAHA ohai thar hairy yak!
          end
          MultiJson.load(string)
        end

        # Find and replace any found objects
        new_content = content.dup
        result_set = []
        result.each_with_index do |str, i|
          cut_index = new_content.index(str)
          if(cut_index)
            result_set << new_content.slice!(0, cut_index)
            result_set << objects[i]
            new_content.slice!(0, str.size)
          else
            logger.warn "Failed to match: #{str}"
          end
        end

        # The result set is the final formatted content that
        # now needs to be split and assigned to files
        result_set << new_content unless new_content.empty?
        leftovers = ''

        # Determine optimal chuck sizing and check if viable
        calculated_chunk_size = (content.size.to_f / num_personality_files).ceil
        if(calculated_chunk_size > max_chunk_size)
          logger.error 'ERROR: Unable to split personality files within defined bounds!'
          logger.error "  Maximum chunk size: #{max_chunk_size.inspect}"
          logger.error "  Maximum personality files: #{num_personality_files.inspect}"
          logger.error "  Calculated chunk size: #{calculated_chunk_size}"
          logger.error "-> Content: #{content.inspect}"
          raise ArgumentError.new 'Unable to split personality files within defined bounds'
        end

        # Do the split!
        chunk_size = calculated_chunk_size
        file_index = 0
        parts = {}.tap do |files|
          until(leftovers.empty? && result_set.empty?)
            file_content = []
            unless(leftovers.empty?)
              result_set.unshift leftovers
              leftovers = ''
            end
            item = nil
            # @todo need better way to determine length of objects since
            #   function structures can severely bloat actual length
            until((cur_len = file_content.map(&:to_s).map(&:size).inject(&:+).to_i) >= chunk_size || result_set.empty?)
              to_cut = chunk_size - cur_len
              item = result_set.shift
              case item
              when String
                file_content << item.slice!(0, to_cut)
              else
                file_content << item
              end
            end
            leftovers = item if item.is_a?(String) && !item.empty?
            unless(file_content.empty?)
              if(file_content.all?{|o|o.is_a?(String)})
                files["/etc/sprkl/#{file_index}.cfg"] = file_content.join
              else
                file_content.map! do |cont|
                  if(cont.is_a?(Hash))
                    ["\"", cont, "\""]
                  else
                    cont
                  end
                end
                files["/etc/sprkl/#{file_index}.cfg"] = {
                  "Fn::Join" => [
                    "",
                    file_content.flatten
                  ]
                }
              end
            end
            file_index += 1
          end
        end
        if(parts.size > num_personality_files)
          logger.warn "Failed to split files within defined range! (Max files: #{num_personality_files} Actual files: #{parts.size})"
          logger.warn 'Appending to last file and hoping for the best!'
          parts = parts.to_a
          extras = parts.slice!(4, parts.length)
          tail_name, tail_contents = parts.pop
          parts = Hash[parts]
          parts[tail_name] = {
            "Fn::Join" => [
              '',
              *extras.map(&:last).unshift(tail_contents)
            ]
          }
        end
        parts['/etc/cloud/cloud.cfg.d/99_s.cfg'] = RUNNER
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
