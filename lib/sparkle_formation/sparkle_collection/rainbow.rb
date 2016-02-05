require 'sparkle_formation'
require 'forwardable'

class SparkleFormation

  class SparkleCollection

    # Contains a layered number of a specific item defined via
    # a Sparkle. Items higher in the spectrum (greater layer index)
    # have higher precedence than those below. This can be used for
    # properly generating the end result based on merging or knockout rules.
    class Rainbow

      # Valid types for a rainbow
      VALID_TYPES = [
        :template,
        :component,
        :dynamic
      ].freeze

      extend Forwardable
      def_delegators :top, *(Smash.public_instance_methods - Object.public_instance_methods)

      # @return [String]
      attr_reader :name
      # @return [Symbol]
      attr_reader :type
      # @return [Array<Hash>]
      attr_reader :spectrum

      # Create a new rainbow
      #
      # @param name [String, Symbol] name of item
      # @param type [String, Symbol] type of item
      # @return [self]
      def initialize(name, type)
        unless(VALID_TYPES.include?(type.to_sym))
          raise ArgumentError.new "Invalid type provdied for Rainbow instance `#{type}`"
        end
        @name = name.to_s
        @type = type.to_sym
        @spectrum = []
      end

      # Add a new layer to the top of the spectrum
      #
      # @param item [Hash]
      # @return [self]
      def add_layer(item)
        unless(item.is_a?(Hash))
          raise TypeError.new "Expecting type `Hash` but received type `#{item.class}`"
        end
        spectrum << item.to_smash
        self
      end

      # Fetch item defined at given layer
      #
      # @param idx [Integer]
      # @return [Hash]
      def layer_at(idx)
        if(idx <= spectrum.size)
          spectrum.at(idx)
        else
          raise KeyError.new "Invalid layer requested for #{type} - #{name} (index: #{idx})"
        end
      end

      # Generates a list of items to be processed in
      # order to achieve the correct result based on
      # expected merging behavior
      #
      # @return [Array<Hash>]
      def monochrome
        Array.new.tap do |result|
          spectrum.each do |item|
            unless(item.get(:args, :layering).to_s == 'merge')
              result.clear
            end
            result << item
          end
        end
      end

      # @return [Hash]
      def top
        spectrum.last || {}
      end
    end

  end
end
