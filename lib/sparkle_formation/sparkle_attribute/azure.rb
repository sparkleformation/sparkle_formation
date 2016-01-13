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
        'resourceId',
        'subscription'
      ]

      # Generate a builtin azure function
      #
      # @return [SparkleFormation::FunctionStruct]
      def _fn_format(*args)
        src = ::Kernel.__callee__.to_s
        src = ::Bogo::Utility.camel(src.sub(/(^_|\!$)/, ''), false)
        ::SparkleFormation::FunctionStruct.new(src, *args)
      end

      AZURE_FUNCTIONS.each do |f_name|
        alias_method "_#{f_name}".to_sym, :_fn_format
        alias_method "#{f_name}!".to_sym, :_fn_format
      end

    end
  end
end
