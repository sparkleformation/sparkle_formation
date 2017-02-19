require_relative '../rspecs'

RSpec.describe SparkleFormation::Resources do
  before{ described_class.registry.clear if described_class.registry }

  describe '#base_key' do
    it 'should return "resources" string' do
      expect(described_class.base_key).to eq('resources')
    end
  end

  describe '#register' do
    it 'should return true when registering a new type' do
      expect(described_class.register('example', {})).to be(true)
    end

    it 'should raise error when type information is not a Hash' do
      expect{ described_class.register('example', true) }.to raise_error(TypeError)
    end
  end

  describe '#load' do
    context 'with Hash data' do
      it 'should register new data into resources' do
        expect(described_class.load('example' => {'data' => 'value'})).to be(true)
        expect(described_class.resource(:example)).to eq('data' => 'value')
      end
    end

    context 'with String data' do
      before do
        @tmp_file = Tempfile.new('sparkle-formation')
        @tmp_file.puts({'example' => {'data' => 'value'}}.to_json)
        @tmp_file.close
      end
      after{ @tmp_file.delete if @tmp_file }

      it 'should register data from file' do
        expect(described_class.load(@tmp_file.path)).to be(true)
        expect(described_class.resource(:example)).to eq('data' => 'value')
      end

      it 'should raise error if file does not exist' do
        path = @tmp_file.path
        @tmp_file.delete
        expect{ described_class.load(path) }.to raise_error(Errno::ENOENT)
      end
    end

    context 'with unsupported data type' do
      it 'should raise ArgumentError' do
        expect{ described_class.load(true) }.to raise_error(TypeError)
      end
    end
  end
end
