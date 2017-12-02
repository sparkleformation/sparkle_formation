require 'sparkle_formation'

class SparkleFormation
  # Internal template composition
  class Composition

    # Component item of composition
    Component = Struct.new('Component', :origin, :key, :block) do
      def key
        self[:key].to_s
      end
    end

    # Override item of composition
    Override = Struct.new('Override', :origin, :args, :block)

    # @return [SparkleFormation] owner of composition
    attr_reader :origin

    # Create a new composition
    #
    # @param origin [SparkleFormation] owner of composition
    # @param args [Hash]
    # @option args [Array<Component>] :components seed components for composition
    # @option args [Array<Override>] :overrides seed overrides for composition
    # @return [self]
    def initialize(origin, args = {})
      unless origin.is_a?(SparkleFormation)
        raise TypeError.new 'Composition requires `SparkleFormation` instance as origin. ' \
                            "Received origin type `#{origin.class}`."
      end
      @origin = origin
      @components_list = []
      @overrides_list = []
      seed_value(args[:overrides], Override).each do |item|
        add_override(item)
      end
      seed_value(args[:components], [Component, Override]).each do |item|
        add_component(item)
      end
    end

    # @return [Array<Component, Override>]
    def components
      @components_list.dup.freeze
    end

    # @return [Array<Override>]
    def overrides
      @overrides_list.dup.freeze
    end

    # Provides the full list of items in order
    #
    # @return [Array<Component, Override>]
    def composite
      [components + overrides].flatten.freeze
    end

    # Add an existing component
    #
    # @param item [Component, Override]
    # @param location [Symbol] :prepend or :append (defaults to :append)
    # @return [self]
    def add_component(item, location = :append)
      unless item.is_a?(Component) || item.is_a?(Override)
        raise TypeError.new("Expecting `Component` or `Override` but received `#{item.class}`")
      end
      if item.respond_to?(:key) && component_keys.include?(item.key)
        # do nothing
      else
        case location
        when :append
          components_list.push(item)
        when :prepend
          components_list.unshift(item)
        else
          raise ArgumentError.new 'Unknown addition location provided. Valid: `:append, :prepend`. ' \
                                  "Received: `#{location.inspect}`"
        end
      end
      self
    end

    # Add an existing override
    #
    # @param item [Override]
    # @param location [Symbol] :prepend or :append (defaults to :append)
    # @return [self]
    def add_override(item, location = :append)
      unless item.is_a?(Override)
        raise TypeError.new("Expecting `Override` but received `#{item.class}`")
      end
      case location
      when :append
        overrides_list.push(item)
      when :prepend
        overrides_list.unshift(item)
      else
        raise ArgumentError.new 'Unknown addition location provided. Valid: ' \
                                "`:append, :prepend`. Received: `#{location.inspect}`"
      end
      self
    end

    # Add a new component
    #
    # @param key [Symbol, String] component identifier
    # @param location [Symbol] :prepend or :append (defaults to :append)
    # @yield component block (optional)
    # @return [self]
    def new_component(key, location = :append, &block)
      comp = Component.new(origin, key, block)
      add_component(comp, location)
      self
    end

    # Add a new override
    #
    # @param args [Hash] local state provided to override
    # @param location [Symbol] :prepend or :append (defaults to :append)
    # @yield override block
    # @return [self]
    def new_override(args = {}, location = :append, &block)
      if args.is_a?(Symbol)
        location = args
        args = {}
      end
      ovr = Override.new(origin, args, block)
      add_override(ovr, location)
      self
    end

    # Iterate full composition
    #
    # @yield block to execute each item
    # @yieldparam [Component, Override]
    # @return [self]
    def each
      if block_given?
        composite.each do |item|
          yield item
        end
      end
      self
    end

    protected

    # @return [Array<String, Symbol>]
    def component_keys
      components.map do |item|
        item.respond_to?(:key) ? item.key : nil
      end.compact
    end

    # If items list provided, validate types and return
    # copy of list. If no list provided, return new list.
    #
    # @param items [Array]
    # @param type [Class]
    # @return [Array]
    def seed_value(items, type)
      type = [type].flatten.compact
      if items
        items.each do |item|
          valid_item = type.any? do |klass|
            item.is_a?(klass)
          end
          unless valid_item
            raise TypeError.new "Invalid type encountered within collection `#{item.class}`. " \
                                "Expected `#{type.map(&:to_s).join('`, `')}`."
          end
        end
        items.dup
      else
        []
      end
    end

    attr_reader :components_list, :overrides_list
  end
end
