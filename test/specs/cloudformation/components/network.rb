SparkleFormation.new('network') do
  _set('AWSTemplateFormatVersion', '2010-09-09')

  description 'Network Only Stack'

  resources do
    network do
      type "AWS::EC2::Subnet"
      properties do
        cidr_block "10.20.30.0/24"
      end
    end
  end
end

