require_relative '../../../../rspecs'

RSpec.describe 'Acceptance -> Deep Nesting -> Aws' do
  describe '-> Deep nesting parameter push' do

    let(:root) do
      SparkleFormation.new(:root) do
        parameters.test_param.type 'String'
      end
    end

    let(:with_param) do
      SparkleFormation.new(:with_param) do
        parameters.test_param.type 'String'
      end
    end

    let(:with_param_2) do
      SparkleFormation.new(:with_param_2) do
        parameters.test_param.type 'String'
      end
    end

    let(:without_param) do
      SparkleFormation.new(:without_param) do
        parameters.different_param.type 'String'
      end
    end

    context 'with single nested parameter path' do
      before do
        prm = with_param
        root.overrides do
          resources.nested do
            type _self.stack_resource_type
            properties.stack prm
          end
        end
        prm.parent = root
      end

      it 'should map root parameter to nested stack' do
        root.apply_deep_nesting
        result = root.sparkle_dump.to_smash
        nested_params = result.get('Resources', 'Nested', 'Properties', 'Parameters')
        expect(nested_params).to eq('TestParam' => {'Ref' => 'TestParam'})
      end

      context 'with double nested parameter path' do
        before do
          prm2 = with_param_2
          with_param.overrides do
            resources.nested2 do
              type _self.stack_resource_type
              properties.stack prm2
            end
          end
          prm2.parent = with_param
        end

        it 'should map root parameter to first nested stack' do
          root.apply_deep_nesting
          result = root.sparkle_dump.to_smash
          nested_params = result.get('Resources', 'Nested', 'Properties', 'Parameters')
          expect(nested_params).to eq('TestParam' => {'Ref' => 'TestParam'})
        end

        it 'should map root parameter to second nested stack' do
          root.apply_deep_nesting
          result = root.sparkle_dump.to_smash
          nested_params = result.get(
            'Resources', 'Nested', 'Properties', 'Stack',
            'Resources', 'Nested2', 'Properties', 'Parameters'
          )
          expect(nested_params).to eq('TestParam' => {'Ref' => 'TestParam'})
        end
      end
    end

    context 'with double nested no parameter path' do
      before do
        wo_prm = without_param
        prm = with_param
        wo_prm.overrides do
          resources.nested2 do
            type _self.stack_resource_type
            properties.stack prm
          end
        end
        root.overrides do
          resources.nested do
            type _self.stack_resource_type
            properties.stack wo_prm
          end
        end
        wo_prm.parent = root
        prm.parent = wo_prm
      end

      it 'should map root parameter to first nested stack' do
        root.apply_deep_nesting
        result = root.sparkle_dump.to_smash
        nested_params = result.get('Rsources', 'Nested', 'Properties', 'Parameters')
        expect(nested_params).to be_nil
      end
    end
  end
end
