require 'sparkle_formation'

class SparkleFormation
  class Sparkle

    include Bogo::Memoization

    # @return [String] path to sparkle directories
    attr_reader :root

    # Create new sparkle instance
    #
    # @param args [Hash]
    # @option args [String] :root path to sparkle directories
    # @return [self]
    def initialize(args={})
      @root = args.fetch(:root, Dir.pwd)
    end

    # @return [Smash<name:block>]
    def components
      memoize(:components) do

      end
    end

    # @return [Smash<name:block>]
    def dynamics
      memoize(:dynamics) do
      end
    end

    # @return [Smash<name:block>]
    def registries
      memoize(:registries) do
      end
    end

    # @return [Smash<name:SparkleFormation>]
    def templates
      memoize(:templates) do
      end
    end

  end
end
