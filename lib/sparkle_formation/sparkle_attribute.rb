require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    autoload :Aws, 'sparkle_formation/sparkle_attribute/aws'

    # Return current resource name
    #
    # @return [String]
    def _resource_name
      result = nil
      if(_parent)
        if(_parent._parent == _root)
          result = _parent._data.detect do |r_name, r_value|
            r_value == self
          end
          result = result.first if result
        else
          result = _parent._resource_name
        end
      end
      unless(result)
        ::Kernel.raise NameError.new 'Failed to determine current resource name! (Check call location)'
      end
      result
    end
    alias_method :resource_name!, :_resource_name

    # Execute system command
    #
    # @param command [String]
    # @return [String] result
    def _system(command)
      ::Kernel.send('`', command)
    end
    alias_method :system!, :_system

    # Print to stdout
    #
    # @param args
    # @return [NilClass]
    def _puts(*args)
      $stdout.puts(*args)
    end
    alias_method :puts!, :_puts

    # Raise an exception
    def _raise(*args)
      ::Kernel.raise(*args)
    end
    alias_method :raise!, :_raise

    # Dynamic insertion helper method
    #
    # @param name [String, Symbol] dynamic name
    # @param args [Object] argument list for dynamic
    # @return [self]
    def dynamic!(name, *args, &block)
      SparkleFormation.insert(name, self, *args, &block)
    end

    # Registry insertion helper method
    #
    # @param name [String, Symbol] name of registry item
    # @param args [Object] argument list for registry
    # @return [self]
    def registry!(name, *args)
      SparkleFormation.registry(name, self, *args)
    end

    # Stack nesting helper method
    #
    # @param template [String, Symbol] template to nest
    # @param args [String, Symbol] stringified and underscore joined for name
    # @return [self]
    def nest!(template, *args, &block)
      SparkleFormation.nest(template, self, *args, &block)
    end

    # TODO: Deprecate or re-imagine

    # @return [TrueClass, FalseClass]
    def rhel?
      !!@platform[:rhel]
    end

    # @return [TrueClass, FalseClass]
    def debian?
      !!@platform[:debian]
    end

    # Set the destination platform
    #
    # @param plat [String, Symbol] one of :rhel or :debian
    # @return [TrueClass]
    def _platform=(plat)
      @platform || __hashish
      @platform.clear
      @platform[plat.to_sym] = true
    end

  end
end
