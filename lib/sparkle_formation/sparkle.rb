require 'sparkle_formation'

# Unicorns and rainbows
class SparkleFormation
  # Independent collection of SparkleFormation items
  class Sparkle

    # Evaluation context wrapper for loading SparkleFormation files
    class EvalWrapper < BasicObject

      # @!visibility private
      def require(*args)
        ::Kernel.require(*args)
      end

      # @!visibility private
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
                :args => ::Smash[
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

          def component(name, args={}, &block)
            part_data[:component].push(
              ::Smash.new(
                :name => name,
                :block => block,
                :args => ::Smash[
                  args.map(&:to_a)
                ],
                :type => :component
              )
            ).last
          end

          def dynamic_info(*args)
            ::Smash.new(:metadata => {}, :args => {})
          end

        end

        def initialize(*args)
          opts = args.detect{|a| a.is_a?(Hash)} || {}
          SparkleFormation.part_data[:template].push(
            ::Smash.new(
              :name => args.first,
              :args => opts
            )
          )
          raise ::TypeError
        end

        # @!visibility private
        class Registry

          def self.register(name, args={}, &block)
            SparkleFormation.part_data[:registry].push(
              ::Smash.new(
                :name => name,
                :block => block,
                :args => ::Smash[
                  args.map(&:to_a)
                ],
                :type => :registry
              )
            ).last
          end

        end
      end

      # @!visibility private
      SfnRegistry = SparkleFormation::Registry

      # NOTE: Enable access to top level constants but do not
      # include deprecated constants to prevent warning outputs
      ::Object.constants.each do |const|
        unless(self.const_defined?(const)) # rubocop:disable Style/RedundantSelf
          deprecated_constants = %i[Bignum Config FALSE Fixnum NIL TimeoutError TRUE]
          next if deprecated_constants.include? const
          self.const_set(const, ::Object.const_get(const)) # rubocop:disable Style/RedundantSelf
        end
      end

      # @!visibility private
      def part_data(arg)
        SparkleFormation.part_data(arg)
      end

    end

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
          idx = idx ? idx.next : 0
          # Trim from the end to determine path allowing windows paths
          # to not be improperly truncated
          file = caller[idx].split(':').reverse.drop(2).reverse.join(':')
          path = File.join(File.dirname(file), 'sparkleformation')
          unless(File.directory?(path))
            path = nil
          end
          unless(name)
            name = File.basename(file)
            name.sub!(File.extname(name), '')
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
    # container
    def eval_wrapper
      Class.new(EvalWrapper)
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
    # @return [Symbol] provider
    attr_accessor :provider

    # Create new sparkle instance
    #
    # @param args [Hash]
    # @option args [String] :root path to sparkle directories
    # @option args [String, Symbol] :name registered pack name
    # @option args [String, Symbol] :provider name of default provider
    # @return [self]
    def initialize(args={})
      if(args[:name])
        @root = self.class.path(args[:name])
      else
        @root = args.fetch(:root, locate_root)
      end
      if(@root != :none && !File.directory?(@root))
        raise Errno::ENOENT.new("No such directory - #{@root}")
      end
      @raw_data = Smash.new(
        :dynamic => [],
        :component => [],
        :registry => [],
        :template => []
      )
      @provider = Bogo::Utility.snake(args.fetch(:provider, 'aws').to_s).to_sym
      @wrapper = eval_wrapper.new
      wrapper.part_data(raw_data)
      load_parts! unless @root == :none
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
    # @param target_provider [String, Symbol] restrict to provider
    # @return [Smash] requested item
    # @raises [NameError, Error::NotFound]
    def get(type, name, target_provider=nil)
      unless(TYPES.keys.include?(type.to_s))
        raise NameError.new "Invalid type requested (#{type})! Valid types: #{TYPES.keys.join(', ')}"
      end
      unless(target_provider)
        target_provider = provider
      end
      result = send(TYPES[type]).get(target_provider, name)
      if(result.nil? && TYPES[type] == 'templates')
        result = (
          send(TYPES[type]).fetch(target_provider, Smash.new).detect{|_, v|
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
            t_provider = data.fetch(:args, :provider, :aws)
            if(templates.get(t_provider, data[:name]))
              raise KeyError.new "Template name is already in use within pack! (`#{data[:name]}` -> `#{t_provider}`)"
            end
            templates.set(t_provider, data[:name],
              data.merge(
                :type => :template,
                :path => file,
                :serialized => !file.end_with?('.rb')
              )
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
            i_provider = item.fetch(:args, :provider, :aws)
            if(collection.get(i_provider, name))
              raise KeyError.new "#{key.capitalize} name is already in use within pack! (`#{name}` -> #{i_provider})"
            end
            collection.set(i_provider, name, item)
          end
        end
      end
    end

  end
  # Alias for interfacing naming
  SparklePack = Sparkle
end
