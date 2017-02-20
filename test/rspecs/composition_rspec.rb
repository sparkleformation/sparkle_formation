require_relative '../rspecs'

RSpec.describe SparkleFormation::Composition do
  it 'should raise error if provided origin is not a SparkleFormation instance' do
    expect{ described_class.new(true) }.to raise_error(TypeError)
  end

  context 'with only origin provided' do
    let(:instance){ described_class.new(SparkleFormation.new('test')) }

    context '#components' do
      it 'should return empty array' do
        expect(instance.components).to eq([])
      end
    end

    context '#overrides' do
      it 'should return empty array' do
        expect(instance.overrides).to eq([])
      end
    end

    context '#composite' do
      it 'should return empty array' do
        expect(instance.composite).to eq([])
      end
    end

    context '#each' do
      it 'should return itself' do
        expect(instance.each).to eq(instance)
      end

      it 'should accept a block' do
        expect(instance.each{}).to eq(instance)
      end
    end

    context '#add_component' do
      let(:test_component) do
        SparkleFormation::Composition::Component.new(
          SparkleFormation.new('test'),
          :test_key,
          ['arg1', 'arg2']
        )
      end

      let(:test_override) do
        SparkleFormation::Composition::Override.new(
          SparkleFormation.new('test'),
          ['arg1', 'arg2']
        )
      end

      it 'should return itself' do
        expect(instance.add_component(test_component)).to eq(instance)
      end

      it 'should accept addition of component' do
        expect(instance.add_component(test_component)).to eq(instance)
      end

      it 'should accept addition of override' do
        expect(instance.add_component(test_override)).to eq(instance)
      end

      it 'should raise type error if item is not Component or override' do
        expect{ instance.add_component(true) }.to raise_error(TypeError)
      end

      it 'should add item to end of components list by default' do
        instance.add_component(test_component)
        instance.add_component(test_override)
        expect(instance.components.last).to eq(test_override)
      end

      it 'should add item to start of components list when using prepend' do
        instance.add_component(test_component)
        instance.add_component(test_override, :prepend)
        expect(instance.components.first).to eq(test_override)
      end

      it 'should raise ArgumentError when using undefined location value' do
        expect{ instance.add_component(test_component, :unknown) }.to raise_error(ArgumentError)
      end
    end

    context '#add_component' do
      let(:test_component) do
        SparkleFormation::Composition::Component.new(
          SparkleFormation.new('test'),
          :test_key,
          ['arg1', 'arg2']
        )
      end

      let(:test_override) do
        SparkleFormation::Composition::Override.new(
          SparkleFormation.new('test-1'),
          ['arg1', 'arg2']
        )
      end
      let(:test_override_2) do
        SparkleFormation::Composition::Override.new(
          SparkleFormation.new('test-2'),
          ['arg1', 'arg2']
        )
      end

      it 'should return self' do
        expect(instance.add_override(test_override)).to eq(instance)
      end

      it 'should raise TypeError when adding non-Override value' do
        expect{ instance.add_override(test_component) }.to raise_error(TypeError)
      end

      it 'should add item to end of overrides list' do
        instance.add_override(test_override_2)
        instance.add_override(test_override)
        expect(instance.overrides.last).to eq(test_override)
      end

      it 'should add item to start of overrides list when using prepend' do
        instance.add_override(test_override_2)
        instance.add_override(test_override, :prepend)
        expect(instance.overrides.first).to eq(test_override)
      end

      it 'should raise ArgumentError when using undefined location value' do
        expect{ instance.add_override(test_override, :unknown) }.to raise_error(ArgumentError)
      end
    end

    context '#new_component' do
      it 'should return self' do
        expect(instance.new_component(:test_component)).to eq(instance)
      end

      it 'should create Component and add to composition' do
        instance.new_component(:test_component)
        expect(instance.components.map(&:key)).to include('test_component')
      end

      it 'should add new Component to end of list' do
        instance.new_component(:test_component)
        instance.new_component(:test_component_2)
        expect(instance.components.last.key).to eq('test_component_2')
      end

      it 'should add new component to start of list when prepend used' do
        instance.new_component(:test_component)
        instance.new_component(:test_component_2, :prepend)
        expect(instance.components.first.key).to eq('test_component_2')
      end
    end

    context '#new_override' do
      it 'should return self' do
        expect(instance.new_override).to eq(instance)
      end

      it 'should create Override and add to composition' do
        instance.new_override
        expect(instance.overrides.first).to be_a(SparkleFormation::Composition::Override)
      end
    end

    context '#each' do
      before do
        instance.new_component(:first){|item| :first }
        instance.new_override{|item| :second }
        instance.new_component(:second){|item| :third }
      end

      it 'should perform a no-op if no block is given' do
        expect(instance.each).to eq(instance)
      end

      it 'should provide block each item in composition' do
        item_count = 0
        instance.each{|i| item_count += 1 }
        expect(item_count).to eq(3)
      end

      it 'should provide block with each item in order with Components first' do
        result = []
        instance.each{|item| result << item.block.call}
        expect(result).to eq([:first, :third, :second])
      end
    end
  end
end
