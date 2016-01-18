require 'sparkle_formation'

class SparkleFormation

  # Provides template helper methods
  module SparkleAttribute

    # Heat specific helper implementations
    module Heat

      # Set customized struct behavior
      def self.included(klass)
        klass.const_set(:CAMEL_KEYS, false)
      end

      # get_attr generator
      #
      # @param [Object] pass through arguments
      # @return [Hash]
      def _get_attr(*args)
        __t_stringish(args.first)
        args = args.map do |thing|
          if(thing.is_a?(::Symbol))
            _process_key(thing, :force)
          else
            thing
          end
        end
        {'get_attr' => args}
      end
      alias_method :_attr, :_get_attr
      alias_method :attr!, :_get_attr

      # list_join generator
      #
      # @param args [Object]
      # @return [Hash]
      def _list_join(*args)
        options = args.detect{|i| i.is_a?(::Hash) && i[:options]} || {:options => {}}
        args.delete(options)
        unless(args.size == 1)
          args = [args]
        end
        {'list_join' => [options[:options][:delimiter] || '', *args]}
      end
      alias_method :_join, :_list_join
      alias_method :join!, :_list_join

      # get_file generator
      #
      # @param loc [String]
      # @return [Hash]
      def _get_file(loc)
        __t_string(loc)
        {'get_file' => loc}
      end
      alias_method :_file, :_get_file
      alias_method :file!, :_get_file

      # get_param generator
      #
      # @param args [Object]
      # @return [Hash]
      def _get_param(*args)
        __t_stringish(args.first)
        args = args.map do |thing|
          if(thing.is_a?(::Symbol))
            _process_key(thing, :force)
          else
            thing
          end
        end
        {'get_param' => args}
      end
      alias_method :_param, :_get_param
      alias_method :param!, :_get_param

      # get_resource generator
      #
      # @param r_name [String, Symbol]
      # @return [Hash]
      def _get_resource(r_name)
        __t_stringish(r_name)
        r_name = r_name.is_a?(Symbol) ? _process_key(r_name, :force) : r_name
        {'get_resource' => r_name}
      end
      alias_method :_resource, :_get_resource
      alias_method :resource!, :_get_resource

      def _digest(value, algorithm='sha512')
        __t_string(algorithm)
        {'digest' => [algorithm, value]}
      end
      alias_method :digest!, :_digest

      # resource_facade generator
      #
      # @param type [String, Symbol]
      # @return [Hash]
      def _resource_facade(type)
        __t_stringish(type)
        {'resource_facade' => type}
      end
      alias_method :_facade, :_resource_facade
      alias_method :facade!, :_resource_facade
      alias_method :resource_facade!, :_resource_facade

      # str_replace generator
      #
      # @param template [String]
      # @param params [Hash]
      # @return [Hash]
      def _str_replace(template, params)
        __t_stringish(template)
        __t_hashish(params)
        {'str_replace' => {'template' => template, 'params' => params}}
      end
      alias_method :str_replace!, :_str_replace

      # str_split generator
      #
      # @param splitter [String]
      # @param string [Object]
      # @param idx [Numeric]
      # @return [Hash]
      def _str_split(splitter, string, idx=nil)
        __t_string(splitter)
        {'str_split' => [splitter, string, idx].compact}
      end
      alias_method :_split, :_str_split
      alias_method :split!, :_str_split

      # map_merge generator
      #
      # @param args [Object]
      # @return [Hash]
      def _map_merge(*args)
        {'map_merge' => args}
      end
      alias_method :map_merge!, :_map_merge

      # @return [Hash]
      def _stack_id
        _get_param('OS::stack_id')
      end
      alias_method :stack_id!, :_stack_id

      # @return [Hash]
      def _stack_name
        _get_param('OS::stack_name')
      end
      alias_method :stack_name!, :_stack_name

      # @return [Hash]
      def _project_id
        _get_param('OS::project_id')
      end
      alias_method :project_id!, :_project_id

      # Resource dependency generator
      #
      # @param [Symbol, String, Array<Symbol, String>] resource names
      # @return [Array<String>]
      def _depends_on(*args)
        _set('depends_on', [args].flatten.compact.map{|s| _process_key(s, s.is_a?(::Symbol))})
      end
      alias_method :depends_on!, :_depends_on

      # Reference output value from nested stack
      #
      # @param stack_name [String, Symbol] logical resource name of stack
      # @param output_name [String, Symbol] stack output name
      # @return [Hash]
      def _stack_output(stack_name, output_name)
        _attr(
          _process_key(stack_name, stack_name.is_a?(::Symbol)),
          _process_key(output_name, output_name.is_a?(::Symbol))
        )
      end
      alias_method :stack_output!, :_stack_output

    end

  end
end
