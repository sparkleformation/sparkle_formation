require 'sparkle_formation'

# Formation container
class SparkleFormation

  include SparkleFormation::Utils::AnimalStrings
  # @!parse include SparkleFormation::Utils::AnimalStrings
  extend SparkleFormation::Utils::AnimalStrings
  # @!parse extend SparkleFormation::Utils::AnimalStrings

  # @return [Array<String>] directory names to ignore
  IGNORE_DIRECTORIES = [
    'components',
    'dynamics',
    'registry'
  ]

  # @return [String] default stack resource name
  DEFAULT_STACK_RESOURCE = 'AWS::CloudFormation::Stack'
  # @return [Array<String>] collection of valid stack resource types
  VALID_STACK_RESOURCES = [DEFAULT_STACK_RESOURCE]

  class << self

    include SparkleFormation::Utils::TypeCheckers

    # @return [Hashish] loaded dynamics
    def dynamics
      @dynamics ||= SparkleStruct.hashish.new
    end

    # @return [Hashish] custom paths
    def custom_paths
      @_paths ||= SparkleStruct.hashish.new
      @_paths
    end

    # Get/set path to sparkle directory
    #
    # @param path [String] path to directory
    # @return [String] path to directory
    def sparkle_path=(path=nil)
      if(path)
        custom_paths[:sparkle_path] = path
        custom_paths[:components_directory] = File.join(path, 'components')
        custom_paths[:dynamics_directory] = File.join(path, 'dynamics')
        custom_paths[:registry_directory] = File.join(path, 'registry')
      end
      custom_paths[:sparkle_path]
    end
    alias_method(:sparkle_path, :sparkle_path=)

    # Get/set path to component files
    #
    # @param path [String] path to component files
    # @return [String] path to component files
    def components_path=(path=nil)
      if(path)
        custom_paths[:components_directory] = path
      end
      custom_paths[:components_directory]
    end
    alias_method(:components_path, :components_path=)

    # Get/set path to dynamic files
    #
    # @param path [String] path to dynamic files
    # @return [String] path to dynamic files
    def dynamics_path=(path=nil)
      if(path)
        custom_paths[:dynamics_directory] = path
      end
      custom_paths[:dynamics_directory]
    end
    alias_method(:dynamics_path, :dynamics_path=)

    # Get/set path to registry files
    #
    # @param path [String] path to registry files
    # @return [String] path to registry files
    def registry_path=(path=nil)
      if(path)
        custom_paths[:registry_directory] = path
      end
      custom_paths[:registry_directory]
    end
    alias_method(:registry_path, :registry_path=)

    # Compile file
    #
    # @param path [String] path to file
    # @param args [Object] use :sparkle to return struct. provide Hash
    #   to pass through when compiling ({:state => {}})
    # @return [Hashish, SparkleStruct]
    def compile(path, *args)
      opts = args.detect{|i| i.is_a?(Hash) } || {}
      unless(path.is_a?(String) && File.file?(path.to_s))
        if(spath = (opts.delete(:sparkle_path) || SparkleFormation.custom_paths[:sparkle_path]))
          container = Sparkle.new(:root => spath)
          path = container.get(:template, path)[:path]
        end
      end
      formation = instance_eval(IO.read(path), path, 1)
      formation.template_path = path
      if(args.delete(:sparkle))
        formation
      else
        formation.compile(opts)._dump
      end
    end

    # Execute given block within struct context
    #
    # @param base [SparkleStruct] context for block
    # @yield block to execute
    # @return [SparkleStruct] provided base or new struct
    def build(base=nil, &block)
      if(base || block.nil?)
        struct = base || SparkleStruct.new
        struct.instance_exec(&block)
        struct
      else
        block
      end
    end

    # Load component
    #
    # @param path [String] path to component
    # @return [SparkleStruct] resulting struct
    def load_component(path)
      instance_eval(IO.read(path), path, 1)
      @_struct
    end

    # Load all dynamics within a directory
    #
    # @param directory [String]
    # @return [TrueClass]
    def load_dynamics!(directory)
      @loaded_dynamics ||= []
      Dir.glob(File.join(directory, '*.rb')).each do |dyn|
        dyn = File.expand_path(dyn)
        next if @loaded_dynamics.include?(dyn)
        instance_eval(IO.read(dyn), dyn, 1)
        @loaded_dynamics << dyn
      end
      @loaded_dynamics.uniq!
      true
    end

    # Load all registry entries within a directory
    #
    # @param directory [String]
    # @return [TrueClass]
    def load_registry!(directory)
      Dir.glob(File.join(directory, '*.rb')).each do |reg|
        reg = File.expand_path(reg)
        require reg
      end
      true
    end

    # Define and register new dynamic
    #
    # @param name [String, Symbol] name of dynamic
    # @param args [Hash] dynamic metadata
    # @option args [Hash] :parameters description of _config parameters
    # @example
    #   metadata describes dynamic parameters for _config hash:
    #   :item_name => {:description => 'Defines item name', :type => 'String'}
    # @yield dynamic block
    # @return [TrueClass]
    def dynamic(name, args={}, &block)
      @dynamics ||= SparkleStruct.hashish.new
      dynamics[name] = SparkleStruct.hashish[
        :block, block, :args, SparkleStruct.hashish[args.map(&:to_a)]
      ]
      true
    end

    # Metadata for dynamic
    #
    # @param name [String, Symbol] dynamic name
    # @return [Hashish] metadata information
    def dynamic_info(name)
      if(dynamics[name])
        dynamics[name][:args] ||= SparkleStruct.hashish.new
      else
        raise KeyError.new("No dynamic registered with provided name (#{name})")
      end
    end
    alias_method :dynamic_information, :dynamic_info

    # Insert a dynamic into a context
    #
    # @param dynamic_name [String, Symbol] dynamic name
    # @param struct [SparkleStruct] context for insertion
    # @param args [Object] parameters for dynamic
    # @return [SparkleStruct]
    def registry(registry_name, struct, *args)
      __t_stringish(registry_name)
      reg = struct._self.sparkle.get(:registry, registry_name)
      struct.instance_exec(*args, &reg[:block])
    end

    # Insert a dynamic into a context
    #
    # @param dynamic_name [String, Symbol] dynamic name
    # @param struct [SparkleStruct] context for insertion
    # @param args [Object] parameters for dynamic
    # @return [SparkleStruct]
    def insert(dynamic_name, struct, *args, &block)
      __t_stringish(dynamic_name)
      result = false
      begin
        dyn = struct._self.sparkle.get(:dynamic, dynamic_name)
        raise dyn if dyn.is_a?(Exception)
        dyn.monochrome.each do |dynamic_item|
          if(result)
            opts = args.detect{|i| i.is_a?(Hash)}
            if(opts)
              opts[:previous_layer_result] = result
            else
              args.push(:previous_layer_result => result)
            end
          end
          result = struct.instance_exec(*args, &dynamic_item[:block])
        end
        if(block_given?)
          result.instance_exec(&block)
        end
      rescue Error::NotFound::Dynamic
        result = builtin_insert(dynamic_name, struct, *args, &block)
        unless(result)
          message = "Failed to locate requested dynamic block for insertion: #{dynamic_name} " \
          "(valid: #{struct._self.sparkle.dynamics.keys.sort.join(', ')})"
          if(struct._self.provider_resources && struct._self.provider_resources.registry.keys.size > 1)
            t_name = struct._self.provider_resources.registry.keys.first
            valid_t_name = Bogo::Utility.snake(
              t_name.split(
                struct._self.provider_resources.resource_type_splitter
              ).join('_')
            )
            message << "\nBuiltin dynamics pattern `#{t_name}` -> `:#{Bogo::Utility.snake(valid_t_name)}`"
          end
          raise message
        end
      end
      result
    end

    # Nest a template into a context
    #
    # @param template [String, Symbol] template to nest
    # @param struct [SparkleStruct] context for nesting
    # @param args [String, Symbol] stringified and underscore joined for name
    # @return [SparkleStruct]
    # @note if symbol is provided for template, double underscores
    #   will be used for directory separator and dashes will match underscores
    def nest(template, struct, *args, &block)
      options = args.detect{|i| i.is_a?(Hash)}
      if(options)
        args.delete(options)
      else
        options = {}
      end
      [template, *args].compact.each do |item|
        __t_stringish(item)
      end
      to_nest = struct._self.sparkle.get(:template, template)
      resource_name = template.to_s.gsub('__', '_')
      unless(args.empty?)
        resource_name = [
          options.delete(:overwrite_name) ? nil : resource_name,
          args.map{|a| Bogo::Utility.snake(a)}.join('_')
        ].flatten.compact.join('_').to_sym
      end
      resource_name = struct._process_key(resource_name.to_sym)
      nested_template = compile(to_nest[:path], :sparkle)
      nested_template.parent = struct._self
      nested_template.name = resource_name
      if(options[:parameters])
        nested_template.compile_state = options[:parameters]
      end
      unless(struct._self.sparkle.empty?)
        nested_template.sparkle.apply(struct._self.sparkle)
      end
      nested_resource = struct.dynamic!(
        struct._self.stack_resource_type,
        resource_name,
        {:resource_name_suffix => nil},
        &block
      )
      nested_resource.properties.stack nested_template
      nested_resource
    end

    # Insert a builtin dynamic into a context
    #
    # @param dynamic_name [String, Symbol] dynamic name
    # @param struct [SparkleStruct] context for insertion
    # @param args [Object] parameters for dynamic
    # @return [SparkleStruct]
    def builtin_insert(dynamic_name, struct, *args, &block)
      if(struct._self.provider_resources && lookup_key = struct._self.provider_resources.registry_key(dynamic_name))
        _name, _config = *args
        _config ||= {}
        __t_stringish(_name)
        __t_hashish(_config)
        resource_name = [
          _name,
          _config.fetch(:resource_name_suffix, dynamic_name)
        ].compact.join('_').to_sym
        _config.delete(:resource_name_suffix)
        new_resource = struct.resources.set!(resource_name)
        new_resource.type lookup_key
        properties = new_resource.properties
        config_keys = _config.keys.zip(_config.keys.map{|k| snake(k).to_s.tr('_', '')})
        struct._self.provider_resources.resource(dynamic_name, :properties).each do |prop_name|
          key = (config_keys.detect{|k| k.last == snake(prop_name).to_s.tr('_', '')} || []).first
          value = _config[key] if key
          if(value)
            if(value.is_a?(Proc))
              properties.set!(prop_name, &value)
            else
              properties.set!(prop_name, value)
            end
          end
        end
        new_resource.instance_exec(&block) if block
        struct._self.provider_resources.resource_customizer(new_resource, lookup_key)
        new_resource
      end
    end

    # Convert hash to SparkleStruct instance
    #
    # @param hash [Hashish]
    # @return [SparkleStruct]
    # @note will do best effort on camel key auto discovery
    def from_hash(hash)
      struct = SparkleStruct.new
      struct._camel_keys_set(:auto_discovery)
      struct._load(hash)
      struct._camel_keys_set(nil)
      struct
    end
  end

  include Bogo::Memoization

  # @return [Symbol] name of formation
  attr_accessor :name
  # @return [Sparkle] parts store
  attr_reader :sparkle
  # @return [String] base path
  attr_reader :sparkle_path
  # @return [String] components path
  attr_reader :components_directory
  # @return [String] dynamics path
  attr_reader :dynamics_directory
  # @return [String] registry path
  attr_reader :registry_directory
  # @return [Hash] parameters for stack generation
  attr_reader :parameters
  # @return [SparkleFormation] parent stack
  attr_accessor :parent
  # @return [Array<String>] valid stack resource types
  attr_reader :stack_resource_types
  # @return [Hash] state hash for compile time parameters
  attr_accessor :compile_state
  # @return [Symbol] target provider
  attr_reader :provider
  # @return [Class] Provider resources
  attr_reader :provider_resources
  # @return [String] local path to template
  attr_accessor :template_path
  # @return [Array<String>] black listed templates
  attr_reader :blacklisted_templates
  # @return [Composition]
  attr_reader :composition

  # Create new instance
  #
  # @param name [String, Symbol] name of formation
  # @param options [Hash] options
  # @option options [String] :sparkle_path custom base path
  # @option options [String] :components_directory custom components path
  # @option options [String] :dynamics_directory custom dynamics path
  # @option options [String] :registry_directory custom registry path
  # @option options [Hash] :parameters parameters for stack generation
  # @option options [Truthy, Falsey] :disable_aws_builtins do not load builtins
  # @yield base context
  def initialize(name, options={}, &base_block)
    @name = name.to_sym
    @component_paths = []
    if(options[:sparkle_collection])
      @sparkle = options[:sparkle_collection]
    else
      @sparkle = SparkleCollection.new
      @sparkle.set_root(
        Sparkle.new(
          Smash.new.tap{|h|
            s_path = options.fetch(:sparkle_path,
              self.class.custom_paths[:sparkle_path]
            )
            if(s_path)
              h[:root] = s_path
            else
              h[:root] = :none
            end
          }
        )
      )
    end
    self.provider = options.fetch(:provider, @parent ? @parent.provider : :aws)
    if(provider == :aws || !options[:disable_aws_builtins])
      require 'sparkle_formation/aws'
    end
    @parameters = set_generation_parameters!(
      options.fetch(:compile_time_parameters,
        options.fetch(:parameters, {})
      )
    )
    @stack_resource_types = [
      stack_resource_type,
      *options.fetch(:stack_resource_types, [])
    ].compact.uniq
    @blacklisted_templates = [name]
    @composition = Composition.new(self)
    @parent = options[:parent]
    @seed = Smash.new(
      :inherit => options[:inherit],
      :layering => options[:layering]
    )
    if(base_block)
      load_block(base_block)
    end
    @compiled = nil
  end

  # Update underlying data structures based on inherit
  # or layering behavior if defined for this template
  #
  # @param options [Hash]
  # @return [self]
  def seed_self
    memoize(:seed) do
      options = @seed
      if(options[:inherit] && options[:layering].to_s == 'merge')
        raise ArgumentError.new 'Cannot merge and inherit!'
      end
      if(options[:inherit])
        inherit_from(options[:inherit])
      elsif(options[:layering].to_s == 'merge')
        merge_previous!
      end
      true
    end
    self
  end

  # Merge previous layer template structure
  #
  # @return [self]
  def merge_previous!
    my_index = sparkle.get(:template, name).spectrum.find_index do |item|
      item[:path] == template_path
    end
    template = self.class.compile(sparkle.get(:template, name).layer_at(my_index - 1)[:path], :sparkle)
    extract_template_data(template)
  end

  # Inhert template structure
  #
  # @param template_name [String] name of template to inherit
  # @return [self]
  def inherit_from(template_name)
    if(blacklisted_templates.map(&:to_s).include?(template_name.to_s))
      raise Error::CircularInheritance.new "Circular inheritance detected between templates `#{template_name}` and `#{name}`" # rubocop:disable Metrics/LineLength
    end
    template = self.class.compile(sparkle.get(:template, template_name)[:path], :sparkle)
    template.blacklisted_templates.replace(
      (template.blacklisted_templates + blacklisted_templates).map(&:to_s).uniq
    )
    extract_template_data(template)
  end

  # Extract information from given template and integrate with current instance
  #
  # @param template [SparkleFormation]
  # @return [self]
  def extract_template_data(template)
    # TODO: Should allow forced override here for cases like: openstack -> rackspace
    if(provider != template.provider)
      raise TypeError.new "This template `#{name}` cannot inherit template `#{template.name}`! Provider mismatch: `#{provider}` != `#{template.provider}`" # rubocop:disable Metrics/LineLength
    end
    template.sparkle.apply(sparkle)
    template.seed_self
    blacklisted_templates.replace(
      (blacklisted_templates + template.blacklisted_templates).map(&:to_s).uniq
    )
    @parameters = template.parameters.to_smash.deep_merge(parameters.to_smash)
    new_composition = Composition.new(self,
      :components => template.composition.composite,
      :overrides => composition.overrides
    )
    composition.components.each do |item|
      if(item.respond_to?(:key) && item.key == '__base__')
        item.key = Smash.new(
          :template => name,
          :component => :__base__,
          :object_id => object_id
        ).checksum.to_s
      end
      new_composition.add_component(item)
    end
    @composition = new_composition
    self
  end

  # @return [String] provider stack resource type
  def stack_resource_type
    DEFAULT_STACK_RESOURCE
  end

  # Set remote API target for template to allow loading of
  # provider specific helpers and data if available. Setting
  # to a false-y value will disable helpers loading
  #
  # @param val [String, Symbol, NilClass, FalseClass] remote provider
  # @return [Symbol, NilClass]
  def provider=(val)
    if(val)
      @provider = Bogo::Utility.snake(val).to_sym
      provider_klass = Bogo::Utility.camel(@provider.to_s)
      if(Provider.const_defined?(provider_klass))
        extend Provider.const_get(provider_klass)
      end
      @provider
    else
      @provider = nil
    end
  end

  # Check if type is a registered stack type
  #
  # @param type [String]
  # @return [TrueClass, FalseClass]
  def stack_resource_type?(type)
    stack_resource_types.include?(type)
  end

  # @return [SparkleFormation] root stack
  def root
    if(parent)
      parent.root
    else
      self
    end
  end

  # @return [Array<SparkleFormation] path to root
  def root_path
    if(parent)
      [*parent.root_path, self].compact
    else
      [self]
    end
  end

  # @return [TrueClass, FalseClass] current stack is root
  def root?
    root == self
  end

  ALLOWED_GENERATION_PARAMETERS = ['type', 'default', 'description', 'multiple', 'prompt_when_nested']
  VALID_GENERATION_PARAMETER_TYPES = ['String', 'Number']

  # Get or set the compile time parameter setting block. If a get
  # request the ancestor path will be searched to root
  #
  # @yield block to set compile time parameters
  # @yieldparam [SparkleFormation]
  # @return [Proc, NilClass]
  def compile_time_parameter_setter(&block)
    if(block)
      @compile_time_parameter_setter = block
    else
      if(@compile_time_parameter_setter)
        @compile_time_parameter_setter
      else
        parent.nil? ? nil : parent.compile_time_parameter_setter
      end
    end
  end

  # Set the compile time parameters for the stack if the setter proc
  # is available
  def set_compile_time_parameters!
    if(compile_time_parameter_setter)
      compile_time_parameter_setter.call(self)
    end
  end

  # Validation parameters used for template generation to ensure they
  # are in the expected format
  #
  # @param params [Hash] parameter set
  # @return [Hash] parameter set
  # @raises [ArgumentError]
  def set_generation_parameters!(params)
    params.each do |name, value|
      unless(value.is_a?(Hash))
        raise TypeError.new("Expecting `Hash` type. Received `#{value.class}`")
      end
      if(key = value.keys.detect{|k| !ALLOWED_GENERATION_PARAMETERS.include?(k.to_s) })
        raise ArgumentError.new("Invalid generation parameter key provided `#{key}`")
      end
    end
    params
  end

  # Add block to load order
  #
  # @param block [Proc]
  # @return [TrueClass]
  def block(block)
    composition.new_component(:__base__, &block)
    true
  end
  alias_method :load_block, :block

  # Load components into instance
  #
  # @param args [String, Symbol] Symbol component names or String paths
  # @return [self]
  def load(*args)
    args.each do |thing|
      if(thing.is_a?(String))
        # NOTE: This needs to be deprecated and removed
        # TODO: deprecate
        key = File.basename(thing.to_s).sub('.rb', '')
        composition.new_component(key, &self.class.load_component(thing))
      else
        composition.new_component(thing)
      end
    end
    self
  end

  # Registers block into overrides
  #
  # @param args [Hash] optional arguments to provide state
  # @yield override block
  def overrides(args={}, &block)
    composition.new_override(args, &block)
    self
  end

  # Compile the formation
  #
  # @param args [Hash]
  # @option args [Hash] :state local state parameters
  # @return [SparkleStruct]
  def compile(args={})
    if(args.key?(:state))
      @compile_state = args[:state]
      unmemoize(:compile)
    end
    memoize(:compile) do
      # NOTE: this is where we inject inherit or layering
      seed_self

      set_compile_time_parameters!
      if(provider && SparkleAttribute.const_defined?(camel(provider)))
        const = SparkleAttribute.const_get(camel(provider))
        struct_class = Class.new(SparkleStruct)
        struct_class.include(const)
        struct_name = [SparkleStruct.name, camel(provider)].join('::')
        struct_class.define_singleton_method(:name){ struct_name }
        struct_class.define_singleton_method(:to_s){ struct_name }
      else
        struct_class = SparkleStruct
      end
      if(Resources.const_defined?(camel(provider)))
        @provider_resources = Resources.const_get(camel(provider))
        provider_resources.load!
      end
      compiled = struct_class.new
      compiled._set_self(self)
      compiled._struct_class = struct_class
      if(struct_class.const_defined?(:CAMEL_KEYS))
        compiled._camel_keys = struct_class.const_get(:CAMEL_KEYS)
      end
      if(struct_class.const_defined?(:CAMEL_STYLE))
        compiled._camel_style = struct_class.const_get(:CAMEL_STYLE)
      end
      if(compile_state)
        compiled.set_state!(compile_state)
      end
      composition.each do |item|
        case item
        when Composition::Component
          if(item.block)
            self.class.build(compiled, &item.block)
          else
            sparkle.get(:component, item.key).monochrome.each do |component_block|
              self.class.build(compiled, &component_block[:block])
            end
          end
        when Composition::Override
          if(item.args && !item.args.empty?)
            compiled._set_state(item.args)
          end
          self.class.build(compiled, &item.block)
        end
      end
      if(compile_state && !compile_state.empty?)
        compiled.outputs.compile_state.value MultiJson.dump(compile_state)
      end
      compiled
    end
  end

  # Clear compiled stack if cached and perform compilation again
  #
  # @return [SparkleStruct]
  def recompile
    unmemoize(:compile)
    compile
  end

  # @return [Array<SparkleFormation>]
  def nested_stacks(*args)
    if(compile[:resources])
      compile.resources.keys!.map do |key|
        if(stack_resource_type?(compile.resources[key].type))
          result = [compile.resources[key].properties.stack]
          if(args.include?(:with_resource))
            result.push(compile[:resources][key])
          end
          if(args.include?(:with_name))
            result.push(key)
          end
          result.size == 1 ? result.first : result
        end
      end.compact
    else
      []
    end
  end

  # @return [TrueClass, FalseClass] includes nested stacks
  def nested?(stack_hash=nil)
    if(stack_hash)
      raise Error::Deprecated.new "Hash parameter no longer valid for this method (`#{self.class}##{__callee__}`)"
    end
    unless(compile.resources.nil?)
      compile.resources._data.any? do |r_name, r_value|
        stack_resource_type?(r_value.type)
      end
    end
  end

  # @return [TrueClass, FalseClass] includes _only_ nested stacks
  def isolated_nests?(stack_hash=nil)
    if(stack_hash)
      raise Error::Deprecated.new "Hash parameter no longer valid for this method (`#{self.class}##{__callee__}`)"
    end
    unless(compile.resources.nil?)
      compile.resources._data.all? do |r_name, r_value|
        stack_resource_type?(r_value.type)
      end
    end
  end

  # @return [TrueClass, FalseClass] policies defined
  def includes_policies?(stack_hash=nil)
    if(stack_hash)
      raise Error::Deprecated.new "Hash parameter no longer valid for this method (`#{self.class}##{__callee__}`)"
    end
    unless(compile.resources.nil?)
      compile.resources._data.any? do |r_name, r_value|
        !r_value.policy.nil?
      end
    end
  end

  # Generate policy for stack
  #
  # @return [Hash]
  def generate_policy
    Smash.new
  end

  # Apply nesting logic to stack
  #
  # @param nest_type [Symbol] values: :shallow, :deep (default: :deep)
  # @return [SparkleFormation::SparkleStruct] compiled structure
  # @note see specific version for expected block parameters
  def apply_nesting(*args, &block)
    if(args.include?(:shallow))
      apply_shallow_nesting(&block)
    else
      apply_deep_nesting(&block)
    end
  end

  # Apply deeply nested stacks. This is the new nesting approach and
  # does not bubble parameters up to the root stack. Parameters are
  # isolated to the stack resource itself and output mapping is
  # automatically applied.
  #
  # @yieldparam stack [SparkleFormation] stack instance
  # @yieldparam resource [AttributeStruct] the stack resource
  # @yieldparam s_name [String] stack resource name
  # @yieldreturn [Hash] key/values to be merged into resource properties
  # @return [SparkleFormation::SparkleStruct] compiled structure
  def apply_deep_nesting(*args, &block)
    compile
  end

  # Check if parameter name matches an output name
  #
  # @param p_name [String, Symbol] parameter name
  # @param output_names [Array<String>] list of available outputs
  # @return [String, NilClass] matching output name
  # @note will auto downcase name prior to comparison
  def output_matched?(p_name, output_names)
    output_names.detect do |o_name|
      Bogo::Utility.snake(o_name).tr('_', '') == Bogo::Utility.snake(p_name).tr('_', '')
    end
  end

  # Extract output to make available for stack parameter usage at the
  # current depth
  #
  # @param output_name [String] name of output
  # @param outputs [Hash] listing of outputs
  # @reutrn [Hash] reference to output value (used for setting parameter)
  def make_output_available(output_name, outputs)
    {}
  end

  # Extract and process nested stacks
  #
  # @yieldparam stack [SparkleFormation] stack instance
  # @yieldparam resource [AttributeStruct] the stack resource
  # @yieldparam s_name [String] stack resource name
  # @yieldreturn [Hash] key/values to be merged into resource properties
  def extract_templates(&block)
    stack_template_extractor(nested_stacks(:with_resource, :with_name), &block)
  end

  # Run the stack extraction
  #
  # @param x_stacks [Array<Array<SparkleFormation, SparkleStruct, String>>]
  def stack_template_extractor(x_stacks, &block)
    x_stacks.each do |stack, resource, s_name|
      unless(stack.nested_stacks.empty?)
        stack_template_extractor(stack.nested_stacks(:with_resource, :with_name), &block)
      end
      resource.properties.set!(:stack, stack.compile.dump!)
      block.call(s_name, stack, resource)
    end
  end

  # Apply shallow nesting. This style of nesting will bubble
  # parameters up to the root stack. This type of nesting is the
  # original and now deprecated, but remains for compat issues so any
  # existing usage won't be automatically busted.
  #
  # @yieldparam resource_name [String] name of stack resource
  # @yieldparam stack [SparkleFormation] nested stack
  # @yieldreturn [String] Remote URL storage for template
  # @return [SparkleFormation::SparkleStruct] compiled structure
  def apply_shallow_nesting(*args, &block)
    compile
  end

  # @return [Smash<output_name:SparkleFormation>]
  def collect_outputs(*args)
    if(args.include?(:force) || root?)
      unless(compile.outputs.nil?)
        outputs = Smash[
          compile.outputs.keys!.zip(
            [self] * compile.outputs.keys!.size
          )
        ]
      else
        outputs = Smash.new
      end
      nested_stacks.each do |nested_stack|
        outputs = nested_stack.collect_outputs(:force).merge(outputs)
      end
      outputs
    else
      root.collect_outputs(:force)
    end
  end

  # Extract parameters from nested stacks. Check for previous nested
  # stack outputs that match parameter. If match, set parameter to use
  # output. If no match, check container stack parameters for match.
  # If match, set to use ref. If no match, add parameter to container
  # stack parameters and set to use ref.
  #
  # @param template [Hash] template being processed
  # @param parameters [Hash] top level parameter set being built
  # @param stack_name [String] name of stack resource
  # @param stack_resource [Hash] duplicate of stack resource contents
  # @param output_map [Hash] mapping of output names to required stack output access
  # @return [TrueClass]
  # @note if parameter has includes `StackUnique` a new parameter will
  #   be added to container stack and it will not use outputs
  def remap_nested_parameters(template, parameters, stack_name, stack_resource, output_map)
    true
  end

  # @return [Hash] dumped hash
  def dump
    MultiJson.load(to_json)
  end

  # @return [Hash] dumped hash
  def sparkle_dump
    MultiJson.load(
      MultiJson.dump(
        compile.sparkle_dump!
      )
    )
  end

  # @return [String] dumped hash JSON
  def to_json(*args)
    # NOTE: Ported in from batali
    # Prevent stupid conversion errors of
    # JSON::Ext::Generator::State into Hash
    args = args.map do |argument|
      argument.respond_to?(:to_h) ? argument.to_h : argument
    end
    MultiJson.dump(compile.dump!, *args)
  end

end
