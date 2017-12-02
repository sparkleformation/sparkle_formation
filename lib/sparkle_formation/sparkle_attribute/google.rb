require 'zlib'
require 'sparkle_formation'

class SparkleFormation
  module SparkleAttribute

    # Google specific helper implementations
    module Google
      CHARACTER_COLLECTION = ('a'..'z').to_a

      def self.included(klass)
        klass.const_set(:CAMEL_STYLE, :no_leading)

        klass.class_eval do
          def _google_dump
            result = _non_google_attribute_struct_dump
            if _parent.nil?
              sparkle_root = {}
              if result.key?('resources') && result['resources'].is_a?(Hash)
                resources = result.delete('resources') || {}
                sparkle_root = (resources.delete(_self.name) || {}).fetch('properties', {})
                result['resources'] = resources.map do |r_name, r_content|
                  r_content.merge('name' => r_name)
                end
                outputs = result.delete('outputs') || {}
                result['outputs'] = outputs.map do |o_name, o_content|
                  o_content.merge('name' => o_name)
                end
                if _self.parent.nil?
                  result = {
                    'resources' => [{
                      'name' => _self.name,
                      'type' => _self.stack_resource_type,
                      'properties' => {
                        'stack' => result,
                      }.merge(sparkle_root),
                    }],
                  }
                end
              end
            end
            result
          end

          alias_method :_non_google_attribute_struct_dump, :_dump
          alias_method :_dump, :_google_dump
          alias_method :dump!, :_google_dump
          alias_method :_non_google_dynamic!, :dynamic!
          alias_method :dynamic!, :_google_dynamic!
        end
      end

      # Customized dynamic to provide automatic unique name generation for
      # built in resources
      #
      # @see SparkleFormation::SparkleAttribute#dynamic!
      # @note generate unique names using the `:sparkle_unique` argument
      def _google_dynamic!(name, *args, &block)
        if args.delete(:sparkle_unique)
          seed = Zlib.crc32(_self.root_path.map(&:name).join('-'))
          gen = Random.new(seed)
          suffix = Array.new(10) do
            CHARACTER_COLLECTION.at(
              gen.rand(CHARACTER_COLLECTION.size)
            )
          end.join
          config_hash = args.detect { |a| a.is_a?(Hash) }
          unless config_hash
            config_hash = {}
            args.push(config_hash)
          end
          config_hash[:resource_name_suffix] = "-#{suffix}"
          args[0] = args.first.to_s.tr('_', '-').downcase
        end
        _non_google_dynamic!(name, *args, &block)
      end

      # Reference generator. Will lookup defined resource name
      # to validate exist.
      #
      # @param r_name [String, Symbol] resource name
      # @return [SparkleFormation::GoogleStruct]
      def _ref(r_name)
        __t_stringish(r_name)
        if _root.resources.set!(r_name).nil?
          ::Kernel.raise ::SparkleFormation::Error::NotFound::Resource.new(:name => r_name)
        else
          ::SparkleFormation::GoogleStruct.new('ref').set!(__attribute_key(r_name))
        end
      end

      alias_method :ref!, :_ref

      # Jinja function string wrapper
      #
      # @return [SparkleFormation::JinjaExpressionStruct]
      def _jinja
        ::SparkleFormation::JinjaExpressionStruct.new
      end

      alias_method :jinja!, :_jinja
      alias_method :fn!, :_jinja

      # Request deployment manager environment variable
      #
      # @param e_name [String, Symbol] environment variable name
      # @return [SparkleFormation::JinjaExpressionStruct]
      def _env(e_name)
        __t_stringish(e_name)
        _jinja.env[__attribute_key(e_name)]
      end

      alias_method :env!, :_env

      # Access a property value supplied to template
      #
      # @param p_name [String, Symbol] parameter name
      # @return [SparkleFormation::JinjaExpressionStruct]
      # @todo Provide lookup validation that defined p_name is valid
      def _property(p_name)
        __t_stringish(p_name)
        _jinja.properties[__attribute_key(p_name)]
      end

      alias_method :property!, :_property
      alias_method :properties!, :_property

      # Generate a statement
      #
      # @param line [String]
      # @return [SparkleFormation::JinjaStatementStruct]
      def _statement(line)
        ::SparkleFormation::JinjaStatementStruct.new(line)
      end

      alias_method :statement!, :_statement

      # Reference output value from nested stack
      #
      # @param stack_name [String, Symbol] logical resource name of stack
      # @param output_name [String, Symbol] stack output name
      # @return [SparkleFormation::JinjaExpressionStruct]
      def _stack_output(stack_name, output_name)
        __t_stringish(stack_name)
        __t_stringish(output_name)
        _ref(stack_name)._set(output_name)
      end

      alias_method :stack_output!, :_stack_output
    end
  end
end
