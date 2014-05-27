SparkleFormation.new('ec2_example') do
  description "AWS CloudFormation Sample Template EC2InstanceSample..."

  parameters do
    key_name do
      description 'Name of an existing EC2 KeyPair to enable SSH access to the instance'
      type 'String'
    end
  end

  mappings.region_map do
    _set('us-east-1', :ami => 'ami-7f418316')
    _set('us-east-1', :ami => 'ami-7f418316')
    _set('us-west-1', :ami => 'ami-951945d0')
    _set('us-west-2', :ami => 'ami-16fd7026')
    _set('eu-west-1', :ami => 'ami-24506250')
    _set('sa-east-1', :ami => 'ami-3e3be423')
    _set('ap-southeast-1', :ami => 'ami-74dda626')
    _set('ap-northeast-1', :ami => 'ami-dcfa4edd')
  end

  resources do
    my_instance do
      type 'AWS::EC2::Instance'
      properties do
        key_name _cf_ref(:key_name)
        image_id _cf_map(:region_map, 'AWS::Region', :ami)
        user_data _cf_base64('80')
      end
    end
  end

  outputs do
    instance_id do
      description 'InstanceId of the newly created EC2 instance'
      value _cf_ref(:my_instance)
    end
    az do
      description 'Availability Zone of the newly created EC2 instance'
      value _cf_attr(:my_instance, :availability_zone)
    end
    public_ip do
      description 'Public IP address of the newly created EC2 instance'
      value _cf_attr(:my_instance, :public_ip)
    end
    private_ip do
      description 'Private IP address of the newly created EC2 instance'
      value _cf_attr(:my_instance, :private_ip)
    end
    public_dns do
      description 'Public DNSName of the newly created EC2 instance'
      value _cf_attr(:my_instance, :public_dns_name)
    end
    private_dns do
      description 'Private DNSName of the newly created EC2 instance'
      value _cf_attr(:my_instance, :private_dns_name)
    end
  end
end
