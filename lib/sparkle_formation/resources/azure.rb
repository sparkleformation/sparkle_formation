require 'sparkle_formation'

class SparkleFormation

  # Resources helper
  class Resources

    # Azure specific resources collection
    class Azure < Resources

      # Characters to be removed from supplied key on matching
      RESOURCE_TYPE_TR = '.'
      # String to split for resource namespacing
      RESOURCE_TYPE_NAMESPACE_SPLITTER = '/'

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

      end

    end
  end
end
