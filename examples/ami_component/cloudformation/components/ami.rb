SparkleFormation.build do

  parameters do
    key_name do
      description 'Name of an existing EC2 KeyPair to enable SSH access to the instance'
      type 'String'
    end
  end

  mappings.region_map do
    set!('us-east-1'._no_hump, :ami => 'ami-7f418316')
    set!('us-west-1'._no_hump, :ami => 'ami-951945d0')
    set!('us-west-2'._no_hump, :ami => 'ami-16fd7026')
    set!('eu-west-1'._no_hump, :ami => 'ami-24506250')
    set!('sa-east-1'._no_hump, :ami => 'ami-3e3be423')
    set!('ap-southeast-1'._no_hump, :ami => 'ami-74dda626')
    set!('ap-northeast-1'._no_hump, :ami => 'ami-dcfa4edd')
  end

end
