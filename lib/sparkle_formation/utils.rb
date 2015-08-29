class SparkleFormation

  # Helper utilities
  module Utils

    # Animal stylings on strins
    module AnimalStrings

      # Camel case string
      # @param string [String]
      # @return [String]
      def camel(string)
        string.to_s.split('_').map{|k| "#{k.slice(0,1).upcase}#{k.slice(1,k.length)}"}.join
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
      def []=(k,v)
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
