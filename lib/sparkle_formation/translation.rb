require 'sparkle_formation'
require 'multi_json'
require 'logger'

class SparkleFormation
  # Translator
  class Translation
    autoload :Heat, 'sparkle_formation/translation/heat'
    autoload :Rackspace, 'sparkle_formation/translation/rackspace'

    include SparkleFormation::Utils::AnimalStrings
    include SparkleFormation::SparkleAttribute

    # @return [Hash] original template
    attr_reader :original
    # @return [Hash] current translation
    attr_reader :translated
    # @return [Hash] duplicated template (full deep copy)
    attr_reader :template
    # @return [Logger] current logger
    attr_reader :logger
    # @return [Hash] extra options (generally used by translation implementations)
    attr_reader :options

    # Create new instance
    #
    # @param template_hash [Hash] stack template
    # @param args [Hash]
    # @option args [Logger] :logger custom logger
    # @option args [Hash] :parameters parameters for stack creation
    # @option args [Hash] :options options for translation
    def initialize(template_hash, args = {})
      @original = template_hash.dup
      @template = template_hash.to_smash
      @translated = {}
      @logger = args.fetch(:logger, Logger.new($stdout))
      @parameters = args[:parameters] || {}
      @options = args[:options] || {}
    end

    # @return [Hash] parameters for template
    def parameters
      Hash[
        @original.fetch('Parameters', {}).map do |k, v|
          [k, v.fetch('Default', '')]
        end
      ].merge(@parameters)
    end

    # @return [Hash] mappings for template
    def mappings
      @original.fetch('Mappings', {})
    end

    # @return [Hash] resources for template
    def resources
      @original.fetch('Resources', {})
    end

    # @return [Hash] outputs for template
    def outputs
      @original.fetch('Outputs', {})
    end

    # @return [Hash] resource mapping
    def map
      self.class.const_get(:MAP)
    end

    # Translate stack definition
    #
    # @return [TrueClass]
    def translate!
      template.each do |key, value|
        translate_method = "translate_#{snake(key.to_s)}".to_sym
        if respond_to?(translate_method)
          send(translate_method, value)
        else
          translate_default(key, value)
        end
      end
      true
    end

    # Default translation action if no mapping is provided
    #
    # @return [Object] value
    def translate_default(key, value)
      translated[key] = value
    end

    # Translate resource
    #
    # @param resource_name [String]
    # @param resource_args [Hash]
    # @return [Hash, NilClass] new resource Hash or nil
    def resource_translation(resource_name, resource_args)
      new_resource = {}
      lookup = map[:resources][resource_args['Type']]
      if lookup.nil?
        logger.warn "Failed to locate resource type: #{resource_args['Type']}"
        nil
      elsif lookup == :delete
        logger.warn "Deleting resource #{resource_name} due to configuration"
        nil
      else
        new_resource['Type'] = lookup[:name]
        if resource_args['Properties']
          new_resource['Properties'] = format_properties(
            :original_properties => resource_args['Properties'],
            :property_map => lookup[:properties],
            :new_resource => new_resource,
            :original_resource => resource_args,
          )
        end
        if lookup[:finalizer]
          send(lookup[:finalizer], resource_name, new_resource, resource_args)
        end
        resource_finalizer(resource_name, new_resource, resource_args)
        new_resource
      end
    end

    # Format the properties of the new resource
    #
    # @param args [Hash]
    # @option args [Hash] :original_properties
    # @option args [Hash] :property_map
    # @option args [Hash] :new_resource
    # @option args [Hash] :original_resource
    # @return [Hash]
    def format_properties(args)
      args[:new_resource]['Properties'] = {}.tap do |new_properties|
        args[:original_properties].each do |property_name, property_value|
          new_key = args[:property_map][property_name]
          if new_key
            if new_key.is_a?(Symbol)
              unless new_key == :delete
                new_key, new_value = send(new_key, property_value,
                                          :new_resource => args[:new_resource],
                                          :new_properties => new_properties,
                                          :original_resource => args[:original_resource])
                new_properties[new_key] = new_value
              end
            else
              new_properties[new_key] = property_value
            end
          else
            logger.warn "Failed to locate property conversion for `#{property_name}` on " \
                        "resource type `#{args[:new_resource]['Type']}`. Passing directly."
            new_properties[default_key_format(property_name)] = property_value
          end
        end
      end
    end

    # Translate provided resources
    #
    # @param value [Hash] resources hash
    # @return [Hash]
    def translate_resources(value)
      translated['Resources'] = {}
      translated['Resources'].tap do |modified_resources|
        value.each do |resource_name, resource_args|
          new_resource = resource_translation(resource_name, resource_args)
          if new_resource
            modified_resources[resource_name] = new_resource
          end
        end
      end
    end

    # Default formatting for keys
    #
    # @param key [String, Symbol]
    # @return [String, Symbol]
    def default_key_format(key)
      key
    end

    # Attempt to dereference name
    #
    # @param obj [Object]
    # @return [Object]
    def dereference(obj)
      result = obj
      if obj.is_a?(Hash)
        name = obj['Ref'] || obj['get_param']
        if name
          p_val = parameters[name.to_s]
          if p_val
            result = p_val
          end
        end
      end
      result
    end

    # Provide name of resource
    #
    # @param obj [Object]
    # @return [String] name
    def resource_name(obj)
      case obj
      when Hash
        obj['Ref'] || obj['get_resource']
      else
        obj.to_s
      end
    end

    # Process object through dereferencer. This will dereference names
    # and apply functions if possible.
    #
    # @param obj [Object]
    # @return [Object]
    def dereference_processor(obj, funcs = [])
      case obj
      when Array
        obj = obj.map { |v| dereference_processor(v, funcs) }
      when Hash
        new_hash = {}
        obj.each do |k, v|
          new_hash[k] = dereference_processor(v, funcs)
        end
        obj = apply_function(new_hash, funcs)
      end
      obj
    end

    # Process object through name mapping
    #
    # @param obj [Object]
    # @param names [Array<Symbol>] enable renaming (:ref, :fn)
    # @return [Object]
    def rename_processor(obj, names = [])
      case obj
      when Array
        obj = obj.map { |v| rename_processor(v, names) }
      when Hash
        new_hash = {}
        obj.each do |k, v|
          new_hash[k] = rename_processor(v, names)
        end
        obj = apply_rename(new_hash, names)
      end
      obj
    end

    # Apply function if possible
    #
    # @param hash [Hash]
    # @param names [Array<Symbol>] enable renaming (:ref, :fn)
    # @return [Hash]
    # @note remapping references to constants:
    #   REF_MAPPING for Ref maps
    #   FN_MAPPING for Fn maps
    def apply_rename(hash, names = [])
      k, v = hash.first
      if hash.size == 1
        if k.start_with?('Fn::')
          {self.class.const_get(:FN_MAPPING).fetch(k, k) => attr_mapping(*v)}
        elsif k == 'Ref'
          if resources.key?(v)
            {'get_resource' => v}
          else
            {'get_param' => self.class.const_get(:REF_MAPPING).fetch(v, v)}
          end
        else
          hash
        end
      else
        hash
      end
    end

    # Apply `GetAttr` mapping if available
    #
    # @param resource_name [String]
    # @param value [String]
    # @return [Array]
    def attr_mapping(resource_name, value)
      result = [resource_name, value]
      if r = resources[resource_name]
        attr_map = self.class.const_get(:FN_ATT_MAPPING)
        if attr_map[r['Type']] && replacement = attr_map[r['Type']][value]
          result = [resource_name, *[replacement].flatten.compact]
        end
      end
      result
    end

    # Apply function if possible
    #
    # @param hash [Hash]
    # @param funcs [Array] allowed functions
    # @return [Hash]
    # @note also allows 'Ref' within funcs to provide mapping
    #   replacements using the REF_MAPPING constant
    def apply_function(hash, funcs = [])
      k, v = hash.first
      if hash.size == 1 && (k.start_with?('Fn') || k == 'Ref') && (funcs.empty? || funcs.include?(k))
        case k
        when 'Fn::Join'
          v.last.join(v.first)
        when 'Fn::FindInMap'
          map_holder = mappings[v[0]]
          if map_holder
            map_item = map_holder[dereference(v[1])]
            if map_item
              map_item[v[2]]
            else
              raise "Failed to find mapping item! (#{v[0]} -> #{v[1]})"
            end
          else
            raise "Failed to find mapping! (#{v[0]})"
          end
        when 'Ref'
          {'Ref' => self.class.const_get(:REF_MAPPING).fetch(v, v)}
        else
          hash
        end
      else
        hash
      end
    end

    # @return [Hash] mapping for pseudo-parameters
    REF_MAPPING = {}

    # @return [Hash] mapping for intrinsic functions
    FN_MAPPING = {}
  end
end
