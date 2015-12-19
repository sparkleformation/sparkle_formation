require 'sparkle_formation'

class SparkleFormation
  # AWS resource helper
  class Aws
    class << self

      include SparkleFormation::Utils::AnimalStrings
      # @!parse include SparkleFormation::Utils::AnimalStrings

      # Register an AWS resource
      #
      # @param type [String] AWS CFN resource type
      # @param hash [Hash] metadata information
      # @return [TrueClass]
      def register(type, hash)
        unless(class_variable_defined?(:@@registry))
          @@registry = AttributeStruct.hashish.new
        end
        @@registry[type] = hash
        true
      end

      # Resource information
      #
      # @param identifier [String, Symbol] resource identifier
      # @param key [String, Symbol] specific data
      # @return [Hashish]
      def resource(identifier, key=nil)
        res = lookup(identifier)
        if(key && res)
          res[key.to_sym]
        else
          res
        end
      end

      # Register all discovered resources
      #
      # @param json_path_or_hash [String, Hashish] path to files or hash
      # @return [TrueClass]
      def load(json_path_or_hash)
        if(json_path_or_hash.is_a?(String))
          require 'multi_json'
          content = AttributeStruct.hashish.new(MultiJson.load(File.read(json)))
        else
          content = json_path_or_hash
        end
        content.each do |type, hash|
          register(type, hash)
        end
        true
      end

      # Load the builtin AWS resources
      #
      # @return [TrueClass]
      def load!
        require File.join(File.dirname(__FILE__), 'aws', 'cfn_resources.rb')
        load(AWS_RESOURCES)
        true
      end

      # Discover registry key via part searching
      #
      # @param key [String, Symbol]
      # @return [String, NilClass]
      def registry_key(key)
        key = key.to_s.tr('_', '')

        if AWS_RESOURCES_AMBIGUOUS.include?(key)
          warn "#{key} is ambiguous, please use a longer from"
        end

        @@registry.keys.detect do |ref|
          ref = ref.downcase
          snake_parts = ref.split('::')
          until(snake_parts.empty?)
            break if snake_parts.join('') == key
            snake_parts.shift
          end
          !snake_parts.empty?
        end
      end

      # Registry information for given type
      #
      # @param key [String, Symbol]
      # @return [Hashish, NilClass]
      def lookup(key)
        @@registry[registry_key(key)]
      end

      # @return [Hashish] currently loaded AWS registry
      def registry
        if(class_variable_defined?(:@@registry))
          @@registry
        else
          @@registry = AttributeStruct.hashish.new
        end
      end

    end
  end
end

# Shortcut helper constant
SfnAws = SparkleFormation::Aws
