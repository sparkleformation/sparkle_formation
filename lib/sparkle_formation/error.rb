require 'sparkle_formation'

class SparkleFormation

  class Error < StandardError

    class NotFound < KeyError
      attr_reader :name

      def initialize(*args)
        opts = args.detect{|o| o.is_a?(Hash)}
        args.delete(opts) if opts
        super(args)
        @name = opts[:name] if opts
      end

      class Dynamic < NotFound; end
      class Component < NotFound; end
      class Registry < NotFound; end

    end
  end

end
