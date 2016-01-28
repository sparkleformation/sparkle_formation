require 'sparkle_formation'

class SparkleFormation

  # SparkleFormation specific errors
  class Error < StandardError

    # File not found error
    class NotFound < KeyError
      attr_reader :name

      def initialize(*args)
        opts = args.detect{|o| o.is_a?(Hash)}
        args.delete(opts) if opts
        super(args)
        @name = opts[:name] if opts
      end

      # @return [String] customized message including name
      def to_s
        if(name)
          "Failed to locate item named: `#{name}`"
        else
          'Failed to locate item'
        end
      end

      # Pack related items
      class Dynamic < NotFound; end
      class Component < NotFound; end
      class Registry < NotFound; end
      class Template < NotFound; end

      # Template internals
      class Resource < NotFound; end

    end

    # Deprecation error
    class Deprecated < Error; end

  end

end
