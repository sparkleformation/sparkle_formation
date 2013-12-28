require 'attribute_struct'
require 'sparkle_formation/utils'

class SparkleFormation
  class Aws
    class << self

      include SparkleFormation::Utils::AnimalStrings

      # type:: AWS CFN resource type
      # hash:: Hash of information
      # Register an AWS resource
      def register(type, hash)
        unless(class_variable_defined?(:@@registry))
          @@registry = AttributeStruct.hashish.new
        end
        @@registry[type] = hash
      end

      # identifier:: resource identifier
      # key:: key of value to return from information hash
      # Return the associated aws resource information
      def resource(identifier, key=nil)
        res = lookup(identifier)
        if(key && res)
          res[key.to_sym]
        else
          res
        end
      end

      # json_path_or_hash:: Path to JSON file or Hash instance of resources
      # Register all discovered resources
      def load(json_path_or_hash)
        if(json_path_or_hash.is_a?(String))
          require 'json'
          content = AttributeStruct.hashish.new(JSON.load(File.read(json)))
        else
          content = json_path_or_hash
        end
        content.each do |type, hash|
          register(type, hash)
        end
        true
      end

      # Load the builtin AWS resources
      def load!
        require File.join(File.dirname(__FILE__), 'aws', 'cfn_resources.rb')
        load(AWS_RESOURCES)
      end

      # key:: string or symbol
      # Return matching registry key. Uses snaked resource type for
      # matching and will attempt all parts for match
      def registry_key(key)
        key = key.to_s
        @@registry.keys.detect do |ref|
          ref = ref.tr('::', '_')
          snake_ref = snake(ref).to_s.gsub('__', '_')
          snake_parts = snake_ref.split('_')
          until(snake_parts.empty?)
            break if snake_parts.join('_') == key
            snake_parts.shift
          end
          !snake_parts.empty?
        end
      end

      # key:: string or symbol
      # Returns resource information of type discovered via matching
      # using #registry_key
      def lookup(key)
        @@registry[registry_key(key)]
      end

    end
  end
end

SfnAws = SparkleFormation::Aws
