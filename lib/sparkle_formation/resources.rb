require 'sparkle_formation'

class SparkleFormation
  # Resources helper
  class Resources

    autoload :Aws, 'sparkle_formation/resources/aws'
    autoload :Azure, 'sparkle_formation/resources/azure'
    autoload :Google, 'sparkle_formation/resources/google'
    autoload :Heat, 'sparkle_formation/resources/heat'
    autoload :Rackspace, 'sparkle_formation/resources/rackspace'
    autoload :Terraform, 'sparkle_formation/resources/terraform'

    # Characters to be removed from supplied key on matching
    RESOURCE_TYPE_TR = '_'
    # String to split for resource namespacing
    RESOURCE_TYPE_NAMESPACE_SPLITTER = '::'
    # Property update conditionals
    # Format: Smash.new(RESOURCE_TYPE => {PROPERTY_NAME => [PropertyConditional]})
    PROPERTY_UPDATE_CONDITIONALS = Smash.new

    # Defines a resource type
    #
    # @param name [String] name of resource type
    # @param properties [Array<Property>] resource properties
    # @param raw [Hash] raw resource information
    Resource = Struct.new(:name, :properties, :raw) do
      # Get property by name
      #
      # @param name [String] name of property
      # @return [Property, NilClass]
      def property(name)
        properties.detect do |prop|
          prop.name == name
        end
      end
    end

    # Defines conditional result for cause of property update
    #
    # @param update_causes [String] one of: 'replacement', 'interrupt', 'unknown', 'none'
    # @param conditional [Proc, TrueClass] condition logic. passed two values: Hash of resource "final" state and
    #   Hash of resource "original" state
    UpdateCausesConditional = Struct.new(:update_causes, :conditional)

    # Defines a resource property
    #
    # @param name [String] property name
    # @param description [String] property descrition
    # @param type [String] property data type
    # @param required [TrueClass, FalseClass] property is required
    # @param update_causes [String] one of: 'replacement', 'interrupt', 'unknown', 'none'
    # @param conditionals [Array<UpdateCausesConditional>] conditionals for update causes
    Property = Struct.new(:name, :description, :type, :required, :update_causes, :conditionals) do
      # Determine result of property update
      #
      # @param final_resource [Hash] desired resource structure containing this property
      # @return ['replacement', 'interrupt', 'unknown', 'none']
      def update_causes(final_resource=nil, original_resource=nil)
        if(conditionals && final_resource)
          final_resource = final_resource.to_smash
          original_resource = original_resource.to_smash
          result = conditionals.detect do |p_cond|
            p_cond.conditional == true || p_cond.conditional.call(final_resource, original_resource)
          end
          if(result)
            result.update_causes
          else
            'unknown'
          end
        else
          self[:update_causes]
        end
      end
    end

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
        if(registry[key])
          result = key
        else
          o_key = key
          key = key.to_s.tr(self.const_get(:RESOURCE_TYPE_TR), '') # rubocop:disable Style/RedundantSelf
          snake_parts = nil
          result = @@registry[base_key].keys.detect do |ref|
            ref = ref.downcase
            snake_parts = ref.split(resource_type_splitter)
            until(snake_parts.empty?)
              break if snake_parts.join('') == key
              snake_parts.shift
            end
            !snake_parts.empty?
          end
          if(result)
            collisions = @@registry[base_key].keys.find_all do |ref|
              split_ref = ref.downcase.split(resource_type_splitter)
              ref = split_ref.slice(split_ref.size - snake_parts.size, split_ref.size).join('')
              key == ref
            end
            if(collisions.size > 1)
              raise ArgumentError.new 'Ambiguous dynamic name returned multiple matches! ' \
                "`#{o_key.inspect}` -> #{collisions.sort.join(', ')}"
            end
          end
        end
        result
      end

      # @return [Regexp] value for resource splitting
      # rubocop:disable Style/RedundantSelf
      def resource_type_splitter
        Regexp.new(
          [self.const_get(:RESOURCE_TYPE_NAMESPACE_SPLITTER)].flatten.compact.map{|value|
            Regexp.escape(value)
          }.join('|')
        )
      end

      # Registry information for given type
      #
      # @param key [String, Symbol]
      # @return [Hashish, NilClass]
      def lookup(key)
        @@registry[base_key][key] || @@registry[base_key][registry_key(key)]
      end

      # @return [Hashish] currently loaded AWS registry
      def registry
        unless(class_variable_defined?(:@@registry))
          @@registry = AttributeStruct.hashish.new
        end
        @@registry[base_key]
      end

      # Simple hook method to allow resource customization if the specific
      # provider requires/offers extra setup
      #
      # @param struct [SparkleStruct]
      # @param lookup_key [String]
      # @return [SparkleStruct]
      def resource_customizer(struct, lookup_key)
        struct
      end

      # Information about specific resource type
      #
      # @param type [String] resource type
      # @return [Resource]
      def resource_lookup(type)
        result = registry[type]
        if(result)
          properties = result.fetch('full_properties', {}).map do |p_name, p_info|
            Property.new(p_name,
              p_info[:description],
              p_info[:type],
              p_info[:required],
              p_info[:update_causes],
              self.const_get(:PROPERTY_UPDATE_CONDITIONALS).get(type, p_name)
            )
          end
          Resource.new(type, properties, result)
        else
          raise KeyError.new "Failed to locate requested resource type: `#{type}`"
        end
      end

    end
  end
end
