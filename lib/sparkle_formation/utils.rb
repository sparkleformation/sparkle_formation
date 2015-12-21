class SparkleFormation

  # Helper utilities
  module Utils

    # Type check helpers
    module TypeCheckers

      # Validate given value is type defined within valid types
      #
      # @param val [Object] value
      # @param types [Class, Array<Class>] valid types
      # @return [NilClass]
      # @raises [TypeError]
      def __t_check(val, types)
        types = [types] unless types.is_a?(Array)
        if(types.none?{|t| val.is_a?(t)})
          file_name, line_no = ::Kernel.caller.detect do |l|
            !l.split(':').first.to_s.include?('/sparkle_formation')
          end.split(':')[0, 2]
          file_name = file_name.to_s.sub(::Dir.pwd, '.')
          ::Kernel.raise TypeError.new "Received invalid value type `#{val.class}`! " \
            "(Allowed types: `#{types.join('`, `')}`) -> #{file_name} @ line #{line_no}"
        end
      end

      # Validate given value is String or Symbol type
      #
      # @return [NilClass]
      # @raises [TypeError]
      def __t_stringish(val)
        __t_check(val, [String, Symbol])
      end

      # Validate given value is a Hash type
      #
      # @return [NilClass]
      # @raises [TypeError]
      def __t_hashish(val)
        __t_check(val, Hash)
      end

    end

    # Animal stylings on strins
    module AnimalStrings

      # Camel case string
      # @param string [String]
      # @return [String]
      def camel(string)
        string.to_s.split('_').map{|k| "#{k.slice(0, 1).upcase}#{k.slice(1, k.length)}"}.join
      end

      # Snake case (underscore) string
      #
      # @param string [String]
      # @return [String]
      def snake(string)
        string.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
      end

    end

  end

  # Registry helper
  class Registry

    class << self

      # Initialize registry
      #
      # @return [self]
      def init!
        @register = AttributeStruct.hashish.new
        self
      end

      # Register block
      #
      # @param name [String, Symbol] name of item
      # @yield block to register
      def register(name, &block)
        @register[name] = block
      end

      # Insert registry item into context
      #
      # @param name [String, Symbol] name of item
      # @param location [AttributeStruct] context to apply block
      # @param args [Object] argument list for block
      def insert(name, location, *args)
        if(block = @register[name])
          location.instance_exec(*args, &block)
        else
          raise KeyError.new("Requested item not found in registry (#{name})")
        end
      end

    end

  end

  # Cache helper
  class Cache
    class << self

      # Get value
      #
      # @param k [Object]
      # @return [Object]
      def [](k)
        init!
        Thread.current[:sparkle_cache][k]
      end

      # Set value
      #
      # @param k [Object] key
      # @param v [Object] value
      # @return [Object] v
      def []=(k, v)
        init!
        Thread.current[:sparkle_cache][k] = v
      end

      # Initialize cache within thread
      #
      # @return [self]
      def init!
        unless(Thread.current[:sparkle_cache])
          Thread.current[:sparkle_cache] = {}
        end
        self
      end

    end
  end
end

SfnCache = SparkleFormation::Cache
SfnRegistry = SparkleFormation::Registry.init!
