require 'sparkle_formation'

class SparkleFormation
  class Translation

    autoload :Heat, 'sparkle_formation/translation/heat'

    include SparkleFormation::Utils::AnimalStrings
    include SparkleFormation::SparkleAttribute

    attr_reader :original, :translated, :template

    def initialize(template_hash)
      @original = template_hash.dup
      @template = MultiJson.load(MultiJson.dump(template_hash)) ## LOL: Lazy deep dup
      @translated = {}
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
            puts "FAILED TO FIND TYPE: #{resource_args['Type']}"
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
                puts "OHAY, NOT FOUND: #{property_name}"
              end
            end
          end
          if(lookup[:finalizer])
            send(lookup[:finalizer], resource_name, new_resource, resource_args)
          end
          modified_resources[resource_name] = new_resource
        end
      end
    end

    def cloud_init(resource_name, ref_prefix = 'AWS')
      pkgs = 'python-argparse cloud-init python-psutil python-pip heat-cfntools'
      _cf_join(
        "#!/bin/bash\n",
        "ls /etc/redhat-release\n",
        "if [ $? -eq 0 ] then\n",
        "  yum install -y -q #{pkgs}\n",
        "else\n",
        "  apt-get install -q -y #{pkgs}\n",
        "fi\n",
        "cfn-create-aws-symlinks\n",
        "cfn-init -v --region ",
        _cf_ref("#{ref_prefix}::Region"),
        " -s ",
        _cf_ref("#{ref_prefix}::StackName"),
        " -r #{resource_name}\n"
      )
    end

  end
end
