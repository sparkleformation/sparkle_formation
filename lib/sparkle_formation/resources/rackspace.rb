require 'sparkle_formation'

class SparkleFormation

  # Resources helper
  class Resources

    # Rackspace specific resources collection
    class Rackspace < Resources
      class << self
        include Bogo::Memoization

        # Load the builtin AWS resources
        #
        # @return [TrueClass]
        def load!
          memoize(:rackspace_resources, :global) do
            load(
              File.join(
                File.dirname(__FILE__),
                'rackspace_resources.json'
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
