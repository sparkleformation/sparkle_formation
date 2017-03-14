require_relative '../../rspecs'

RSpec.describe SparkleFormation::SparkleAttribute::Azure do
  let(:template){ SparkleFormation.new('test') }

  let(:instance) do
    klass = Class.new(SparkleFormation::SparkleStruct)
    klass.include described_class
    obj = klass.new
    obj._set_self(template)
    obj
  end

  describe '.resources_formatter' do
    let(:resources_hash) do
      Smash.new(
        :resources => {
          :item_name => {
            :properties => []
          }
        }
      )
    end

    it 'should covert resources Hash into resources Array' do
      result = described_class.resources_formatter(resources_hash)
      expect(result).to eq('resources' => ['name' => 'item_name', 'properties' => []])
    end
  end

  describe 'Azure Functions' do
    described_class.const_get(:AZURE_FUNCTIONS).each do |full_name|
      f_name = Bogo::Utility.snake(full_name)

      context "#_#{f_name}" do
        it "should generate a function string for #{f_name}" do
          result = instance.__send__("_#{f_name}".to_sym)
          expect(result._dump).to eq("[#{full_name}()]")
        end

        it 'should generate functions with arguments' do
          result = instance.__send__("_#{f_name}".to_sym, 1, 'string')
          expect(result._dump).to eq("[#{full_name}(1, 'string')]")
        end
      end
    end
  end

  describe '#_resource_id' do
    it 'should raise error if resource is not defined' do
      expect{ instance._resource_id('item') }.to raise_error(SparkleFormation::Error::NotFound::Resource)
    end

    context 'with resource defined' do
      before{ instance.resources.item.type 'Custom' }

      it 'should create a resource id data structure' do
        expect(instance._resource_id('item')._dump).to eq("[resourceId('Custom', 'Item')]")
      end
    end
  end

  describe '#_depends_on' do
    before{ instance.resources.item.type 'Custom' }

    it 'should inject depends on data structure into underlying structure' do
      result = instance._depends_on(:item)
      expect(instance._dump['DependsOn']).to eq(['Custom/Item'])
    end
  end

  describe '#_stack_output' do
    it 'should create a stack output data structure' do
      expect(instance._stack_output('s_name', 's_output')._dump).to eq("[reference('SName').outputs.SOutput.value]")
    end
  end

  describe '#_variables' do
    it 'should generate an azure variable struct' do
      expect(instance._variables('foo')._klass).to eq(SparkleFormation::AzureVariableStruct)
    end

    it 'should generate a variables function string on dump' do
      expect(instance._variables('foo')._dump).to eq("[variables('foo')]")
    end

    context 'with local template context' do
      let(:template) do
        SparkleFormation.new('test', :provider => :azure) do
          variables do
            snake.set!('nested_function_call'.disable_camel!, 'fubar')
            camel do
              NestedFunctionCall 'foobar'
            end
            normal.nested_function_call 'phewbar'
          end
          snake variables!(:snake).nested_function_call
          camel variables!(:camel).nested_function_call
          normal variables!(:normal).nested_function_call
          unset variables!(:unset).nested_function_call
        end
      end

      it 'should dump the snake cased function name' do
        expect(template.dump.to_smash[:snake]).to eq("[variables('snake').nested_function_call]")
      end

      it 'should dump the camel cased function name' do
        expect(template.dump.to_smash[:camel]).to eq("[variables('camel').NestedFunctionCall]")
      end

      it 'should dump the normal cased function name' do
        expect(template.dump.to_smash[:normal]).to eq("[variables('normal').nestedFunctionCall]")
      end

      it 'should dump the explicit given function name when variable is unset' do
        expect(template.dump.to_smash[:unset]).to eq("[variables('unset').nested_function_call]")
      end
    end
  end
end
