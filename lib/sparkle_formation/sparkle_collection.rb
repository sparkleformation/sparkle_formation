require "sparkle_formation"

class SparkleFormation
  # Provides a collection of sparkles
  # @todo add unmemoize behavior on collection modification to prevent
  # leak on long running processes with long lasting collections
  class SparkleCollection < Sparkle
    autoload :Rainbow, "sparkle_formation/sparkle_collection/rainbow"

    # @return [Symbol] provider
    attr_accessor :provider

    # Create a new collection of sparkles
    #
    # @param args [Hash]
    # @option args [Symbol, String] :provider name of default provider
    # @return [self]
    def initialize(args = {})
      @provider = Bogo::Utility.snake(args.to_smash.fetch(:provider, "aws")).to_sym
      @root = nil
      @sparkles = []
    end

    # Apply collection settings to this collection
    #
    # @param collection [SparkleFormation::Collection]
    # @return [self]
    # @note will overwrite existing set packs
    def apply(collection)
      @root = collection.sparkles.last
      @sparkles = collection.sparkles.slice(0, collection.sparkles.length - 1) || []
      self
    end

    # Set the root sparkle which forces highest precedence
    #
    # @param sparkle [Sparkle]
    # @return [self]
    def set_root(sparkle)
      @root = sparkle
      self
    end

    # Add new sparkle to collection
    #
    # @param sparkle [Sparkle]
    # @return [self]
    def add_sparkle(sparkle, precedence = :high)
      unless sparkle.is_a?(Sparkle)
        raise TypeError.new "Expected type `SparkleFormation::Sparkle` but received `#{sparkle.class}`!"
      end
      if precedence == :high
        @sparkles.push(sparkle).uniq!
      else
        @sparkles.unshift(sparkle).uniq!
      end
      self
    end

    # Remove sparkle from collection
    #
    # @param sparkle [Sparkle]
    # @return [self]
    def remove_sparkle(sparkle)
      @sparkles.delete(sparkle)
      self
    end

    # @return [Sparkle, NilClass]
    def sparkle_at(idx)
      sparkles.at(idx)
    end

    # @return [Integer]
    def size
      sparkles.size
    end

    # @return [TrueClass, FalseClass]
    def empty?
      size == 0 # rubocop:disable Style/ZeroLengthPredicate
    end

    # @return [Smash]
    def components
      memoize("components_#{checksum}") do
        Smash.new.tap do |hsh|
          sparkles.each do |sprkl|
            sprkl.components.each_pair do |c_provider, c_info|
              c_info.each_pair do |c_name, c_value|
                unless hsh.get(c_provider, c_name)
                  hsh.set(c_provider, c_name, Rainbow.new(c_name, :component))
                end
                hsh.get(c_provider, c_name).add_layer(c_value)
              end
            end
          end
        end
      end
    end

    # @return [Smash]
    def dynamics
      memoize("dynamics_#{checksum}") do
        Smash.new.tap do |hsh|
          sparkles.each do |sprkl|
            sprkl.dynamics.each_pair do |c_provider, c_info|
              c_info.each_pair do |c_name, c_value|
                unless hsh.get(c_provider, c_name)
                  hsh.set(c_provider, c_name, Rainbow.new(c_name, :dynamic))
                end
                hsh.get(c_provider, c_name).add_layer(c_value)
              end
            end
          end
        end
      end
    end

    # @return [Smash]
    def registries
      memoize("registries_#{checksum}") do
        Smash.new.tap do |hsh|
          sparkles.each do |sprkl|
            hsh.deep_merge!(sprkl.registries)
          end
        end
      end
    end

    # @return [Smash]
    def templates
      memoize("templates_#{checksum}") do
        Smash.new.tap do |hsh|
          sparkles.each do |sprkl|
            sprkl.templates.each_pair do |c_provider, c_info|
              c_info.each_pair do |c_name, c_value|
                unless hsh.get(c_provider, c_name)
                  hsh.set(c_provider, c_name, Rainbow.new(c_name, :template))
                end
                hsh.get(c_provider, c_name).add_layer(c_value)
              end
            end
          end
        end
      end
    end

    # Request item from the store
    #
    # @param type [String, Symbol] item type (see: TYPES)
    # @param name [String, Symbol] name of item
    # @param target_provider [String, Symbol] restrict to provider
    # @return [Smash] requested item
    # @raise [NameError, Error::NotFound]
    def get(type, name, target_provider = nil)
      type_name = Sparkle::TYPES[type.to_s]
      unless type_name
        raise ArgumentError.new "Unknown file type requested from collection `#{type}`"
      end
      result = nil
      unless target_provider
        target_provider = provider
      end
      result = send(type_name).get(target_provider, name)
      if result.nil? && type_name == "templates"
        t_direct = sparkles.map do |pack|
          begin
            pack.get(:template, name, target_provider)
          rescue Error::NotFound
          end
        end.compact.last
        if t_direct
          result = send(type_name).get(target_provider, t_direct[:name])
        end
      end
      unless result
        error_klass = Error::NotFound.const_get(
          Bogo::Utility.camel(type)
        )
        raise error_klass.new(:name => name)
      end
      result
    end

    protected

    # @return [Array<Sparkle>]
    def sparkles
      (@sparkles + [@root]).compact
    end

    # @return [String] checksum of sparkles
    def checksum
      Smash.new.tap do |s|
        sparkles.each_with_index do |v, i|
          s[i.to_s] = v
        end
      end.checksum
    end
  end
end
