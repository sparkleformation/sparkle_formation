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
    def initialize(f_name = nil, *args)
      super()
      @_fn_name = f_name.to_s
      @_fn_args = args
      @_fn_args.map! do |l_arg|
        if l_arg.is_a?(_klass)
          l_arg = l_arg._root
          l_arg._parent(self)
        end
        l_arg
      end
    end

    # Create a clone of this instance
    def _clone(*_)
      new_inst = _klass_new(_fn_name, *_fn_args)
      new_inst._data.replace(__hashish[
        @table.map { |_key, _value|
          if _key.is_a?(::AttributeStruct)
            _key = _key._clone
          else
            _key = _do_dup(_key)
          end
          if _value.is_a?(::AttributeStruct)
            _value = _value._clone
          else
            _value = _do_dup(_value)
          end
          [_key, _value]
        }
      ])
      new_inst
    end

    # @return [Numeric] hash value for instance
    def hash
      _dump.hash
    end

    # @return [TrueClass, FalseClass]
    def eql?(_other)
      if _other.respond_to?(:_dump) && _other.respond_to?(:_parent)
        ::MultiJson.dump(_dump).hash ==
          ::MultiJson.dump(_other._dump).hash &&
          _parent == _other._parent
      else
        false
      end
    end

    # @return [TrueClass, FalseClass]
    def ==(_other)
      eql?(_other)
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
      if args.empty?
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
      if val.is_a?(::String) && __single_quote_strings
        _set("['#{val}']")
      else
        _set("[#{val.inspect}]")
      end
    end

    # Override of the dump to properly format eval string
    #
    # @return [String]
    def _dump
      unless @table.empty?
        key, value = @table.first
        suffix = _eval_join(
          *[
          key == '_function_' ? nil : key,
          !value.nil? ? value._dump : nil,
        ].compact
        )
      end
      if _fn_name
        args = _fn_args.map do |arg|
          if arg.respond_to?(:_dump)
            arg._dump
          elsif arg.is_a?(::Symbol)
            quote = __single_quote_strings ? "'" : '"'
            "#{quote}#{::Bogo::Utility.camel(arg.to_s, false)}#{quote}"
          elsif arg.is_a?(::String) && __single_quote_strings
            "'#{arg}'"
          else
            arg.inspect
          end
        end.join(', ')
        unless _fn_name.to_s.empty?
          function_name = args.empty? ? "#{_fn_name}#{__empty_argument_list}" : "#{_fn_name}(#{args})"
        end
        internal = _eval_join(
          *[
          function_name,
          suffix,
        ].compact
        )
        if root? || (!__single_anchor? && function_name)
          if !root? && __quote_nested_funcs?
            quote = __single_quote_strings ? "'" : '"'
          end
          "#{quote}#{__anchor_start}#{internal}#{__anchor_stop}#{quote}"
        else
          internal
        end
      else
        suffix
      end
    end

    alias_method :_sparkle_dump, :_dump

    # Join arguments into a string for remote evaluation
    #
    # @param args [Array<String>]
    # @return [String]
    def _eval_join(*args)
      args = args.compact
      args.delete_if &:empty?
      args.slice(1, args.size).to_a.inject(args.first) do |memo, item|
        if item.start_with?('[')
          memo += item
        else
          memo += ".#{item}"
        end
      end
    end

    def __quote_nested_funcs?
      false
    end

    # @return [TrueClass] wrap in single anchor
    def __single_anchor?
      true
    end

    # @return [Class]
    def _klass
      ::SparkleFormation::FunctionStruct
    end

    # @return [String] start character(s) used to anchor function call
    def __anchor_start
      '['
    end

    # @return [String] stop character(s) used to anchor function call
    def __anchor_stop
      ']'
    end

    # @return [String] value to use when argument list is empty
    def __empty_argument_list
      '()'
    end

    # @return [String] dump from root
    def to_s
      _root._dump
    end

    # @return [String] dump from root
    def inspect
      _root._dump
    end

    # @return [TrueClass] enable single quote string generation
    def __single_quote_strings
      true
    end
  end

  # Function struct specialized for Azure variables to check nested
  # variable function value and properly match defined case
  class AzureVariableStruct < FunctionStruct
    # [SparkleStruct] context of function usage
    attr_reader :_fn_context

    # Set current function context
    #
    # @param ctx [SparkleStruct] current context
    # @return [SparkleStruct]
    def _fn_context=(ctx)
      @_fn_context = ctx
    end

    # Wrapper to check for nested function call and properly case
    # the function if found.
    def _dump
      # Remap nested function keys if possible
      if _fn_context && _fn_context.root!.data![_fn_name] && _fn_context.root!.data![_fn_name].data![_fn_args.first]
        __valid_keys = _fn_context.root!.data![_fn_name].data![_fn_args.first].keys!
        __current_key = @table.keys.first
        __match_key = __current_key.to_s.downcase.gsub('_', '')
        __key_remap = __valid_keys.detect do |__nested_key|
          __nested_key.to_s.downcase.gsub('_', '') == __match_key
        end
        if __key_remap
          @table[__key_remap] = @table.delete(@table.keys.first)
        end
      end
      super
    end

    # @return [Class]
    def _klass
      ::SparkleFormation::AzureVariableStruct
    end
  end

  # FunctionStruct for jinja expressions
  class JinjaExpressionStruct < FunctionStruct

    # @return [String] start character(s) used to anchor function call
    def __anchor_start
      '{{ '
    end

    # @return [String] stop character(s) used to anchor function call
    def __anchor_stop
      ' }}'
    end

    # @return [String] value to use when argument list is empty
    def __empty_argument_list
      ''
    end

    # @return [FalseClass] disable single quote string generation
    def __single_quote_strings
      false
    end

    # @return [Class]
    def _klass
      ::SparkleFormation::JinjaExpressionStruct
    end
  end

  # FunctionStruct for jinja statements
  class JinjaStatementStruct < FunctionStruct

    # @return [String] start character(s) used to anchor function call
    def __anchor_start
      '{% '
    end

    # @return [String] stop character(s) used to anchor function call
    def __anchor_stop
      ' %}'
    end

    # @return [String] value to use when argument list is empty
    def __empty_argument_list
      ''
    end

    # @return [FalseClass] disable single quote string generation
    def __single_quote_strings
      false
    end

    # @return [Class]
    def _klass
      ::SparkleFormation::JinjaStatementStruct
    end
  end

  # FunctionStruct for customized google functions
  class GoogleStruct < FunctionStruct

    # @return [String] start character(s) used to anchor function call
    def __anchor_start
      '$('
    end

    # @return [String] stop character(s) used to anchor function call
    def __anchor_stop
      ')'
    end

    # @return [String] value to use when argument list is empty
    def __empty_argument_list
      ''
    end

    # @return [FalseClass] disable single quote string generation
    def __single_quote_strings
      false
    end

    # @return [Class]
    def _klass
      ::SparkleFormation::GoogleStruct
    end
  end

  # FunctionStruct for customized terraform functions
  class TerraformStruct < FunctionStruct

    # @return [String] start character(s) used to anchor function call
    def __anchor_start
      '${'
    end

    # @return [String] stop character(s) used to anchor function call
    def __anchor_stop
      '}'
    end

    # @return [String] value to use when argument list is empty
    def __empty_argument_list
      ''
    end

    # @return [FalseClass] disable single quote string generation
    def __single_quote_strings
      false
    end

    # @return [FalseClass] wrap every structure in anchors
    def __single_anchor?
      true
    end

    def __quote_nested_funcs?
      false
    end

    # @return [Class]
    def _klass
      ::SparkleFormation::TerraformStruct
    end
  end
end
