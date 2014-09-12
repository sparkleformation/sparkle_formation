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
    def initialize(template_hash, args={})
      @original = template_hash.dup
      @template = MultiJson.load(MultiJson.dump(template_hash)) ## LOL: Lazy deep dup
      @translated = {}
      @logger = args.fetch(:logger, Logger.new($stdout))
      @parameters = args[:parameters] || {}
      @options = args[:options] || {}
    end

    # @return [Hash] parameters for template
    def parameters
      Hash[
        @original.fetch('Parameters', {}).map do |k,v|
          [k, v.fetch('Default', '')]
        end
      ].merge(@parameters)
    end

    # @return [Hash]
    def mappings
      @original.fetch('Mappings', {})
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
        if(respond_to?(translate_method))
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
      if(lookup.nil?)
        logger.warn "Failed to locate resource type: #{resource_args['Type']}"
        nil
      elsif(lookup == :delete)
        logger.warn "Deleting resource #{resource_name} due to configuration"
        nil
      else
        new_resource['Type'] = lookup[:name]
        if(resource_args['Properties'])
          new_resource['Properties'] = format_properties(
            :original_properties => resource_args['Properties'],
            :property_map => lookup[:properties],
            :new_resource => new_resource,
            :original_resource => resource_args
          )
        end
        if(lookup[:finalizer])
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
          if(new_key)
            if(new_key.is_a?(Symbol))
              unless(new_key == :delete)
                new_key, new_value = send(new_key, property_value,
                  :new_resource => args[:new_resource],
                  :new_properties => new_properties,
                  :original_resource => args[:original_resource]
                )
                new_properties[new_key] = new_value
              end
            else
              new_properties[new_key] = property_value
            end
          else
            logger.warn "Failed to locate property conversion for `#{property_name}` on resource type `#{args[:new_resource]['Type']}`. Passing directly."
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
          if(new_resource)
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
      if(obj.is_a?(Hash))
        name = obj['Ref']
        if(name)
          p_val = parameters[name.to_s]
          if(p_val)
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
        obj['Ref']
      else
        obj.to_s
      end
    end

    # Process object through dereferencer. This will dereference names
    # and apply functions if possible.
    #
    # @param obj [Object]
    # @return [Object]
    def dereference_processor(obj, funcs=[])
      obj = dereference(obj)
      case obj
      when Array
        obj = obj.map{|v| dereference_processor(v, funcs)}
      when Hash
        new_hash = {}
        obj.each do |k,v|
          new_hash[k] = dereference_processor(v, funcs)
        end
        obj = apply_function(new_hash, funcs)
      end
      obj
    end

    # Apply function if possible
    #
    # @param hash [Hash]
    # @param funcs [Array] allowed functions
    # @return [Hash]
    # @note also allows 'Ref' within funcs to provide mapping
    #   replacements using the REF_MAPPING constant
    def apply_function(hash, funcs=[])
      k,v = hash.first
      if(hash.size == 1 && (k.start_with?('Fn') || k == 'Ref') && (funcs.empty? || funcs.include?(k)))
        case k
        when 'Fn::Join'
          v.last.join(v.first)
        when 'Fn::FindInMap'
          mappings[v[0]][dereference(v[1])][v[2]]
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

  end
end
