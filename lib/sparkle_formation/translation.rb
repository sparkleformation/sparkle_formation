require 'sparkle_formation'
require 'multi_json'

class SparkleFormation
  class Translation

    autoload :Heat, 'sparkle_formation/translation/heat'
    autoload :Rackspace, 'sparkle_formation/translation/rackspace'

    include SparkleFormation::Utils::AnimalStrings
    include SparkleFormation::SparkleAttribute

    attr_reader :original, :translated, :template, :logger

    def initialize(template_hash, logger=nil)
      @original = template_hash.dup
      @template = MultiJson.load(MultiJson.dump(template_hash)) ## LOL: Lazy deep dup
      @translated = {}
      if(logger)
        @logger = logger
      else
        require 'logger'
        @logger = Logger.new($stdout)
      end
    end

    def map
      self.class.const_get(:MAP)
    end

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

    def translate_default(key, value)
      translated[key] = value
    end

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

    def translate_resources(value)
      translated['Resources'] = {}
      translated['Resources'].tap do |modified_resources|
        value.each do |resource_name, resource_args|
          modified_resources[resource_name] = resource_translation(resource_name, resource_args)
        end
      end
    end

    def decode_resource_name(obj)
      case obj
      when String
        obj
      when Hash
        obj['Ref']
      else
        obj.to_s
      end
    end

    def default_key_format(key)
      key
    end

  end
end
