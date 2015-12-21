require 'sparkle_formation'

class SparkleFormation

  # Resources helper
  class Resources

    # AWS specific resources collection
    class Aws < Resources

      class << self

        include Bogo::Memoization

        # Load the builtin AWS resources
        #
        # @return [TrueClass]
        def load!
          memoize(:aws_resources, :global) do
            load(
              File.join(
                File.dirname(__FILE__),
                'aws_resources.json'
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
