require 'sparkle_formation'

class SparkleFormation
  # Provides a collection of sparkles
  # @todo add unmemoize behavior on collection modification to prevent
  # leak on long running processes with long lasting collections
  class SparkleCollection < Sparkle

    autoload :Rainbow, 'sparkle_formation/sparkle_collection/rainbow'

    # Create a new collection of sparkles
    #
    # @return [self]
    def initialize(*_)
      @root = nil
      @sparkles = []
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
    def add_sparkle(sparkle, precedence=:high)
      unless(sparkle.is_a?(Sparkle))
        raise TypeError.new "Expected type `SparkleFormation::Sparkle` but received `#{sparkle.class}`!"
      end
      if(precedence == :high)
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
      size == 0
    end

    # @return [Smash]
    def components
      memoize("components_#{checksum}") do
        Smash.new.tap do |hsh|
          sparkles.each do |sprkl|
            sprkl.components.each_pair do |c_name, c_value|
              hsh[c_name] ||= Rainbow.new(c_name, :component)
              hsh[c_name].add_layer(c_value)
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
            sprkl.dynamics.each_pair do |c_name, c_value|
              hsh[c_name] ||= Rainbow.new(c_name, :dynamic)
              hsh[c_name].add_layer(c_value)
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
            hsh.merge!(sprkl.registries)
          end
        end
      end
    end

    # @return [Smash]
    def templates
      memoize("templates_#{checksum}") do
        Smash.new.tap do |hsh|
          sparkles.each do |sprkl|
            sprkl.templates.each_pair do |c_name, c_value|
              hsh[c_name] ||= Rainbow.new(c_name, :template)
              hsh[c_name].add_layer(c_value)
            end
          end
        end
      end
    end

    # Request item from the store
    #
    # @param type [String, Symbol] item type (see: TYPES)
    # @param name [String, Symbol] name of item
    # @return [Smash] requested item
    # @raises [NameError, Error::NotFound]
    def get(type, name)
      type_name = Sparkle::TYPES[type.to_s]
      unless(type_name)
        raise ArgumentError.new "Unknown file type requested from collection `#{type}`"
      end
      result = nil
      error = nil
      result = send(type_name)[name]
      unless(result)
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
