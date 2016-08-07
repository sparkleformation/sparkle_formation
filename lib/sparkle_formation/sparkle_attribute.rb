require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    autoload :Aws, 'sparkle_formation/sparkle_attribute/aws'
    autoload :Azure, 'sparkle_formation/sparkle_attribute/azure'
    autoload :Google, 'sparkle_formation/sparkle_attribute/google'
    autoload :Heat, 'sparkle_formation/sparkle_attribute/heat'
    autoload :Rackspace, 'sparkle_formation/sparkle_attribute/rackspace'
    autoload :Terraform, 'sparkle_formation/sparkle_attribute/terraform'

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

    # @overload _puts(obj, ...)
    #   Print to stdout
    #   @param obj [Object] object to print
    # @see Kernel.puts
    # @return [NilClass]
    def _puts(*args)
      $stdout.puts(*args)
    end
    alias_method :puts!, :_puts

    # Raise an exception
    # @see Kernel.raise
    def _raise(*args)
      ::Kernel.raise(*args)
    end
    alias_method :raise!, :_raise

    # @overload _method(sym)
    #   Lookup a method definition on self
    #   @param sym [Symbol] name of method
    # @note usually used as `puts! method!(:foo).source_location`
    # @see Object#method
    # @return [Method]
    def _method(*args)
      ::Kernel.instance_method(:method).bind(self).call(*args)
    end
    alias_method :method!, :_method

    # @overload _dynamic(resource_type, custom_name, options={})
    #   Insert builtin resource
    #   @param resource_type [String, Symbol] provider resource type
    #   @param custom_name [String, Symbol] custom name used for resource name generation
    #   @param options [Hash]
    #   @option options [String, NilClass] :resource_name_suffix custom suffix to use for
    #     name generation (defaults to resource_type)
    #   @note All other options are set into the new resource's properties
    # @overload _dynamic(dynamic_name, custom_name, options={})
    #   Call custom dynamic from available sparkle packs
    #   @param dynamic_name [Symbol] name of registered dynamic
    #   @param custom_name [Symbol, String] unique name passed directly to registered dynamic
    #   @param options [Hash]
    #   @option options [String, Symbol] :provider override provider restriction when fetching dynamic
    #   @note All options are passed to dynamic with custom_name
    # @yieldblock [new_struct] Provides newly inserted structure
    # @yieldparam new_struct [SparkleStruct] newly inserted structure which can be modified
    # @yieldreturn [Object] discarded
    # @return [self]
    def _dynamic(name, *args, &block)
      SparkleFormation.insert(name, self, *args, &block)
    end
    alias_method :dynamic!, :_dynamic

    # @overload _registry(name)
    #   Return value from registry item with given name
    #   @param name [String, Symbol] registry item name
    # @overload _registry(name, *args, options={})
    #   Pass given parameters to registry item with given name and
    #   return the value
    #   @param name [String, Symbol] registry item name
    #   @param options [Hash]
    #   @param options [Hash] :provider override provider restriction when fetching registry item
    #   @param args [Object] argument list
    #   @note args and options will be passed directly to registry item when called
    # @return [Object] return value of registry item
    def _registry(name, *args)
      SparkleFormation.registry(name, self, *args)
    end
    alias_method :registry!, :_registry

    # @overload _nest(template, *names, options={})
    #   Nest a stack resource
    #   @param template [String, Symbol] name of desired template
    #   @param names [String, Symbol] list of optional string/symbol values for resource name generation
    #   @param options [Hash]
    #   @option options [String, Symbol] :provider override provider restriction when
    #     fetching template
    #   @option options [Truthy, Falsey] :overwrite_name when set to true, will not include
    #     template name in resource name
    #   @option options [Hash] :parameters compile time parameter values to pass to nested template
    # @yieldblock [new_struct] Provides newly inserted structure
    # @yieldparam new_struct [SparkleStruct] newly inserted structure which can be modified
    # @yieldreturn [Object] discarded
    # @return [self]
    def _nest(template, *args, &block)
      SparkleFormation.nest(template, self, *args, &block)
    end
    alias_method :nest!, :_nest

    # Format the provided key. If symbol type is provided
    # formatting is forced. Otherwise the default formatting
    # is applied
    #
    # @param key [String, Symbol] given key
    # @return [String] formatted key
    def __attribute_key(key)
      if(key.is_a?(::Symbol) || key.is_a?(::String))
        _process_key(key, key.is_a?(::Symbol) ? :force : nil)
      else
        key
      end
    end

  end
end
