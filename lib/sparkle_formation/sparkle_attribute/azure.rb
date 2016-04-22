require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    # Azure specific helper implementations
    module Azure

      # Extract resources Hash from template dump and transform to
      # Array type expected by the ARM API
      #
      # @param hash [Hash] template dump
      # @return [Hash]
      def self.resources_formatter(hash)
        if(hash.key?('resources') && !hash['resources'].is_a?(Array))
          resources = hash.delete('resources')
          hash['resources'] = Array.new
          resources.each do |r_name, r_contents|
            hash['resources'].push(
              r_contents.merge('name' => r_name)
            )
          end
        end
        hash
      end

      # Inject camel style on module inclusion
      # Add custom dump functionality to properly set resources
      def self.included(klass)
        klass.const_set(:CAMEL_STYLE, :no_leading)

        klass.class_eval do
          def _azure_dump
            result = _attribute_struct_dump
            if(_parent.nil?)
              result = ::SparkleFormation::SparkleAttribute::Azure.resources_formatter(result)
            end
            result
          end
          alias_method :_attribute_struct_dump, :_dump
          alias_method :_dump, :_azure_dump
          alias_method :dump!, :_azure_dump
        end
      end

      # Valid azure builtin functions
      AZURE_FUNCTIONS = [
        'add',
        'copyIndex',
        'div',
        'int',
        'length',
        'mod',
        'mul',
        'sub',
        'base64',
        'concat',
        'padLeft',
        'replace',
        'split',
        'string',
        'substring',
        'toLower',
        'toUpper',
        'trim',
        'uniqueString',
        'uri',
        'deployment',
        'parameters',
        'variables',
        'listKeys',
        'providers',
        'reference',
        'resourceGroup',
        'subscription'
      ]

      # NOTE: Alias implementation disabled due to Ruby 2.3 __callee__ bug
      #   see: https://bugs.ruby-lang.org/issues/12176

      # Generate a builtin azure function
      #
      # @return [SparkleFormation::FunctionStruct]
      def _fn_format(*args)
        src = ::Kernel.__callee__.to_s
        src = ::Bogo::Utility.camel(src.sub(/(^_|\!$)/, ''), false)
        ::SparkleFormation::FunctionStruct.new(src, *args)
      end

      AZURE_FUNCTIONS.map do |f_name|
        ::Bogo::Utility.snake(f_name)
      end.each do |f_name|
        # alias_method "_#{f_name}".to_sym, :_fn_format
        # alias_method "#{f_name}!".to_sym, :_fn_format

        define_method("_#{f_name}".to_sym) do |*args|
          src = ::Kernel.__callee__.to_s
          src = ::Bogo::Utility.camel(src.sub(/(^_|\!$)/, ''), false)
          ::SparkleFormation::FunctionStruct.new(src, *args)
        end
        alias_method "#{f_name}!".to_sym, "_#{f_name}".to_sym
      end

      # Customized resourceId generator that will perform automatic
      # lookup on defined resources for building the function if Symbol
      # type is provided
      #
      # @param args [Object]
      # @return [FunctionStruct]
      def _resource_id(*args)
        if(args.size > 1)
          ::SparkleFormation::FunctionStruct.new('resourceId', *args)
        else
          r_name = args.first
          resource = _root.resources.set!(r_name)
          if(resource.nil?)
            ::Kernel.raise ::SparkleFormation::Error::NotFound::Resource.new(:name => r_name)
          else
            ::SparkleFormation::FunctionStruct.new(
              'resourceId',
              resource.type,
              resource.resource_name!
            )
          end
        end
      end
      alias_method :resource_id!, :_resource_id

      # Customized dependsOn generator. Will automatically build resource
      # reference value using defined resources for Symbol type values. Sets
      # directly into current context.
      #
      # @param args [Object]
      # @return [Array<String>]
      def _depends_on(*args)
        args = args.map do |item|
          case item
          when ::Symbol
            resource = _root.resources.set!(item)
            if(resource.nil?)
              ::Kernel.raise ::SparkleFormation::Error::NotFound::Resource.new(:name => item)
            else
              [resource.type, resource.resource_name!].join('/')
            end
          else
            item
          end
        end
        set!(:depends_on, args)
      end
      alias_method :depends_on!, :_depends_on

      # Reference output value from nested stack
      #
      # @param stack_name [String, Symbol] logical resource name of stack
      # @param output_name [String, Symbol] stack output name
      # @return [Hash]
      def _stack_output(stack_name, output_name)
        stack_name = __attribute_key(stack_name)
        output_name = __attribute_key(output_name)
        o_root = _reference(stack_name)
        o_root.outputs.set!(output_name).value
        o_root
      end
      alias_method :stack_output!, :_stack_output

    end
  end
end
