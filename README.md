# SparkleFormation

AWS CloudFormation template building tools for Ruby. Yay!

## What's it do?

Provides a very loose DSL to describe an AWS CloudFormation
in Ruby.

## Is that it?

Yes. Well, kinda. It also has some extra features, like defining
components, dynamics, merging, AWS builtin function helpers, and
conjouring magic (to get unicorns).

## Expanded User Docs

New user documentation is now here! [User Documentation](http://sparkleformation.github.io/sparkle_formation/UserDocs/)

## What's it look like?

Lets use one of the example CF templates that creates an EC2 instance. First
we can just convert it into a single file (ec2_example.rb):

```ruby
SparkleFormation.new('ec2_example') do
  description "AWS CloudFormation Sample Template ..."

  parameters.keyname do
    description 'Name of EC2 key pair'
    type 'string'
  end

  mappings.region_map do
    set!('us-east-1', :ami => 'ami-7f418316')
    set!('us-east-1', :ami => 'ami-7f418316')
    set!('us-west-1', :ami => 'ami-951945d0')
    set!('us-west-2', :ami => 'ami-16fd7026')
    set!('eu-west-1', :ami => 'ami-24506250')
    set!('sa-east-1', :ami => 'ami-3e3be423')
    set!('ap-southeast-1', :ami => 'ami-74dda626')
    set!('ap-northeast-1', :ami => 'ami-dcfa4edd')
  end

  dynamic!(:ec2_instance, :foobar) do
    properties do
      key_name ref!(:key_name)
      image_id map!(:region_map, 'AWS::Region', :ami)
      user_data base64!('80')
    end
  end

  outputs do
    instance_id do
      description 'InstanceId of the newly created EC2 instance'
      value ref!(:foobar_ec2_instance)
    end
    az do
      description 'Availability Zone of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :availability_zone)
    end
    public_ip do
      description 'Public IP address of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :public_ip)
    end
    private_ip do
      description 'Private IP address of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :private_ip)
    end
    public_dns do
      description 'Public DNSName of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :public_dns_name)
    end
    private_dns do
      description 'Private DNSName of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :private_dns_name)
    end
  end
end
```

And once compiled we get a nice Hash that we can then convert to JSON which
is ready for AWS. To print:

```ruby
require 'sparkle_formation'
require 'json'

puts JSON.pretty_generate(
  SparkleFormation.compile('ec2_example.rb')
)
```

Easy!

## Why not just write JSON?

Because, who in their right mind would want to write all of that in JSON? Also,
we can start applying some of the underlying features in `SparkleFormation` to
make this easier to maintain.

# Components

Lets say we have a handful of CF templates we want to maintain, and all of those
templates use the same AMI. Instead of copying that information into all the
templates, lets create an AMI component instead, and then load it into the actual
templates.

First, create the component (components/ami.rb):

```ruby
SparkleFormation.build(:ami) do

  mappings.region_map do
    set!('us-east-1', :ami => 'ami-7f418316')
    set!('us-east-1', :ami => 'ami-7f418316')
    set!('us-west-1', :ami => 'ami-951945d0')
    set!('us-west-2', :ami => 'ami-16fd7026')
    set!('eu-west-1', :ami => 'ami-24506250')
    set!('sa-east-1', :ami => 'ami-3e3be423')
    set!('ap-southeast-1', :ami => 'ami-74dda626')
    set!('ap-northeast-1', :ami => 'ami-dcfa4edd')
  end

end
```

Now, we can modify our initial example to use this component (ec2_example.rb):

```ruby
SparkleFormation.new('ec2_example').load(:ami) do

  description "AWS CloudFormation Sample Template ..."

  parameters.keyname do
    description 'Name of EC2 key pair'
    type 'string'
  end

  dynamic!(:ec2_instance, :foobar) do
    properties do
      key_name ref!(:key_name)
      image_id map!(:region_map, 'AWS::Region', :ami)
      user_data base64!('80')
    end
  end

  outputs do
    instance_id do
      description 'InstanceId of the newly created EC2 instance'
      value ref!(:foobar_ec2_instance)
    end
    az do
      description 'Availability Zone of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :availability_zone)
    end
    public_ip do
      description 'Public IP address of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :public_ip)
    end
    private_ip do
      description 'Private IP address of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :private_ip)
    end
    public_dns do
      description 'Public DNSName of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :public_dns_name)
    end
    private_dns do
      description 'Private DNSName of the newly created EC2 instance'
      value attr!(:foobar_ec2_instance, :private_dns_name)
    end
  end
end
```

Now a few things have changed. Instead of passing a block directly to the
instance instantiation, we are loading a component (the `ami` component)
into the formation, and then applying an override block on top of the `ami`
component. The result is the same as the initial example, but now we have
a DRY component to use. Great!

## Dynamics

Okay, so lets say we want to have two ec2 instances. We could duplicate the
resource and outputs, renaming where required. This would get ugly quick,
especially as more instances are added. Making a component for the ec2 resource
won't really help since components are static, used to apply the same common
parts to multiple templates. So what do we use?

Enter `dynamics`. These are much like components, except that instead of simply
being merged, they allow passing of arguments which makes them reusable to create
unique resources. So, from our last example, lets move the ec2 related items
into a dynamic (dynamics/node.rb):

```ruby
SparkleFormation.dynamic(:node,
  :parameters => {
    :key_name => {
      :type => 'String',
      :description => 'Optionally make keypair static'
    }
  }
) do |_name, _config|

  if(_config[:key_name])
    parameters.keyname do
      description 'Name of EC2 key pair'
      type 'string'
    end
  end

  dynamic!(:ec2_instance, _name) do
    properties do
      key_name _config.fetch(:key_name, ref!(:key_name))
      image_id map!(:region_map, 'AWS::Region', :ami)
      user_data baes64!('80')
    end
  end

  outputs("#{_name}_instance_id".to_sym) do
    description 'InstanceId of the newly created EC2 instance'
    value ref!("#{_name}_ec2_instance".to_sym)
  end
  outputs("#{_name}_az".to_sym) do
    description 'Availability Zone of the newly created EC2 instance'
    value attr!("#{_name}_ec2_instance".to_sym, :availability_zone)
  end
  outputs("#{_name}_public_ip".to_sym) do
    description 'Public IP address of the newly created EC2 instance'
    value attr!("#{_name}_ec2_instance".to_sym, :public_ip)
  end
  outputs("#{_name}_private_ip".to_sym) do
    description 'Private IP address of the newly created EC2 instance'
    value attr!("#{_name}_ec2_instance".to_sym, :private_ip)
  end
  outputs("#{_name}_public_dns".to_sym) do
    description 'Public DNSName of the newly created EC2 instance'
    value attr!("#{_name}_ec2_instance".to_sym, :public_dns_name)
  end
  outputs("#{_name}_private_dns".to_sym) do
    description 'Private DNSName of the newly created EC2 instance'
    value attr!("#{_name}_ec2_instance".to_sym, :private_dns_name)
  end
end
```

Now we can put all of these together, and create multiple ec2 instance
resource easily:

```ruby
SparkleFormation.new('ec2_example').load(:ami).overrides do

  description "AWS CloudFormation Sample Template ..."

  %w(node1 node2 node3).each do |_node_name|
    dynamic!(:node, _node_name)
  end

  # and include one with predefined keypair

  dynamic!(:node, 'snowflake', :key_pair => 'snowkeys')
end
```

## TODO
* Add information about symbol importance
* Add examples of camel case control
* Add examples of complex merge strategies
* Add examples of accessing parent hash elements

# Infos
* Documentation: http://sparkleformation.github.io/sparkle_formation
* User Documentation: http://sparkleformation.github.io/sparkle_formation/UserDocs/README.html
* Repository: https://github.com/sparkleformation/sparkle_formation
* IRC: Freenode @ #heavywater
