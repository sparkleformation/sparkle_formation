require 'sparkle_formation'
require 'attribute_struct/monkey_camels'

class SparkleFormation
  # SparkleFormation customized AttributeStruct
  class SparkleStruct < AttributeStruct

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
      unless(inst.is_a?(::SparkleFormation))
        ::Kernel.raise ::TypeError.new "Expecting type of `SparkleFormation` but got `#{inst.class}`"
      end
      @self = inst
    end

    # @return [SparkleFormation]
    def _self(*_)
      unless(@self)
        if(_parent.nil?)
          ::Kernel.raise ::ArgumentError.new 'Creator did not provide return reference!'
        else
          _parent._self
        end
      else
        @self
      end
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
      if(args.first.is_a?(::Hash))
        inst._load(args.first)
      end
      if(block)
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
      if(@self && result.nil?)
        if(_self.parameters.keys.map(&:to_s).include?(arg.to_s))
          ::Kernel.raise ::ArgumentError.new "No value provided for compile time parameter: `#{arg}`!"
        end
      end
      result
    end
    alias_method :state!, :_state

  end
end
