require 'sparkle_formation'

class SparkleFormation
  # Resources helper
  class Resources

    autoload :Aws, 'sparkle_formation/resources/aws'
    autoload :Azure, 'sparkle_formation/resources/azure'
    autoload :Heat, 'sparkle_formation/resources/heat'
    autoload :Rackspace, 'sparkle_formation/resources/rackspace'

    # Characters to be removed from supplied key on matching
    RESOURCE_TYPE_TR = '_'
    # String to split for resource namespacing
    RESOURCE_TYPE_NAMESPACE_SPLITTER = '::'

    class << self

      include SparkleFormation::Utils::AnimalStrings
      # @!parse include SparkleFormation::Utils::AnimalStrings

      # @return [String] base registry key
      def base_key
        Bogo::Utility.snake(self.name.split('::').last) # rubocop:disable Style/RedundantSelf
      end

      # Register resource
      #
      # @param type [String] Orchestration resource type
      # @param hash [Hash] metadata information
      # @return [TrueClass]
      def register(type, hash)
        unless(class_variable_defined?(:@@registry))
          @@registry = AttributeStruct.hashish.new
        end
        @@registry[base_key] ||= AttributeStruct.hashish.new
        @@registry[base_key][type] = hash
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
          content = AttributeStruct.hashish.new(MultiJson.load(File.read(json_path_or_hash)))
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
        true
      end

      # Discover registry key via part searching
      #
      # @param key [String, Symbol]
      # @return [String, NilClass]
      def registry_key(key)
        o_key = key
        key = key.to_s.tr(self.const_get(:RESOURCE_TYPE_TR), '') # rubocop:disable Style/RedundantSelf
        snake_parts = nil
        result = @@registry[base_key].keys.detect do |ref|
          ref = ref.downcase
          snake_parts = ref.split(
            self.const_get(:RESOURCE_TYPE_NAMESPACE_SPLITTER) # rubocop:disable Style/RedundantSelf
          )
          until(snake_parts.empty?)
            break if snake_parts.join('') == key
            snake_parts.shift
          end
          !snake_parts.empty?
        end
        if(result)
          collisions = @@registry[base_key].keys.find_all do |ref|
            split_ref = ref.downcase.split(
              self.const_get(:RESOURCE_TYPE_NAMESPACE_SPLITTER) # rubocop:disable Style/RedundantSelf
            )
            ref = split_ref.slice(split_ref.size - snake_parts.size, split_ref.size).join('')
            key == ref
          end
          if(collisions.size > 1)
            raise ArgumentError.new 'Ambiguous dynamic name returned multiple matches! ' \
              "`#{o_key.inspect}` -> #{collisions.sort.join(', ')}"
          end
        end
        result
      end

      # Registry information for given type
      #
      # @param key [String, Symbol]
      # @return [Hashish, NilClass]
      def lookup(key)
        @@registry[base_key][registry_key(key)]
      end

      # @return [Hashish] currently loaded AWS registry
      def registry
        unless(class_variable_defined?(:@@registry))
          @@registry = AttributeStruct.hashish.new
        end
        @@registry[base_key]
      end

    end
  end
end
