## Knife Cloudformation

knife-cloudformation [knife-cloudformation plugin](https://rubygems.org/gems/knife-cloudformation) is a plugin for
knife that provisions cloudformation stacks. It can be used with
SparkleFormation to build stacks without the intermediary steps of
writing a json template to file and uploading the template to the provider.

### Processing SparkleFormation Templates

To build a stack directly from a SparkleFormation template, use the
`create` command with the `--file` and `--processing` flags:

```
knife cloudformation create my-web-stack --file templates/website.rb --processing
```

`--file` directs knife to a file under the `cloudformation` directory,
and `--processing` tells knife to render a json template using
SparkleFormation. 
         
### Applying Stacks

You can also apply an existing stack's outputs to the stack you are
building. Using the `--apply-stack` flag sets parameters are to the
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
                             
