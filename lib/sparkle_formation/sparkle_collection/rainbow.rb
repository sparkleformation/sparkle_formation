require 'sparkle_formation'


class SparkleFormation

  class SparkleCollection

    # Contains a layered number of a specific item defined via
    # a Sparkle. Items higher in the spectrum (greater layer index)
    # have higher precedence than those below. This can be used for
    # properly generating the end result based on merging or knockout rules.
    class Rainbow

      # @return [String]
      attr_reader :name
      # @return [String]
      attr_reader :type
      # @return [Array]
      attr_reader :spectrum

      # Create a new rainbow
      #
      # @param name [String, Symbol] name of item
      # @param type [String, Symbol] type of item
      # @return [self]
      def initialize(name, type)
        @name = name
        @type = type
        @spectrum = []
      end

      # Add a new layer to the top of the spectrum
      #
      # @param item [Hash]
      # @return [self]
      def add_layer(item)
        spectrum << item
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

    end

  end
end
