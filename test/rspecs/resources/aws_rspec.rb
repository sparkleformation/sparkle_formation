require_relative '../../rspecs'

RSpec.describe SparkleFormation::Resources::Aws do

  describe "#registry_key" do
    context "with registry loaded" do
      before{ described_class.load! }

      it 'should lookup resource using full name' do
        expect(described_class.registry_key('aws_ec2_instance')).to eq('AWS::EC2::Instance')
      end

      it 'should lookup resource using partial name' do
        expect(described_class.registry_key('ec2_instance')).to eq('AWS::EC2::Instance')
      end

      it 'should raise ArgumentError when multiple matches are found' do
        expect{ described_class.registry_key('instance') }.to raise_error ArgumentError
      end
    end
  end
end
