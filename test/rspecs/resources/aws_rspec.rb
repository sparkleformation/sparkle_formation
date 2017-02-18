require_relative '../../rspecs'

RSpec.describe SparkleFormation::Resources::Aws do
  before do
    described_class.unmemoize(:aws_resources, :global)
    if(described_class.registry)
      described_class.registry.clear
    end
  end

  describe '#base_key' do
    it 'should return "aws" string' do
      expect(described_class.base_key).to eq('aws')
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

  describe '#resource' do
    before{ described_class.load! }

    it 'should return resource information' do
      expect(described_class.resource(:aws_ec2_instance)).to be_a(Hash)
    end

    it 'should return nil if resource cannot be found' do
      expect(described_class.resource(:unknown_resource)).to be_nil
    end

    context 'with data key provided' do
      it 'should return specific resource data if resource exists' do
        expect(described_class.resource(:aws_ec2_instance, :properties)).to be_a(Array)
      end

      it 'should return nil if resource cannot be found' do
        expect(described_class.resource(:unknown_resource, :properties)).to be_nil
      end
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

  describe '#registry_key' do
    context 'with registry loaded' do
      before{ described_class.load! }

      it 'should return key when exact key provided' do
        expect(described_class.registry_key('AWS::EC2::Instance')).to eq('AWS::EC2::Instance')
      end

      it 'should return key when partial key provided' do
        expect(described_class.registry_key('EC2::Instance')).to eq('AWS::EC2::Instance')
      end

      it 'should return key using snake cased full name' do
        expect(described_class.registry_key('aws_ec2_instance')).to eq('AWS::EC2::Instance')
      end

      it 'should return key using snake cased partial name' do
        expect(described_class.registry_key('ec2_instance')).to eq('AWS::EC2::Instance')
      end

      it 'should raise ArgumentError when multiple matches are found' do
        expect{ described_class.registry_key('instance') }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#lookup' do
    before{ described_class.load! }

    it 'should lookup resource with full name' do
      expect(described_class.lookup('AWS::EC2::Instance')).to be_a(Hash)
    end

    it 'should lookup resource with partial name' do
      expect(described_class.lookup('EC2::Instance')).to be_a(Hash)
    end

    it 'should lookup resource with snake cased full name' do
      expect(described_class.lookup('aws_ec2_instance')).to be_a(Hash)
    end

    it 'should lookup resource with snake cased partial name' do
      expect(described_class.lookup('ec2_instance')).to be_a(Hash)
    end

    it 'should raise ArgumentError when multiple matches are found' do
      expect{ described_class.lookup('instance') }.to raise_error(ArgumentError)
    end

    it 'should return nil if no match found' do
      expect(described_class.lookup('example')).to be_nil
    end
  end

  describe '#registry' do
    context 'with data loaded' do
      before{ described_class.load! }

      it 'should return the data Hash' do
        expect(described_class.registry).to be_a(Hash)
      end
    end
  end

  describe '#resource_lookup' do
    before{ described_class.load! }

    it 'should return a Resource if found' do
      expect(described_class.resource_lookup('AWS::EC2::Instance')).to be_a(SparkleFormation::Resources::Resource)
    end

    it 'should raise error if resource is not found' do
      expect{ described_class.resource_lookup(:example) }.to raise_error(KeyError)
    end
  end
end
