class SparkleFormation
  class Translation
    class Rackspace < Heat

      MAP = Heat::MAP
      MAP[:resources]['AWS::EC2::Instance'][:name] = 'Rackspace::Cloud::Server'

      def nova_server_finalizer(resource_name, new_resource, old_resource, translated_resources)
        if(old_resource['Metadata'])
          new_resource['Metadata'] = old_resource['Metadata']
          if(new_resource['Metadata'] && new_resource['Metadata']['AWS::CloudFormation::Init'] && config = new_resource['Metadata']['AWS::CloudFormation::Init']['config'])
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

      def nova_server_user_data(value, args={})
        result = super
        args[:new_properties].delete(:user_data_format)
        args[:new_properties].delete(:config_drive)
        result
      end

    end
  end
end
