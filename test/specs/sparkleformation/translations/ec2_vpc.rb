SparkleFormation.new('vpc').overrides do
  dynamic!(:ec2_vpc, :test) do
    properties do
      cidr_block '10.0.0.2/24'
    end
  end
end
