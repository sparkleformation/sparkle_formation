SparkleFormation.build do

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

end
