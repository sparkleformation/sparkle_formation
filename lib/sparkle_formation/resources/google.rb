require 'sparkle_formation'

class SparkleFormation

  # Resources helper
  class Resources

    # Google specific resources collection
    class Google < Resources

      # Characters to be removed from supplied key on matching
      RESOURCE_TYPE_TR = '._'
      # String to split for resource namespacing
      RESOURCE_TYPE_NAMESPACE_SPLITTER = ['.']

      class << self
        include Bogo::Memoization

        # Load the builtin AWS resources
        #
        # @return [TrueClass]
        def load!
          memoize(:google_resources, :global) do
            load(
              File.join(
                File.dirname(__FILE__),
                'google_resources.json'
              )
            )
            # NOTE: Internal resource type used for nesting
            registry['sparkleformation.stack'] = {
              'properties' => [],
              'full_properties' => {},
            }
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
