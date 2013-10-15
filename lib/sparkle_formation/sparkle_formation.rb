require 'attribute_struct'
require 'sparkle_formation/sparkle_attribute'
require 'sparkle_formation/utils'

AttributeStruct.camel_keys = true

class SparkleFormation

  include SparkleFormation::Utils::AnimalStrings

  class << self

    attr_reader :dynamics
    attr_reader :components_path
    attr_reader :dynamics_path

    def custom_paths
      @_paths ||= {}
      @_paths
    end

    def components_path=(path)
      custom_paths[:sparkle_path] = path
    end

    def dynamics_path=(path)
      custom_paths[:dynamics_directory] = path
    end

    def compile(path)
      formation = self.instance_eval(IO.read(path), path, 1)
      formation.compile._dump
    end

    def build(&block)
      struct = AttributeStruct.new
      struct.instance_exec(&block)
      struct
    end

    def load_component(path)
      self.instance_eval(IO.read(path), path, 1)
    end

    def load_dynamics!(directory)
      @loaded_dynamics ||= []
      Dir.glob(File.join(directory, '*.rb')).each do |dyn|
        dyn = File.expand_path(dyn)
        next if @loaded_dynamics.include?(dyn)
        self.instance_eval(IO.read(dyn), dyn, 1)
        @loaded_dynamics << dyn
      end
      @loaded_dynamics.uniq!
      true
    end

    def dynamic(name, &block)
      @dynamics ||= Mash.new
      @dynamics[name] = block
    end

    def insert(dynamic_name, struct, *args)
      if(@dynamics && @dynamics[dynamic_name])
        struct.instance_exec(*args, &@dynamics[dynamic_name])
        struct
      else
        raise "Failed to locate requested dynamic block for insertion: #{dynamic_name} (valid: #{@dynamics.keys.sort.join(', ')})"
      end
    end

    def from_hash(hash)
      struct = AttributeStruct.new
      struct._camel_keys_set(:auto_discovery)
      struct._load(hash)
      struct._camel_keys_set(nil)
      struct
    end
  end

  attr_reader :name
  attr_reader :sparkle_path
  attr_reader :components
  attr_reader :load_order

  def initialize(name, options={}, &block)
    @name = name
    @sparkle_path = options[:sparkle_path] ||
      self.class.custom_paths[:sparkle_path] ||
      File.join(Dir.pwd, 'cloudformation/components')
    @dynamics_directory = options[:dynamics_directory] ||
      self.class.custom_paths[:dynamics_directory] ||
      File.join(File.dirname(@sparkle_path), 'dynamics')
    self.class.load_dynamics!(@dynamics_directory)
    @components = AttributeStruct.hashish.new
    @load_order = []
    if(block)
      load_block(block)
    end
  end

  def load_block(block)
    @components[:__base__] = self.class.build(&block)
    @load_order << :__base__
  end

  def load(*args)
    args.each do |thing|
      if(thing.is_a?(Symbol))
        path = File.join(sparkle_path, "#{thing}.rb")
      else
        path = thing
      end
      key = File.basename(path).sub('.rb', '')
      components[key] = self.class.load_component(path)
      @load_order << key
    end
    self
  end

  def overrides(&block)
    @overrides = self.class.build(&block)
    self
  end

  # Returns compiled Mash instance
  def compile
    compiled = AttributeStruct.new
    @load_order.each do |key|
      compiled._merge!(components[key])
    end
    if(@overrides)
      compiled._merge!(@overrides)
    end
    compiled
  end

end
