#
# Author:: Chris Roberts <chris@hw-ops.com>
# Copyright:: 2013, Heavy Water Operations, LLC
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'attribute_struct'
require 'sparkle_formation/sparkle_attribute'
require 'sparkle_formation/utils'

AttributeStruct.camel_keys = true

class SparkleFormation

  include SparkleFormation::Utils::AnimalStrings

  class << self

    include SparkleFormation::Utils::AnimalStrings

    attr_reader :dynamics
    attr_reader :components_path
    attr_reader :dynamics_path

    # Return custom paths
    def custom_paths
      @_paths ||= {}
      @_paths
    end

    # path:: Path
    # Set path to component files
    def components_path=(path)
      custom_paths[:sparkle_path] = path
    end

    # path:: Path
    # Set path to dynamic files
    def dynamics_path=(path)
      custom_paths[:dynamics_directory] = path
    end

    # path:: Path
    # args:: Option symbols
    #   - :sparkle:: Return formation instead of Hash
    # Compile file at given path and return Hash
    def compile(path, *args)
      formation = self.instance_eval(IO.read(path), path, 1)
      args.include?(:sparkle) ? formation : formation.compile._dump
    end

    # base:: Base AttributeStruct
    # Execute given block within base
    def build(base=nil, &block)
      struct = base || AttributeStruct.new
      struct.instance_exec(&block)
      @_struct = struct
    end

    # path:: Path
    # Load component at given path
    def load_component(path)
      self.instance_eval(IO.read(path), path, 1)
      @_struct
    end

    # directory:: Path
    # Load all dynamics within given directory
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

    # name:: Name of dynamic
    # Define a new dynamic and store associated block
    def dynamic(name, &block)
      @dynamics ||= Mash.new
      @dynamics[name] = block
    end

    # dynamic_name:: Name of dynamic
    # struct:: AttributeStruct instances
    # args:: Args to pass to dynamic
    # Inserts a dynamic into the given AttributeStruct instance
    def insert(dynamic_name, struct, *args)
      result = false
      if(@dynamics && @dynamics[dynamic_name])
        struct.instance_exec(*args, &@dynamics[dynamic_name])
        result = struct
      else
        result = builtin_insert(dynamic_name, struct, *args)
      end
      unless(result)
        raise "Failed to locate requested dynamic block for insertion: #{dynamic_name} (valid: #{@dynamics.keys.sort.join(', ')})"
      end
      result
    end

    # dynamic_name:: Name of dynamic
    # struct:: AttributeStruct instances
    # args:: Args to pass to dynamic
    # Inserts a builtin dynamic into the given AttributeStruct instance
    def builtin_insert(dynamic_name, struct, *args)
      if(defined?(SfnAws) && lookup_key = SfnAws.registry_key(dynamic_name))
        _name, _config = *args
        _config ||= {}
        return unless _name
        new_resource = struct.resources.__send__("#{_name}_#{dynamic_name}".to_sym)
        new_resource.type lookup_key
        properties = new_resource.properties
        SfnAws.resource(dynamic_name, :properties).each do |prop_name|
          value = [prop_name, snake(prop_name)].map do |key|
            _config[key] || _config[key.to_sym]
          end.compact.first
          if(value)
            if(value.is_a?(Proc))
              properties.__send__(prop_name).instance_exec(&value)
            else
              properties.__send__(prop_name, value)
            end
          end
        end
        struct
      end
    end

    # hash:: Hash
    # Attempts to load an AttributeStruct instance from and existing
    # Hash instance
    # NOTE: camel keys will do best effort at auto discovery
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
    unless(options[:disable_aws_builtins])
      require 'sparkle_formation/aws'
      SfnAws.load!
    end
    @components = AttributeStruct.hashish.new
    @load_order = []
    @overrides = []
    if(block)
      load_block(block)
    end
  end

  # block:: block to execute
  # Loads block
  def load_block(block)
    @components[:__base__] = self.class.build(&block)
    @load_order << :__base__
  end

  # args:: symbols or paths for component loads
  # Loads components into instance
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

  # Registers block into overrides
  def overrides(&block)
    @overrides << block
    self
  end

  # Returns compiled Mash instance
  def compile
    compiled = AttributeStruct.new
    @load_order.each do |key|
      compiled._merge!(components[key])
    end
    @overrides.each do |override|
      self.class.build(compiled, &override)
    end
    compiled
  end

end
