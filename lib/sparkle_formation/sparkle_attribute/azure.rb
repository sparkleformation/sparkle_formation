require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    # Azure specific helper implementations
    module Azure

      # Inject camel style on module inclusion
      def self.included(klass)
        klass.const_set(:CAMEL_STYLE, :no_leading)
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
