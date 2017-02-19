require 'sparkle_formation'

class SparkleFormation

  # Resources helper
  class Resources

    # Azure specific resources collection
    class Azure < Resources

      # Characters to be removed from supplied key on matching
      RESOURCE_TYPE_TR = '/._'
      # String to split for resource namespacing
      RESOURCE_TYPE_NAMESPACE_SPLITTER = ['.', '/']

      class << self

        include Bogo::Memoization

        # Load the builtin AWS resources
        #
        # @return [TrueClass]
        def load!
          memoize(:azure_resources, :global) do
            load(
              File.join(
                File.dirname(__FILE__),
                'azure_resources.json'
              )
            )
            true
          end
        end

        # Auto load data when included
        def included(_klass)
          load!
        end

        # Automatically add api version information and location if
        # required by resource and not provided
        #
        # @param struct [SparkleStruct]
        # @param lookup_key [String]
        # @return [SparkleStruct]
        def resource_customizer(struct, lookup_key)
          info = registry[lookup_key]
          if(info[:required].include?('apiVersion') && struct.api_version.nil?)
            struct.api_version info[:api_version]
          end
          if(info[:required].include?('location') && struct.location.nil?)
            struct.location struct.resource_group!.location
          end
          struct
        end

      end

    end
  end
end
