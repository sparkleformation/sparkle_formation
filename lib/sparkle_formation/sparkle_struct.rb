require 'sparkle_formation'
require 'attribute_struct/monkey_camels'

class SparkleFormation

  # SparkleFormation customized AttributeStruct
  class SparkleStruct < AttributeStruct

    # AWS specific struct
    class Aws < SparkleStruct
      include SparkleAttribute
      include SparkleAttribute::Aws
    end

    # Azure specific struct
    class Azure < SparkleStruct
      include SparkleAttribute
      include SparkleAttribute::Azure
    end

    # Google specific struct
    class Google < SparkleStruct
      include SparkleAttribute
      include SparkleAttribute::Google
    end

    # Heat specific struct
    class Heat < SparkleStruct
      include SparkleAttribute
      include SparkleAttribute::Heat
    end

    OpenStack = Heat
    Rackspace = Heat
    # Rackspace specific struct
    class Rackspace < SparkleStruct
      include SparkleAttribute
      include SparkleAttribute::Rackspace
    end

    # Terraform specific struct
    class Terraform < SparkleStruct
      include SparkleAttribute
      include SparkleAttribute::Terraform
    end

    include ::SparkleFormation::SparkleAttribute
    # @!parse include ::SparkleFormation::SparkleAttribute
    include ::SparkleFormation::Utils::TypeCheckers
    # @!parse include ::SparkleFormation::TypeCheckers

    # @return [SparkleStruct]
    attr_accessor :_struct_class

    # Override initializer to force desired behavior
    def initialize(*_)
      super
      @_camel_keys = true
      _set_state :hash_load_struct => true
    end

    # Set SparkleFormation instance
    #
    # @param inst [SparkleFormation]
    # @return [SparkleFormation]
    def _set_self(inst)
      unless inst.is_a?(::SparkleFormation)
        ::Kernel.raise ::TypeError.new "Expecting type of `SparkleFormation` but got `#{inst.class}`"
      end
      @self = inst
    end

    # @return [SparkleFormation]
    def _self(*_)
      unless @self
        if _parent.nil?
          ::Kernel.raise ::ArgumentError.new 'Creator did not provide return reference!'
        else
          _parent._self
        end
      else
        @self
      end
    end

    # Process value in search for FunctionStruct objects. If found replace with
    # the root item of the structure
    #
    # @param item [Object]
    # @return [Object]
    def function_bubbler(item)
      if item.is_a?(::Enumerable)
        if item.respond_to?(:keys)
          item.class[
            *item.map do |entry|
              function_bubbler(entry)
            end.flatten(1)
          ]
        else
          item.class[
            *item.map do |entry|
              function_bubbler(entry)
            end
          ]
        end
      elsif item.is_a?(::SparkleFormation::FunctionStruct)
        item._root
      else
        item
      end
    end

    # Override to inspect result value and fetch root if value is a
    # FunctionStruct
    def method_missing(sym, *args, &block)
      if sym.is_a?(::String) || sym.is_a?(::Symbol)
        if sym.to_s.start_with?('_') || sym.to_s.end_with?('!')
          ::Kernel.raise ::NoMethodError.new "Undefined method `#{sym}` for #{_klass.name}"
        end
      end
      super(*[sym, *args], &block)
      if sym.is_a?(::String) || sym.is_a?(::Symbol)
        if (s = sym.to_s).end_with?('=')
          s.slice!(-1, s.length)
          sym = s
        end
        sym = _process_key(sym)
      else
        sym = function_bubbler(sym)
      end
      # When setting an AttributeStruct type instance check parent or context if
      # available and reset if it has been moved.
      if @table[sym].is_a?(::AttributeStruct)
        if @table[sym].is_a?(::SparkleFormation::FunctionStruct)
          if @table[sym].respond_to?(:_fn_context) && @table[sym]._fn_context != self
            @table[sym] = @table[sym]._clone
            @table[sym]._fn_context = self
          end
        elsif @table[sym]._parent != self
          @table[sym]._parent(self)
        end
      end
      @table[sym] = function_bubbler(@table[sym])
      @table[sym]
    end

    # @return [Class]
    def _klass
      _struct_class || ::SparkleFormation::SparkleStruct
    end

    # Instantiation override properly set origin template
    #
    # @return [SparkleStruct]
    def _klass_new(*args, &block)
      inst = super()
      inst._set_self(_self)
      inst._struct_class = _struct_class
      if args.first.is_a?(::Hash)
        inst._load(args.first)
      end
      if block
        inst.build!(&block)
      end
      inst
    end

    # Override the state to force helpful error when no value has been
    # provided
    #
    # @param arg [String, Symbol] name of parameter
    # @return [Object]
    # @raises [ArgumentError]
    def _state(arg)
      result = super
      if @self && result.nil?
        if _self.parameters.keys.map(&:to_s).include?(arg.to_s)
          unless _self.parameters[arg.to_sym].key?(:default)
            ::Kernel.raise ::ArgumentError.new "No value provided for compile time parameter: `#{arg}`!"
          else
            result = _self.parameters[arg.to_sym][:default]
          end
        end
      end
      result
    end

    alias_method :state!, :_state

    # TODO: Need to refactor attribute_struct dumping to allow hooking
    # custom behavior instead of heavy copy/paste to modify a method call

    # Process and unpack items for dumping within deeply nested
    # enumerable types
    #
    # @param item [Object]
    # @return [Object]
    def _sparkle_dump_unpacker(item)
      if item.is_a?(::Enumerable)
        if item.respond_to?(:keys)
          item.class[
            *item.map do |entry|
              _sparkle_dump_unpacker(entry)
            end.flatten(1)
          ]
        else
          item.class[
            *item.map do |entry|
              _sparkle_dump_unpacker(entry)
            end
          ]
        end
      elsif item.is_a?(::AttributeStruct)
        item.nil? ? UNSET_VALUE : item._sparkle_dump
      elsif item.is_a?(::SparkleFormation)
        item.sparkle_dump
      else
        item
      end
    end

    # @return [AttributeStruct::AttributeHash, Mash] dump struct to hashish
    def _sparkle_dump
      processed = @table.keys.map do |key|
        value = @table[key]
        val = _sparkle_dump_unpacker(value)
        [_sparkle_dump_unpacker(key), val] unless val == UNSET_VALUE
      end.compact
      __hashish[*processed.flatten(1)]
    end

    alias_method :sparkle_dump!, :_sparkle_dump
  end
end
