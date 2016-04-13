require 'sparkle_formation'

class SparkleFormation
  module Provider
    # AWS specific implementation
    module Aws

      # @return [String] Type string for AWS CFN stack resource
      def stack_resource_type
        'AWS::CloudFormation::Stack'
      end

      # Generate policy for stack
      #
      # @return [Hash]
      def generate_policy
        statements = []
        compile.resources.keys!.each do |r_name|
          r_object = compile.resources[r_name]
          if(r_object['Policy'])
            r_object['Policy'].keys!.each do |effect|
              statements.push(
                'Effect' => effect.to_s.capitalize,
                'Action' => [r_object['Policy'][effect]].flatten.compact.map{|i| "Update:#{i}"},
                'Resource' => "LogicalResourceId/#{r_name}",
                'Principal' => '*'
              )
            end
            r_object.delete!('Policy')
          end
        end
        statements.push(
          'Effect' => 'Allow',
          'Action' => 'Update:*',
          'Resource' => '*',
          'Principal' => '*'
        )
        Smash.new('Statement' => statements)
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
        outputs = collect_outputs
        nested_stacks(:with_resource).each do |stack, resource|
          unless(stack.nested_stacks.empty?)
            stack.apply_deep_nesting(*args)
          end
          stack.compile.parameters.keys!.each do |parameter_name|
            if(output_name = output_matched?(parameter_name, outputs.keys))
              next if outputs[output_name] == stack
              stack_output = stack.make_output_available(output_name, outputs)
              resource.properties.parameters.set!(parameter_name, stack_output)
            end
          end
        end
        if(block_given?)
          extract_templates(&block)
        end
        compile
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
        parameters = compile[:parameters] ? compile[:parameters]._dump : {}
        output_map = {}
        nested_stacks(:with_resource, :with_name).each do |_stack, stack_resource, stack_name|
          remap_nested_parameters(compile, parameters, stack_name, stack_resource, output_map)
        end
        extract_templates(&block)
        compile.parameters parameters
        if(args.include?(:bubble_outputs))
          outputs_hash = Hash[
            output_map do |name, value|
              [name, {'Value' => {'Fn::GetAtt' => value}}]
            end
          ]
          if(compile.outputs)
            compile._merge(compile._klass_new(outputs_hash))
          else
            compile.outputs output_hash
          end
        end
        compile
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
          base_sparkle.compile.outputs.set!(output_name).set!(
            :value, base_sparkle.compile.attr!(
              ref_sparkle.name, "Outputs.#{output_name}"
            )
          )
        end
        if(bubble_path.empty?)
          if(drip_path.size == 1)
            parent = drip_path.first.parent
            if(parent && parent.compile.parameters.data![output_name])
              return compile.ref!(output_name)
            end
          end
          raise ArgumentError.new "Failed to detect available bubbling path for output `#{output_name}`. " <<
            'This may be due to a circular dependency! ' <<
            "(Output Path: #{outputs[output_name].root_path.map(&:name).join(' > ')} " <<
            "Requester Path: #{root_path.map(&:name).join(' > ')})"
        end
        result = compile.attr!(bubble_path.first.name, "Outputs.#{output_name}")
        if(drip_path.size > 1)
          parent = drip_path.first.parent
          drip_path.unshift(parent) if parent
          drip_path.each_slice(2) do |base_sparkle, ref_sparkle|
            next unless ref_sparkle
            base_sparkle.compile.resources[ref_sparkle.name].properties.parameters.set!(output_name, result)
            ref_sparkle.compile.parameters.set!(output_name){ type 'String' } # TODO: <<<<------ type check and prop
            result = compile.ref!(output_name)
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
        stack_parameters = stack_resource.properties.stack.compile.parameters
        unless(stack_parameters.nil?)
          stack_parameters._dump.each do |pname, pval|
            if(pval['StackUnique'])
              check_name = [stack_name, pname].join
            else
              check_name = pname
            end
            if(parameters.keys.include?(check_name))
              if(list_type?(parameters[check_name]['Type']))
                new_val = {'Fn::Join' => [',', {'Ref' => check_name}]}
              else
                new_val = {'Ref' => check_name}
              end
              template.resources.set!(stack_name).properties.parameters.set!(pname, new_val)
            elsif(output_map[check_name])
              template.resources.set!(stack_name).properties.parameters.set!(
                pname, 'Fn::GetAtt' => output_map[check_name]
              )
            else
              if(list_type?(pval['Type']))
                new_val = {'Fn::Join' => [',', {'Ref' => check_name}]}
              else
                new_val = {'Ref' => check_name}
              end
              template.resources.set!(stack_name).properties.parameters.set!(pname, new_val)
              parameters[check_name] = pval
            end
          end
        end
        unless(stack_resource.properties.stack.compile.outputs.nil?)
          stack_resource.properties.stack.compile.outputs.keys!.each do |oname|
            output_map[oname] = [stack_name, "Outputs.#{oname}"]
          end
        end
        true
      end

      # Check if type is a list type
      #
      # @param type [String]
      # @return [TrueClass, FalseClass]
      def list_type?(type)
        type == 'CommaDelimitedList' || type.start_with?('List<')
      end

    end
  end
end
