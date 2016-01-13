require 'sparkle_formation'

class SparkleFormation

  # SparkleFormation customized AttributeStruct targeted at defining
  # strings of code for remote evaulation
  class FunctionStruct < AttributeStruct

    # @return [String] name of function
    attr_reader :_fn_name
    # @return [Array<Object>] function argument list
    attr_reader :_fn_args

    # Create a new FunctionStruct instance
    #
    # @param f_name [String] name of function
    # @param args [Array<Object>] argument list
    # @return [self]
    def initialize(f_name=nil, *args)
      super()
      @_fn_name = f_name.to_s
      @_fn_args = args
      @_fn_args.map! do |l_arg|
        if(l_arg.is_a?(_klass))
          l_arg = l_arg._root
          l_arg._parent(self)
        end
        l_arg
      end
    end

    # @return [False] functions are never nil
    def nil?
      false
    end

    # @return [TrueClass, FalseClass] is root struct
    def root?
      _parent.nil?
    end

    # Override to provide expected behavior when arguments are passed
    # to a function call
    #
    # @param name [String, Symbol] method name
    # @param args [Object<Array>] argument list
    # @return [Object]
    def method_missing(name, *args)
      if(args.empty?)
        super
      else
        @table['_function_'] = _klass_new(name, *args)
      end
    end

    # Set accessor directly into table data
    #
    # @param val [Integer, String]
    # @return [FunctionStruct]
    def [](val)
      _set("[#{val}]")
    end

    # Override of the dump to properly format eval string
    #
    # @return [String]
    def _dump
      unless(@table.empty?)
        key, value = @table.first
        suffix = _eval_join(
          *[
            key == '_function_' ? nil : key,
            !value.nil? ? value._dump : nil
          ].compact
        )
      end
      if(_fn_name)
        args = _fn_args.map do |arg|
          if(arg.respond_to?(:_dump))
            arg._dump
          else
            arg.inspect
          end
        end.join(', ')
        internal = _eval_join(
          *[
            args.empty? ? _fn_name : "#{_fn_name}(#{args})",
            suffix
          ].compact
        )
        root? ? "[#{internal}]" : internal
      else
        suffix
      end
    end

    # Join arguments into a string for remote evaluation
    #
    # @param args [Array<String>]
    # @return [String]
    def _eval_join(*args)
      args = args.compact
      args.delete_if(&:empty?)
      args.slice(1, args.size).to_a.inject(args.first) do |memo, item|
        if(item.start_with?('['))
          memo += item
        else
          memo += ".#{item}"
        end
      end
    end

    # @return [Class]
    def _klass
      ::SparkleFormation::FunctionStruct
    end

  end
end
