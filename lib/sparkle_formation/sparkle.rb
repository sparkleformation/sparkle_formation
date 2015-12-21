require 'sparkle_formation'

# Unicorns and rainbows
class SparkleFormation
  # Independent collection of SparkleFormation items
  class Sparkle

    class << self

      @@_pack_registry = Smash.new

      # Register a SparklePack for short name access
      #
      # @param name [String, Symbol] name of pack
      # @param path [String] path to pack
      # @return [Array<String:name, String:path>]
      def register!(name=nil, path=nil)
        unless(path)
          idx = caller.index do |item|
            item.end_with?("`register!'")
          end
          if(idx)
            file = caller[idx.next].split(':', 2).first
            path = File.join(File.dirname(file), 'sparkleformation')
            unless(File.directory?(path))
              path = nil
            end
            unless(name)
              name = File.basename(caller[idx.next].split(':', 2).first)
              name.sub!(File.extname(name), '')
            end
          end
        end
        unless(name)
          if(path)
            name = path.split(File::PATH_SEPARATOR)[-3].to_s
          end
        end
        unless(path)
          raise ArgumentError.new('No SparklePack path provided and failed to auto-detect!')
        end
        unless(name)
          raise ArgumentError.new('No SparklePack name provided and failed to auto-detect!')
        end
        @@_pack_registry[name] = path
        [name, path]
      end

      # Return the path to the SparkePack registered with the given
      # name
      #
      # @param name [String, Symbol] name of pack
      # @return [String] path
      def path(name)
        if(@@_pack_registry[name])
          @@_pack_registry[name]
        else
          raise KeyError.new "No pack registered with requested name: #{name}!"
        end
      end

    end

    # Wrapper for evaluating sfn files to store within sparkle
    # container and remove global application
    # rubocop:disable Metrics/MethodLength
    def eval_wrapper
      klass = Class.new(BasicObject)
      klass.class_eval(<<-EOS
        def require(*args)
          ::Kernel.require *args
        end

        class SparkleFormation

          attr_accessor :sparkle_path

          class << self

            def insert(*args, &block)
              ::SparkleFormation.insert(*args, &block)
            end

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

          def initialize(*args)
            SparkleFormation.part_data[:template].push(
              ::Smash.new(
                :name => args.first
              )
            )
            raise TypeError
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
        end

        SfnRegistry = SparkleFormation::Registry

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

    # Create new sparkle instance
    #
    # @param args [Hash]
    # @option args [String] :root path to sparkle directories
    # @option args [String, Symbol] :name registered pack name
    # @return [self]
    def initialize(args={})
      if(args[:name])
        @root = self.class.path(args[:name])
      else
        @root = args.fetch(:root, locate_root)
      end
      unless(File.directory?(@root))
        raise Errno::ENOENT.new("No such directory - #{@root}")
      end
      @raw_data = Smash.new(
        :dynamic => [],
        :component => [],
        :registry => [],
        :template => []
      )
      @wrapper = eval_wrapper.new
      wrapper.part_data(raw_data)
      load_parts!
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
        Smash.new
      end
    end

    # Request item from the store
    #
    # @param type [String, Symbol] item type (see: TYPES)
    # @param name [String, Symbol] name of item
    # @return [Smash] requested item
    # @raises [NameError, Error::NotFound]
    def get(type, name)
      unless(TYPES.keys.include?(type.to_s))
        raise NameError.new "Invalid type requested (#{type})! Valid types: #{TYPES.keys.join(', ')}"
      end
      result = send(TYPES[type])[name]
      if(result.nil? && TYPES[type] == 'templates')
        result = (
          send(TYPES[type]).detect{|_, v|
            name = name.to_s
            short_name = v[:path].sub(%r{#{Regexp.escape(root)}/?}, '')
            v[:path] == name ||
            short_name == name ||
            short_name.sub('.rb', '').gsub(File::SEPARATOR, '__').tr('-', '_') == name ||
            v[:path].end_with?(name)
          } || []
        ).last
      end
      unless(result)
        klass = Error::NotFound.const_get(type.capitalize)
        raise klass.new("No #{type} registered with requested name (#{name})!", :name => name)
      end
      result
    end

    # @return [String]
    def inspect
      "<SparkleFormation::Sparkle [root: #{root.inspect}]>"
    end

    private

    attr_reader :wrapper

    # Locate root directory. Defaults to current working directory if
    # valid sub directory is not located
    #
    # @return [String] root path
    def locate_root
      VALID_ROOT_DIRS.map do |part|
        path = File.expand_path(File.join(Dir.pwd, part))
        if(File.exist?(path))
          path
        end
      end.compact.first
    end

    # Load all sparkle parts
    def load_parts!
      memoize(:load_parts) do
        Dir.glob(File.join(root, '**', '**', '*.{json,rb}')).each do |file|
          slim_path = file.sub("#{root}/", '')
          if(file.end_with?('.rb'))
            begin
              wrapper.instance_eval(IO.read(file), file, 1)
            rescue TypeError
            end
          end
          if(file.end_with?('.json') || raw_data[:template].first)
            data = raw_data[:template].pop || Smash.new
            unless(data[:name])
              data[:name] = slim_path.tr('/', '__').sub(/\.(rb|json)$/, '')
            end
            if(templates[data[:name]])
              raise KeyError.new "Template name is already in use within pack! (`#{data[:name]}`)"
            end
            templates[data[:name]] = data.merge(
              :type => :template,
              :path => file,
              :serialized => !file.end_with?('.rb')
            )
          end
        end
        raw_data.each do |key, items|
          items.each do |item|
            if(item[:name])
              collection = send(TYPES[key])
              name = item.delete(:name)
            else
              path = item[:block].source_location.first.sub('.rb', '').split(File::SEPARATOR)
              type, name = path.slice(path.size - 2, 2)
              collection = send(type)
            end
            if(collection[name])
              raise KeyError.new "#{key.capitalize} name is already in use within pack! (`#{name}`)"
            end
            collection[name] = item
          end
        end
      end
    end

  end
  # Alias for interfacing naming
  SparklePack = Sparkle
end
