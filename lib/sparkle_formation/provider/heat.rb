require 'sparkle_formation'

class SparkleFormation
  module Provider
    # Heat specific implementation
    module Heat

      # @return [String] Type string for OpenStack HEAT stack resource
      def stack_resource_type
        'OS::Heat::Stack'
      end

      # Generate policy for stack
      #
      # @return [Hash]
      def generate_policy
        {}
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
      # @return [Hash] dumped stack
      def apply_deep_nesting(*args, &block)
        outputs = collect_outputs
        nested_stacks(:with_resource).each do |stack, resource|
          unless(stack.nested_stacks.empty?)
            stack.apply_deep_nesting(*args)
          end
          stack.compile.parameters.keys!.each do |parameter_name|
            if(output_name = output_matched?(parameter_name, outputs.keys))
              next if outputs[output_name] == stack
              stack_output = stack.make_output_available(output_name, outputs)
              resource.properties.parameters._set(parameter_name, stack_output)
            end
          end
        end
        if(block_given?)
          extract_templates(&block)
        end
        compile.dump!
      end

      # Apply shallow nesting. This style of nesting will bubble
      # parameters up to the root stack. This type of nesting is the
      # original and now deprecated, but remains for compat issues so any
      # existing usage won't be automatically busted.
      #
      # @yieldparam resource_name [String] name of stack resource
      # @yieldparam stack [SparkleFormation] nested stack
      # @yieldreturn [String] Remote URL storage for template
      # @return [Hash]
      def apply_shallow_nesting(*args, &block)
        parameters = compile.parameters
        output_map = {}
        nested_stacks(:with_resource, :with_name).each do |_stack, stack_resource, stack_name|
          remap_nested_parameters(compile, parameters, stack_name, stack_resource, output_map)
        end
        extract_templates(&block)
        if(args.include?(:bubble_outputs))
          output_map.each do |o_name, o_val|
            compile.outputs._set(o_name).value compile._stack_output(*o_val)
          end
        end
        compile.dump!
      end

      # Extract output to make available for stack parameter usage at the
      # current depth
      #
      # @param output_name [String] name of output
      # @param outputs [Hash] listing of outputs
      # @reutrn [Hash] reference to output value (used for setting parameter)
      def make_output_available(output_name, outputs)
        bubble_path = outputs[output_name].root_path - root_path
        drip_path = root_path - outputs[output_name].root_path
        bubble_path.each_slice(2) do |base_sparkle, ref_sparkle|
          next unless ref_sparkle
          base_sparkle.compile.outputs._set(output_name)._set(
            :value, base_sparkle.compile._stack_output(
              ref_sparkle.name, output_name
            )
          )
        end
        if(bubble_path.empty?)
          if(drip_path.size == 1)
            parent = drip_path.first.parent
            if(parent && !parent.compile.parameters._set(output_name).nil?)
              return compile.parameter!(output_name)
            end
          end
          raise ArgumentError.new "Failed to detect available bubbling path for output `#{output_name}`. " <<
            'This may be due to a circular dependency! ' <<
            "(Output Path: #{outputs[output_name].root_path.map(&:name).join(' > ')} " <<
            "Requester Path: #{root_path.map(&:name).join(' > ')})"
        end
        result = compile._stack_output(bubble_path.first.name, output_name)
        if(drip_path.size > 1)
          parent = drip_path.first.parent
          drip_path.unshift(parent) if parent
          drip_path.each_slice(2) do |base_sparkle, ref_sparkle|
            next unless ref_sparkle
            base_sparkle.compile.resources[ref_sparkle.name].properties.parameters._set(output_name, result)
            ref_sparkle.compile.parameters._set(output_name).type 'string' # TODO: <<<<------ type check and prop
            result = compile._parameter(output_name)
          end
        end
        result
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
        nested_template = stack_resource.properties.stack.compile
        stack_parameters = nested_template.parameters
        unless(stack_parameters.nil?)
          stack_parameters._keys.each do |pname|
            pval = stack_parameters[pname]
            unless(pval.stack_unique.nil?)
              check_name = [stack_name, pname].join
            else
              check_name = pname
            end
            if(!parameters._set(check_name).nil?)
              template.resources._set(stack_name).properties.parameters._set(pname, template._parameter(check_name))
            elsif(output_map[check_name])
              template.resources._set(stack_name).properties.parameters._set(pname)
              template._stack_output(*output_map[check_name])
            else
              parameters._set(check_name, pval)
              template.resources._set(stack_name).properties.parameters._set(pname, template._parameter(check_name))
            end
          end
        end
        unless(nested_template.outputs.nil?)
          nested_template.outputs.keys!.each do |oname|
            output_map[oname] = [stack_name, oname]
          end
        end
        true
      end

    end
  end
end
