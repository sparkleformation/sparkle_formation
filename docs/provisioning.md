## Provisioning SparkleFormations

### JSON Templates

Generating JSON from a SparkleFormation template is as simple as
calling `SparkleFormation.compile()` on the template file. Here's a simple
script to output a JSON template from a supplied
SparkeFormation template:

```ruby
#!/usr/bin/env ruby
require 'sparkle_formation'
require 'json'

puts SparkleFormation.compile(ARGV[0])
```

The output can be written to a file and uploaded to the provider using
the method of your choice.

For a more legible template:

```ruby
puts JSON.pretty_generate(SparkleFormation.compile(ARGV[0]))
```

Note: The output from this command may not be usable with cloud providers,
as the many spaces and newlines may exceed the cloudformation
character limit. However, it is much easier to read.

### Knife Cloudformation
knife-cloudformation [knife-cloudformation plugin](https://rubygems.org/gems/knife-cloudformation) is a plugin for
knife that provisions cloudformation stacks. It can be used with
SparkleFormation to build stacks without the intermediary steps of
writing a JSON template to file and uploading the template to the provider.

#### Knife Cloudformation Setup

```ruby
gem 'knife-cloudformation'
```

```
$ gem install knife-cloudformation
```

Add the following to your `knife.rb` file:
```ruby
knife[:aws_access_key_id] = ENV['AWS_ACCESS_KEY_ID']
knife[:aws_secret_access_key] = ENV['AWS_SECRET_ACCESS_KEY']

[:cloudformation, :options].inject(knife){ |m,k| m[k] ||= Mash.new }
knife[:cloudformation][:options][:disable_rollback] = true
knife[:cloudformation][:options][:capabilities] = ['CAPABILITY_IAM']
knife[:cloudformation][:processing] = true
knife[:cloudformation][:credentials] = {
  :aws_region => knife[:region],
  :aws_access_key_id => knife[:aws_access_key_id],
  :aws_secret_access_key => knife[:aws_secret_access_key]
}
# If you are using nested stacks add bucket to store templates. Note
# that the bucket must exist (the library will not auto-create it)
knife[:cloudformation][:nesting_bucket] = 'my-cfn-nested-stacks'

```

| Attribute                                        | Function                                                                                                       |
|--------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| `[:cloudformation][:options][:disable_rollback]` | Disables rollback if stack is unsuccessful. Useful for debugging.                                              |
| `[:cloudformation][:credentials]`                | Credentials for a user that is allowed to create stacks.                                                       |
| `[:cloudformation][:options][:capabilities]`     | Enables IAM creation (AWS only). Options are `nil` or `['CAPABILITY_IAM']`                                     |
| `[:cloudformation][:processing]`                 | Enables processing SparkleFormation templates (otherwise knife cloudformation will expect a JSON CFN template. |

#### Processing SparkleFormation Templates
To build a stack directly from a SparkleFormation template, use the
`create` command with the `--file` and `--processing` flags:

```
knife cloudformation create my-web-stack --file templates/website.rb --processing
```

`--file` directs knife to a file under the `cloudformation` directory,
and `--processing` tells knife to render JSON from the
SparkleFormation template before passing it to the provider.

#### Applying Stacks
You can also apply an existing stack's outputs to the stack you are
building. Using the `--apply-stack` flag sets parameters to the
values of any matching outputs.

Consider that you have built a database stack (`db-stack-01`) that includes an output for the
database endpoint:

```ruby
outputs do
  database_endpoint do
    value attr!(:database_elb, 'DNSName')
    description "Database ELB Endpoint for client connections"
  end
end
```

Next, you build a website stack (`web-stack-01`) that needs to connect to the
database. The SparkleFormation for this stack includes a parameter to
prompt for the database endpoint:

```ruby
parameters.database_endpoint do
  type 'String'
  description 'Database endpoint to connect to'
  default 'localhost'
end
```

Using knife-cloudformation, you apply the database stack in order to
automatically provide the correct database endpoint:

`knife cloudformation create web-stack-01 --file templates/website.rb --processing --apply-stack db-stack-01`
