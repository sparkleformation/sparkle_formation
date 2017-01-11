require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    # Terraform specific helper implementations
    module Terraform

      # Set customized struct behavior
      def self.included(klass)
        klass.const_set(:CAMEL_KEYS, false)
      end

      def _var(v_name)
        __t_stringish(v_name)
        res = ::SparkleFormation::TerraformStruct.new('var').set!(__attribute_key(v_name))
      end
      alias_method :var!, :_var
      alias_method :parameter!, :_var

      def _path(p_name)
        __t_stringish(p_name)
        ::SparkleFormation::TerraformStruct.new('path').set!(__attribute_key(p_name))
      end
      alias_method :path!, :_path

      def _module(m_name)
        __t_stringish(m_name)
        ::SparkleFormation::TerraformStruct.new('module').set!(__attribute_key(m_name))
      end
      alias_method :module!, :_module

      def _terraform_self(s_name)
        __t_stringish(s_name)
        ::SparkleFormation::TerraformStruct.new('self').set!(__attribute_key(s_name))
      end
      alias_method :self!, :_terraform_self

      def _terraform_lookup(*args)
        ::SparkleFormation::TerraformStruct.new('lookup', *args)
      end
      alias_method :lookup!, :_terraform_lookup

      # TODO: Add resource checking before returning structure
      def _resource(r_name)
        __t_stringish(r_name)
        r_name = __resource_lookup(r_name)
        ::SparkleFormation::TerraformStruct.new(r_name)
      end
      alias_method :resource!, :_resource

      TERRAFORM_INTRINSIC_FUNCTIONS = [
        'base64decode',
        'base64encode',
        'base64sha256',
        'cidrhost',
        'cidrnetmask',
        'cidrsubnet',
        'coalesce',
        'compact',
        'concat',
        'distinct',
        'element',
        'file',
        'format',
        'formatlist',
        'index',
        'join',
        'jsonencode',
        'length',
        'list',
        'lower',
        'map',
        'md5',
        'merge',
        'uuid',
        'replace',
        'sha1',
        'sha256',
        'signum',
        'sort',
        'split',
        'trimspace',
        'upper'
      ]

      # NOTE: Alias implementation disabled due to Ruby 2.3 __callee__ bug
      #   see: https://bugs.ruby-lang.org/issues/12176

      # Generate a builtin terraform function
      #
      # @return [SparkleFormation::FunctionStruct]
      def _fn_format(*args)
        src = ::Kernel.__callee__.to_s
        src = ::Bogo::Utility.camel(src.sub(/(^_|\!$)/, ''), false)
        ::SparkleFormation::TerraformStruct.new(src, *args)
      end

      TERRAFORM_INTRINSIC_FUNCTIONS.map do |f_name|
        ::Bogo::Utility.snake(f_name)
      end.each do |f_name|
        # alias_method "_#{f_name}".to_sym, :_fn_format
        # alias_method "#{f_name}!".to_sym, :_fn_format

        define_method("_#{f_name}".to_sym) do |*args|
          src = ::Kernel.__callee__.to_s
          src = ::Bogo::Utility.camel(src.sub(/(^_|\!$)/, ''), false)
          ::SparkleFormation::TerraformStruct.new(src, *args)
        end
        alias_method "#{f_name}!".to_sym, "_#{f_name}".to_sym
      end

      def __resource_lookup(name)
        resource = root!.resources[name]
        if(resource.nil?)
          name
        else
          "#{resource.type}.#{name}"
        end
      end

      # Resource dependency generator
      # @overload _depends_on(resource_name)
      #   @param resource_name [String, Symbol] logical resource name
      # @overload _depends_on(resource_names)
      #   @param resource_names [Array<String, Symbol>] list of logical resource names
      # @overload _depends_on(*resource_names)
      #   @param resource_names [Array<String, Symbol>] list of logical resource names
      # @return [Array<String>]
      # @note this will directly modify the struct at its current context to inject depends on structure
      def _depends_on(*args)
        _set('depends_on', [args].flatten.compact.map{|s| __attribute_key(s) })
      end
      alias_method :depends_on!, :_depends_on

      # Reference output value from nested stack
      #
      # @param stack_name [String, Symbol] logical resource name of stack
      # @param output_name [String, Symbol] stack output name
      # @return [Hash]
      def _stack_output(stack_name, output_name)
        _module(stack_name)._set(output_name)
      end
      alias_method :stack_output!, :_stack_output

    end

  end
end
