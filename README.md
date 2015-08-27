![SparkleFormation](img/sparkle-formation.png)

# SparkleFormation

Orchestration template building tools for Ruby.

## What's it do?

Provides a very loose DSL to describe orchestration API templates
programmatically in Ruby.

## Is that it?

Yes. Well, kinda. It also has some extra features, like defining
building blocks to facilitate code reuse in template creation,
helper functions for commonly generated data structures, builtin
logic for handling template nesting, and most importantly:
conjouring magic (to get unicorns).

## Documentation

* [Library Documentation](https://sparkleformation.github.io/sparkle_formation)
* [User Documentation](https://sparkleformation.github.io/sparkle_formation/UserDocs)

## Overview

Many template orchestration APIs accept serialized templates defining
infrastructure resources and configurations. Interacting directly with
these services via data serialization formats (JSON, YAML, etc) can be
difficult for humans. SparkleFormation allows humans to programmatically
define templates in Ruby. These are then exported into the desired
serialization format, ready to send to the target orchestration API.

## What's it look like?

Below is a simple example of an AWS CloudFormation template defined within
SparkleFormation. It creates a single EC2 resource:

```ruby
SparkleFormation.new('ec2_example') do
  description "AWS CloudFormation Sample Template ..."

  parameters.key_name do
    description 'Name of EC2 key pair'
    type 'String'
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

  dynamic!(:ec2_instance, :foobar) do
    properties do
      key_name ref!(:key_name)
      image_id map!(:region_map, region!, :ami)
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
is ready to send to the AWS CloudFormation API:

```ruby
require 'sparkle_formation'
require 'json'

puts JSON.pretty_generate(
  SparkleFormation.compile('ec2_example.rb')
)
```

Easy!

## Reusability features

SparkleFormation provides a number of features facilitating code reuse and
logical structuring. These features help aid developers in applying DRY
concepts to infrastructure codebases easing maintainability.

> [Learn more!](https://sparkleformation.github.io/sparkle_formation/UserDocs/building-blocks.html)

# Infos
* Documentation: http://sparkleformation.github.io/sparkle_formation
* User Documentation: http://sparkleformation.github.io/sparkle_formation/UserDocs/README.html
* Repository: https://github.com/sparkleformation/sparkle_formation
* IRC: Freenode @ #sparkleformation
