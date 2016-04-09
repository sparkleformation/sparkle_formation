require 'sparkle_formation'

class SparkleFormation
  module SparkleAttribute

    # Google specific helper implementations

    module Google

      # Reference generator. Will lookup defined resource name
      # to validate exist.
      #
      # @param r_name [String, Symbol] resource name
      # @return [SparkleFormation::GoogleStruct]
      def _ref(r_name)
        if(_root.resources.set!(r_name).nil?)
          ::Kernel.raise ::SparkleFormation::Error::NotFound::Resource.new(:name => r_name)
        else
          ::SparkleFormation::GoogleStruct.new('ref').set!(r_name)
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
        _jinja.env[__attribute_key(e_name)]
      end
      alias_method :env!, :_env

      # Access a property value supplied to template
      #
      # @param p_name [String, Symbol] parameter name
      # @return [SparkleFormation::JinjaExpressionStruct]
      # @todo Provide lookup validation that defined p_name is valid
      def _property(p_name)
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

    end

  end
end
