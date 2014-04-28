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

    def translate_resources(value)
      translated['Resources'] = {}.tap do |modified_resources|
        value.each do |resource_name, resource_args|
          new_resource = {}
          lookup = map[:resources][resource_args['Type']]
          unless(lookup)
            logger.warn "Failed to locate resource type: #{resource_args['Type']}"
            next
          end
          new_resource['Type'] = lookup[:name]
          new_resource['Properties'] = {}.tap do |new_properties|
            resource_args['Properties'].each do |property_name, property_value|
              new_key = lookup[:properties][property_name]
              if(new_key)
                if(new_key.is_a?(Symbol))
                  new_key, new_value = send(new_key, property_value,
                    :new_resource => new_resource,
                    :new_properties => new_properties,
                    :original_resource => resource_args
                  )
                  new_properties[new_key] = new_value
                else
                  new_properties[new_key] = property_value
                end
              else
                logger.warn "Failed to locate property conversion for `#{property_name}` on resource type `#{resource_args['Type']}`. Passing directly."
                new_properties[snake(property_name)] = property_value
              end
            end
          end
          if(lookup[:finalizer])
            send(lookup[:finalizer], resource_name, new_resource, resource_args, modified_resources)
          end
          resource_finalizer(resource_name, new_resource, resource_args, modified_resources)
          modified_resources[resource_name] = new_resource
        end
      end
    end

  end
end
