require 'sparkle_formation'

class SparkleFormation
  class Sparkle

    # Wrapper for evaluating sfn files to store within sparkle
    # container and remove global application
    class EvalWrapper < BasicObject
      class SparkleFormation

        def self.dynamic(name, args={}, &block)
          ::Smash.new(
            :name => name,
            :block => block,
            :args => Smash[
              args.map(&:to_a)
            ],
            :type => :dynamic
          )
        end

        def self.build(&block)
          ::Smash.new(
            :block => block,
            :type => :component
          )
        end

        def self.component(name, &block)
          ::Smash.new(
            :name => name,
            :block => block,
            :type => :component
          )
        end

        class Registry

          def self.register(name, &block)
            ::Smash.new(
              :name => name,
              :block => block,
              :type => :registry
            )
          end

        end
        SfnRegistry = Registry

      end
    end

    include Bogo::Memoization

    # Valid directories from cwd to set as root
    VALID_ROOT_DIRS = [
      'sparkleformation',
      'sfn',
      'cloudformation',
      'cfn',
      '.'
    ]

    # Reserved directories
    DIRS = [
      'components',
      'registries',
      'dynamics'
    ]

    # @return [String] path to sparkle directories
    attr_reader :root

    # Create new sparkle instance
    #
    # @param args [Hash]
    # @option args [String] :root path to sparkle directories
    # @return [self]
    def initialize(args={})
      @root = args.fetch(:root, locate_root)
    end

    # @return [Smash<name:block>]
    def components
      memoize(:components) do
        Smash.new.tap do |hash|
          Dir.glob(File.join(root, 'components', '*.rb')) do |file|
            result = EvalWrapper.new.instance_eval(IO.read(file), file, 1)
            unless(result[:name])
              result[:name] = File.basename(file).sub('.rb', '')
            end
            hash[result.delete(:name)] = result
          end
        end
      end
    end

    # @return [Smash<name:block>]
    def dynamics
      memoize(:dynamics) do
        Smash.new.tap do |hash|
          Dir.glob(File.join(root, 'dynamics', '*.rb')) do |file|
            dyn = EvalWrapper.new.instance_eval(IO.read(file), file, 1)
            hash[dyn.delete(:name)] = dyn
          end
        end
      end
    end

    # @return [Smash<name:block>]
    def registries
      memoize(:registries) do
        Smash.new.tap do |hash|
          Dir.glob(File.join(root, 'registries', '*.rb')) do |file|
            reg = EvalWrapper.new.instance_eval(IO.read(file), file, 1)
            hash[reg.delete(:name)] = reg
          end
        end
      end
    end

    # @return [Smash<name:path>]
    def templates
      memoize(:templates) do
        Smash.new.tap do |hash|
          Dir.glob(File.join(root, '**', '**', '*.{json,rb}')) do |path|
            slim_path = path.sub("#{root}/", '')
            next if DIRS.include?(slim_path.split('/').first)
            name = slim_path.tr('/', '__')
            hash[name] = path
          end
        end
      end
    end

    private

    # Locate root directory. Defaults to current working directory if
    # valid sub directory is not located
    #
    # @return [String] root path
    def locate_root
      VALID_ROOT_DIRS.map do |part|
        path = File.expand_path(File.join(Dir.pwd, part))
        if(File.exists?(path))
          path
        end
      end.compact.first
    end

  end
end
