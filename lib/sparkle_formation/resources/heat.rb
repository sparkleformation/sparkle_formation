require 'sparkle_formation'

class SparkleFormation

  # Resources helper
  class Resources

    # Heat specific resources collection
    class Heat < Resources
      class << self
        include Bogo::Memoization

        # Load the builtin AWS resources
        #
        # @return [TrueClass]
        def load!
          memoize(:heat_resources, :global) do
            load(
              File.join(
                File.dirname(__FILE__),
                'heat_resources.json'
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
