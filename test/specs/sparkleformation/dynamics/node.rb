SparkleFormation.dynamic(:node) do |_name, _config|
  parameters do
    key_name do
      description 'Name of an existing EC2 KeyPair to enable SSH access to the instance'
      type 'String'
    end
  end

  dynamic!(:ec2_instance, _name) do
    properties do
      key_name ref!(:key_name)
    end
  end
end
