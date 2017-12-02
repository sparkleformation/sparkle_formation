require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    # AWS specific helper implementations
    module Aws

      # @overload _cf_join(*args, opts={})
      #   Fn::Join generator
      #   @param args [String, Hash] list of items to join
      #   @param opts [Hash]
      #   @option opts [Hash] :options options for join function
      #   @option options [String] :delimiter value used for joining items. Defaults to ''
      # @return [Hash]
      def _cf_join(*args)
        options = args.detect { |i| i.is_a?(Hash) && i[:options] } || {:options => {}}
        args.delete(options)
        unless args.size == 1
          args = [args]
        end
        {'Fn::Join' => [options[:options][:delimiter] || '', *args]}
      end

      alias_method :join!, :_cf_join

      # Split generator
      #
      # @param string [String, Hash] string to split
      # @param delimiter [String] delimiter to split string
      # @return [Hash]
      def _cf_split(string, delimiter)
        __t_stringish(string) unless string.is_a?(Hash)
        __t_stringish(delimiter) unless delimiter.is_a?(Hash)
        {'Fn::Split' => [delimiter, string]}
      end

      alias_method :split!, :_cf_split

      # Sub generator
      #
      # @param string [String, Hash] string to apply substitution
      # @param variables [Hash] key value mappings for substitution
      # @return [Hash]
      def _cf_sub(string, variables = nil)
        if variables.nil?
          {'Fn::Sub' => string}
        else
          __t_hashish(variables)
          {'Fn::Sub' => [string, variables]}
        end
      end

      alias_method :_sub, :_cf_sub
      alias_method :sub!, :_cf_sub

      # Ref generator
      #
      # @param thing [String, Symbol] reference name
      # @return [Hash]
      # @note Symbol value will force key processing
      def _cf_ref(thing)
        __t_stringish(thing)
        {'Ref' => __attribute_key(thing)}
      end

      alias_method :_ref, :_cf_ref
      alias_method :ref!, :_cf_ref

      # ValueImport generator
      #
      # @param thing [String, Symbol, Hash] value import
      # @return [Hash]
      def _cf_value_import(thing)
        __t_stringish(thing) unless thing.is_a?(Hash)
        {'Fn::ImportValue' => __attribute_key(thing)}
      end

      alias_method :_import_value, :_cf_value_import
      alias_method :import_value!, :_cf_value_import

      # @overload _cf_map(map_name, top_level_key, second_level_key)
      #   Fn::FindInMap generator
      #   @param map_name [String, Symbol] name of map
      #   @param top_level_key [String, Symbol, Hash] top level key name
      #   @param second_level_key [String, Symbol, Hash] second level key name
      # @return [Hash]
      def _cf_map(thing, key, *suffix)
        __t_stringish(thing)
        suffix = suffix.map do |item|
          if item.is_a?(Symbol)
            _process_key(item, :force)
          else
            item
          end
        end
        thing = __attribute_key(thing)
        if key.is_a?(Symbol)
          key = ref!(key)
        end
        {'Fn::FindInMap' => [thing, key, *suffix]}
      end

      alias_method :_cf_find_in_map, :_cf_map
      alias_method :find_in_map!, :_cf_map
      alias_method :map!, :_cf_map

      # @overload _cf_attr(logical_id, attribute_name)
      #   Fn::GetAtt generator
      #   @param logical_id [String, Symbol] logical resource name
      #   @param attribute_name [String, Symbol] name of desired resource attribute
      # @return [Hash]
      def _cf_attr(*args)
        r_name = args.first
        args = args.slice(1, args.size)
        __t_stringish(r_name)
        args = args.map do |thing|
          if thing.is_a?(Symbol)
            _process_key(thing, :force)
          else
            thing
          end
        end
        {'Fn::GetAtt' => [__attribute_key(r_name), *args]}
      end

      alias_method :_cf_get_att, :_cf_attr
      alias_method :get_att!, :_cf_attr
      alias_method :attr!, :_cf_attr

      # Fn::Base64 generator
      #
      # @param arg [Object] argument to be encoded
      # @return [Hash]
      def _cf_base64(arg)
        {'Fn::Base64' => arg}
      end

      alias_method :base64!, :_cf_base64

      # Fn::GetAZs generator
      #
      # @param region [String, Symbol] String will pass through. Symbol will be converted to ref
      # @return [Hash]
      def _cf_get_azs(region = nil)
        region = case region
                 when Symbol
                   _cf_ref(region)
                 when NilClass
                   ''
                 else
                   region
                 end
        {'Fn::GetAZs' => region}
      end

      alias_method :get_azs!, :_cf_get_azs
      alias_method :azs!, :_cf_get_azs

      # Fn::Select generator
      #
      # @param index [String, Symbol, Integer] Symbol will be converted to ref
      # @param item [Object, Symbol] Symbol will be converted to ref
      # @return [Hash]
      def _cf_select(index, item)
        index = index.is_a?(Symbol) ? _cf_ref(index) : index
        item = _cf_ref(item) if item.is_a?(Symbol)
        {'Fn::Select' => [index, item]}
      end

      alias_method :select!, :_cf_select

      # Condition generator
      #
      # @param name [String, Symbol] symbol will be processed
      # @return [Hash]
      def _condition(name)
        __t_stringish(name)
        {'Condition' => __attribute_key(name)}
      end

      alias_method :condition!, :_condition

      # Condition setter
      #
      # @param name [String, Symbol] condition name
      # @return [SparkleStruct]
      # @note this is used to set a {"Condition" => "Name"} into the
      #   current context, generally the top level of a resource
      def _on_condition(name)
        _set(*_condition(name).to_a.flatten)
      end

      alias_method :on_condition!, :_on_condition

      # Fn::If generator
      #
      # @param cond [String, Symbol] symbol will be case processed
      # @param true_value [Object] item to be used when true
      # @param false_value [Object] item to be used when false
      # @return [Hash]
      def _if(cond, true_value, false_value)
        {'Fn::If' => _array(__attribute_key(cond), true_value, false_value)}
      end

      alias_method :if!, :_if

      # Fn::And generator
      #
      # @param args [Object] items to be AND'ed together
      # @return [Hash]
      # @note symbols will be processed and set as condition. strings
      #   will be set as condition directly. procs will be evaluated
      def _and(*args)
        {
          'Fn::And' => _array(
            *args.map { |v|
            if v.is_a?(Symbol) || v.is_a?(String)
              _condition(v)
            else
              v
            end
          }
          ),
        }
      end

      alias_method :and!, :_and

      # Fn::Equals generator
      #
      # @param v1 [Object]
      # @param v2 [Object]
      # @return [Hash]
      def _equals(v1, v2)
        {'Fn::Equals' => _array(v1, v2)}
      end

      alias_method :equals!, :_equals

      # Fn::Not generator
      #
      # @param arg [Object]
      # @return [Hash]
      def _not(arg)
        if arg.is_a?(String) || arg.is_a?(Symbol)
          arg = _condition(arg)
        else
          arg = _array(arg).first
        end
        {'Fn::Not' => [arg]}
      end

      alias_method :not!, :_not

      # Fn::Or generator
      #
      # @param v1 [Object]
      # @param v2 [Object]
      # @return [Hash]
      def _or(*args)
        {
          'Fn::Or' => _array(
            *args.map { |v|
            if v.is_a?(Symbol) || v.is_a?(String)
              _condition(v)
            else
              v
            end
          }
          ),
        }
      end

      alias_method :or!, :_or

      # No value generator
      #
      # @return [Hash]
      def _no_value
        _ref('AWS::NoValue')
      end

      alias_method :no_value!, :_no_value

      # Region generator
      #
      # @return [Hash]
      def _region
        _ref('AWS::Region')
      end

      alias_method :region!, :_region

      # Notification ARNs generator
      #
      # @return [Hash]
      def _notification_arns
        _ref('AWS::NotificationARNs')
      end

      alias_method :notification_arns!, :_notification_arns

      # Account ID generator
      #
      # @return [Hash]
      def _account_id
        _ref('AWS::AccountId')
      end

      alias_method :account_id!, :_account_id

      # Stack ID generator
      #
      # @return [Hash]
      def _stack_id
        _ref('AWS::StackId')
      end

      alias_method :stack_id!, :_stack_id

      # Stack name generator
      #
      # @return [Hash]
      def _stack_name
        _ref('AWS::StackName')
      end

      alias_method :stack_name!, :_stack_name

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
        _set('DependsOn', [args].flatten.compact.map { |s| __attribute_key(s) })
      end

      alias_method :depends_on!, :_depends_on

      # Reference output value from nested stack
      #
      # @param stack_name [String, Symbol] logical resource name of stack
      # @apram output_name [String, Symbol] stack output name
      def _stack_output(stack_name, output_name)
        _cf_attr(_process_key(stack_name), "Outputs.#{__attribute_key(output_name)}")
      end

      alias_method :stack_output!, :_stack_output

      # @return [TrueClass, FalseClass] resource can be tagged
      def taggable?
        if self[:type]
          resource = _self._provider._resources.lookup(self[:type].gsub('::', '_').downcase)
          resource && resource[:properties].include?('Tags')
        else
          if _parent
            _parent.taggable?
          end
        end
      end

      # Set tags on a resource
      #
      # @param hash [Hash] Key/value pair tags
      # @return [SparkleStruct]
      def _tags(hash)
        __t_hashish(hash)
        _set('Tags',
             hash.map { |k, v|
          {'Key' => __attribute_key(k), 'Value' => v}
        })
      end

      alias_method :tags!, :_tags
    end
  end
end
