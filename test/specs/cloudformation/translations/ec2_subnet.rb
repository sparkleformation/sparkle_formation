SparkleFormation.new('ec2_subnet').overrides do

  parameters do
    subnet_id do
      type 'String'
    end
  end

  dynamic!(:ec2_subnet, :test_az) do
    properties do
      availability_zone azs!
      cidr_block '10.0.0.0/24'
    end
  end

  dynamic!(:ec2_subnet, :test_vpc) do
    properties do
      cidr_block '10.0.2.0/24'
      subnets [ref!(:subnet_id)]
    end
  end

end
