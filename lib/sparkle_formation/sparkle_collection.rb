require 'sparkle_formation'

class SparkleFormation
  # Provides a collection of sparkles
  class SparkleCollection < Sparkle

    # Create a new collection of sparkles
    #
    # @return [self]
    def initialize(*_)
      @sparkles = []
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
        sparkles.push(sparkle).uniq!
      else
        sparkles.unshift(sparkle).uniq!
      end
      self
    end

    # Remove sparkle from collection
    #
    # @param sparkle [Sparkle]
    # @return [self]
    def remove_sparkle(sparkle)
      sparkles.delete(sparkle)
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
            hsh.merge!(sprkl.components)
          end
        end
      end
    end

    # @return [Smash]
    def dynamics
      memoize("dynamics_#{checksum}") do
        Smash.new.tap do |hsh|
          sparkles.each do |sprkl|
            hsh.merge!(sprkl.dynamics)
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
            hsh.merge!(sprkl.templates)
          end
        end
      end
    end

    protected

    # @return [Array<Sparkle>]
    attr_reader :sparkles

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
