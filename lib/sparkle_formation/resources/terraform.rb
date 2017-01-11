require 'sparkle_formation'

class SparkleFormation

  # Resources helper
  class Resources

    # Terraform specific resources collection
    class Terraform < Resources

      # String to split for resource namespacing
      RESOURCE_TYPE_NAMESPACE_SPLITTER = ['_']

      class << self

        include Bogo::Memoization

        # Load the builtin Terraform resources
        #
        # @return [TrueClass]
        def load!
          memoize(:terraform_resources, :global) do
            load(
              File.join(
                File.dirname(__FILE__),
                'terraform_resources.json'
              )
            )
            # NOTE: Internal resource type used for nesting
            register('module',
              'properties' => [],
              'full_properties' => {}
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
