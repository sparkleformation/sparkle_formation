## Stack Policies

AWS CloudFormation includes support for stack policies. These
policies add an extra layer of control that restricts or allows
actions to be taken on specific resources within a stack.
SparkleFormation includes support for extracting inline stack
policy information from SparkleFormation templates which can
then be applied to stacks.

* [AWS CFN Stack Policies](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html)

### Template Usage

Resource policies can be defined within a SparkleFormation
template. This allows for policies to be programatically generated
in the same manner as the stack template itself.

```ruby
```

### Library Usage

SparkleFormation can extract stack policies from a template after
it has been compiled. Once extracted, the policy can be applied
to the stack as dictated by the API.

```ruby
template = SparkleFormation.new(:test) do
  resources.my_resource do
    policy do
      allow 'Modify'
      deny 'Replace'
    end
  end
end

policy = template.generate_policy
```

This generates a policy data structure:

```ruby
{
  "Statement" => [
    {
      "Effect" => "Allow",
      "Action" => [
        "Update:*"
      ],
      "Resource" => "*",
      "Principal" => "*"
    },
    {
      "Effect" => "Allow",
      "Action" => [
        "Update:Modify"
      ],
      "Resource" => "LogicalResourceId/MyResource",
      "Principal" => "*"
    },
    {
      "Effect" => "Deny",
      "Action" => [
        "Update:Replace"
      ],
      "Resource" => "LogicalResourceId/MyResource",
      "Principal" => "*"
    }
  ]
}
```