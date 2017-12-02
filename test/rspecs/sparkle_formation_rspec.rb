require_relative '../rspecs'

RSpec.describe SparkleFormation do
  let(:instance_args) { {} }
  let(:instance) { described_class.new('test', instance_args) { content 'value' } }

  describe '#compile' do
    describe 'compile time parameters' do
      let(:instance_args) { {:compile_time_parameters => compile_parameters} }
      context 'with basic types' do
        let(:compile_parameters) do
          {
            :fubar => {
              :type => :string,
            },
          }
        end
        it 'should serialize parameters into template' do
          instance.compile(:state => {:fubar => 'test value'})
          result = instance.dump.to_smash
          state = MultiJson.load(result.get(:Outputs, :CompileState, :Value))
          expect(state['fubar']).to eql('test value')
        end
      end
      context 'with complex types' do
        let(:compile_parameters) do
          {
            :fubar => {
              :type => :complex,
            },
          }
        end

        it 'should not serialize state into template when no value provided' do
          result = instance.dump.to_smash
          expect(result.get(:Outputs, :CompileState)).to be_nil
        end

        it 'should not serialize state into template when value is provided' do
          instance.compile(:state => {:fubar => Time.now})
          result = instance.dump.to_smash
          expect(result.get(:Outputs, :CompileState)).to be_nil
        end
      end
    end
  end
end
