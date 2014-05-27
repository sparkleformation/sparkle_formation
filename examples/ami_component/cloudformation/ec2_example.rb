SparkleFormation.new('ec2_example').load(:ami).overrides do

  description "AWS CloudFormation Sample Template EC2InstanceSample..."

  dynamic!(:ec2_instance, :my) do
    properties do
      key_name ref!(:key_name)
      image_id map!(:region_map, 'AWS::Region', :ami)
      user_data base64!('80')
    end
  end

  outputs do
    instance_id do
      description 'InstanceId of the newly created EC2 instance'
      value ref!(:my_ec2_instance)
    end
    az do
      description 'Availability Zone of the newly created EC2 instance'
      value attr!(:my_ec2_instance, :availability_zone)
    end
    public_ip do
      description 'Public IP address of the newly created EC2 instance'
      value attr!(:my_ec2_instance, :public_ip)
    end
    private_ip do
      description 'Private IP address of the newly created EC2 instance'
      value attr!(:my_ec2_instance, :private_ip)
    end
    public_dns do
      description 'Public DNSName of the newly created EC2 instance'
      value attr!(:my_ec2_instance, :public_dns_name)
    end
    private_dns do
      description 'Private DNSName of the newly created EC2 instance'
      value attr!(:my_ec2_instance, :private_dns_name)
    end
  end
end
