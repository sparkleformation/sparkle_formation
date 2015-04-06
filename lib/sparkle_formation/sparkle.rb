require 'sparkle_formation'

class SparkleFormation
  class Sparkle

    # Wrapper for evaluating sfn files to store within sparkle
    # container and remove global application
    def eval_wrapper
      klass = Class.new(BasicObject)
      klass.class_eval(<<-EOS
        def require(*args)
          ::Kernel.require *args
        end

        class SparkleFormation

          attr_accessor :sparkle_path

          class << self

            def part_data(data=nil)
              if(data)
                @data = data
              else
                @data
              end
            end

            def dynamic(name, args={}, &block)
              part_data[:dynamic].push(
                ::Smash.new(
                  :name => name,
                  :block => block,
                  :args => Smash[
                    args.map(&:to_a)
                  ],
                  :type => :dynamic
                )
              ).last
            end

            def build(&block)
              part_data[:component].push(
                ::Smash.new(
                  :block => block,
                  :type => :component
                )
              ).last
            end

            def component(name, &block)
              part_data[:component].push(
                ::Smash.new(
                  :name => name,
                  :block => block,
                  :type => :component
                )
              ).last
            end

            def dynamic_info(*args)
              Smash.new(:metadata => {}, :args => {})
            end

          end

          class Registry

            def self.register(name, &block)
              SparkleFormation.part_data[:registry].push(
                ::Smash.new(
                  :name => name,
                  :block => block,
                  :type => :registry
                )
              ).last
            end

          end
          SfnRegistry = Registry

        end
        ::Object.constants.each do |const|
          unless(self.const_defined?(const))
            next if const == :Config # prevent warning output
            self.const_set(const, ::Object.const_get(const))
          end
        end

        def part_data(arg)
          SparkleFormation.part_data(arg)
        end
        EOS
      )
      klass
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
      'registry',
      'dynamics'
    ]

    # Valid types
    TYPES = Smash.new(
      'component' => 'components',
      'registry' => 'registries',
      'dynamic' => 'dynamics',
      'template' => 'templates'
    )

    # @return [String] path to sparkle directories
    attr_reader :root
    # @return [Smash] raw part data
    attr_reader :raw_data
    attr_reader :wrapper

    # Create new sparkle instance
    #
    # @param args [Hash]
    # @option args [String] :root path to sparkle directories
    # @return [self]
    def initialize(args={})
      @root = args.fetch(:root, locate_root)
      @raw_data = Smash.new(
        :dynamic => [],
        :component => [],
        :registry => []
      )
      @wrapper = eval_wrapper.new
      wrapper.part_data(raw_data)
      load_parts!
    end

    def load_parts!
      memoize(:load_parts) do
        Dir.glob(File.join(root, "{#{DIRS.join(',')}}", '*.rb')).each do |file|
          wrapper.instance_eval(IO.read(file), file, 1)
        end
        raw_data.each do |key, items|
          items.each do |item|
            if(item[:name])
              send(TYPES[key])[item.delete(:name)] = item
            else
              path = item[:block].source_location.first.sub('.rb', '').split(File::SEPARATOR)
              type, name = path.slice(path.size - 2, 2)
              send(type)[name] = item
            end
          end
        end
      end
    end

    # @return [Smash<name:block>]
    def components
      memoize(:components) do
        Smash.new
      end
    end

    # @return [Smash<name:block>]
    def dynamics
      memoize(:dynamics) do
        Smash.new
      end
    end

    # @return [Smash<name:block>]
    def registries
      memoize(:registries) do
        Smash.new
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
            hash[name] = Smash.new(
              :path => path,
              :type => :template
            )
          end
        end
      end
    end

    # Request item from the store
    #
    # @param type [String, Symbol] item type (see: TYPES)
    # @param name [String, Symbol] name of item
    # @return [Smash] requested item
    # @raises [NameError, KeyError]
    def get(type, name)
      unless(TYPES.keys.include?(type.to_s))
        raise NameError.new "Invalid type requested (#{type})! Valid types: #{TYPES.join(', ')}"
      end
      result = send(TYPES[type])[name]
      unless(result)
        result = (send(TYPES[type]).detect{|k,v| v[:path] == name} || []).last
      end
      unless(result)
        klass = Error::NotFound.const_get(type.capitalize)
        raise klass.new("No #{type} registered with requested name (#{name})!", :name => name)
      end
      result
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
