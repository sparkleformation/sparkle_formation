class SparkleFormation
  class Translation
    # Translation for Rackspace
    class Rackspace < Heat

      # translation override to provide HOT format
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
      end

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
        new_resource['Properties']['port'] = source_listener['LoadBalancerPort']
        new_resource['Properties']['protocol'] = source_listener['Protocol']
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
              check['type'] = 'CONNECT'
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
      DEFAULT_CHUNK_SIZE = 350

      # Build server personality structure
      #
      # @param resource [Hash]
      # @return [Hash] personality hash
      # @todo update chunking to use join!
      def build_personality(resource)
        chunk_size = options.fetch(
          :serialization_chunk_size,
          DEFAULT_CHUNK_SIZE
        ).to_i
        init = resource['Metadata']['AWS::CloudFormation::Init']
        content = MultiJson.dump('AWS::CloudFormation::Init' => init)
        # Break out our content to extract items required during stack
        # execution
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
        new_content = content.dup
        result_set = []
        result.each_with_index do |str, i|
          cut_index = new_content.index(str)
          if(cut_index)
            result_set << new_content.slice!(0, cut_index)
            result_set << objects[i]
            new_content.slice!(0, str.size)
          else
            $stderr.puts "Failed to mach: #{str}"
          end
        end

        result_set << new_content unless new_content.empty?
        leftovers = ''

        parts = {}.tap do |files|
          count = 0
          (content.size.to_f / chunk_size).ceil.times do
            file_content = []
            unless(leftovers.empty?)
              file_content << leftovers
              leftovers = ''
            end
            item = nil
            # @todo need better way to determine length of objects since
            #   function structures can severely bloat actual length
            until(file_content.map(&:to_s).map(&:size).inject(&:+).to_i >= chunk_size || result_set.empty?)
              item = result_set.shift
              case item
              when String
                file_content << item.slice!(0, chunk_size)
              else
                file_content << item
              end
            end
            leftovers = item if item.is_a?(String) && !item.empty?
            unless(file_content.empty?)
              if(file_content.all?{|o|o.is_a?(String)})
                files["/etc/sprkl/#{count}.cfg"] = file_content.join
              else
                file_content.map! do |cont|
                  if(cont.is_a?(Hash))
                    ["\"", cont, "\""]
                  else
                    cont
                  end
                end
                files["/etc/sprkl/#{count}.cfg"] = {
                  "Fn::Base64" => {
                    "Fn::Join" => [
                      "",
                      file_content.flatten
                    ]
                  }
                }
              end
              count += 1
            end
          end
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
