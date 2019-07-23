require_relative "../../spec"

describe SparkleFormation::SparkleAttribute::Aws do
  before do
    klass = Class.new(AttributeStruct)
    klass.include(SparkleFormation::SparkleAttribute)
    klass.include(SparkleFormation::SparkleAttribute::Aws)
    klass.include(SparkleFormation::Utils::TypeCheckers)
    @attr = klass.new
    @attr._camel_keys = true
    @sfn = SparkleFormation.new(:test, :provider => :aws)
  end

  it "should generate Fn::Join" do
    @attr.join!("a", "b", "c").must_equal "Fn::Join" => ["", ["a", "b", "c"]]
  end

  it "should generate Fn::Join with custom delimiter" do
    @attr.join!("a", "b", "c", :options => {:delimiter => "-"}).
      must_equal "Fn::Join" => ["-", ["a", "b", "c"]]
  end

  it "should generate Ref" do
    @attr.ref!("Item").must_equal "Ref" => "Item"
  end

  it "should process symbol when generating Ref" do
    @sfn.overrides do
      thing ref!(:item)
    end.dump.must_equal "Thing" => {"Ref" => "Item"}
  end

  it "should generate Fn::ImportValue" do
    @sfn.overrides do
      thing import_value!("MyUniqueOutput")
    end.dump.
      must_equal "Thing" => {"Fn::ImportValue" => "MyUniqueOutput"}
  end

  it "should generate Fn::FindInMap" do
    @sfn.overrides do
      thing find_in_map!("MyMap", ref!("MyKey"), "SubKey")
    end.dump.
      must_equal "Thing" => {"Fn::FindInMap" => ["MyMap", {"Ref" => "MyKey"}, "SubKey"]}
  end

  it "should generate Fn::GetAtt" do
    @sfn.overrides do
      thing attr!(:resource, "my_instance", :ip_address)
    end.dump.
      must_equal "Thing" => {"Fn::GetAtt" => ["Resource", "my_instance", "IpAddress"]}
  end

  it "should generate Fn::Base64" do
    @attr.base64!("my string!").must_equal "Fn::Base64" => "my string!"
  end

  it "should generate Fn::GetAZs" do
    @attr.azs!.must_equal "Fn::GetAZs" => ""
  end

  it "should generate Fn::GetAZs with argument" do
    @attr.azs!("fubar").must_equal "Fn::GetAZs" => "fubar"
  end

  it "should generate Fn::GetAZs with Ref when provided symbol" do
    @sfn.overrides do
      thing azs!(:item)
    end.dump.
      must_equal "Thing" => {"Fn::GetAZs" => {"Ref" => "Item"}}
  end

  it "should generate Fn::Select" do
    @attr.select!(1, "fubar").must_equal "Fn::Select" => [1, "fubar"]
    @attr.select!("1", "fubar").must_equal "Fn::Select" => ["1", "fubar"]
  end

  it "should generate Fn::Select with Ref when provided symbol" do
    @sfn.overrides do
      thing select!(:param, :fubar)
    end.dump.
      must_equal "Thing" => {"Fn::Select" => [{"Ref" => "Param"}, {"Ref" => "Fubar"}]}
  end

  it "should generate a condition with consistent format when string" do
    @attr.condition!("test_name"._no_hump).must_equal "Condition" => "test_name"
  end

  it "should generate a condition with camelized name when symbol" do
    @sfn.overrides do
      test condition!(:test_name)
    end.dump["Test"].must_equal "Condition" => "TestName"
  end

  it "should set a condition directly into context" do
    @sfn.overrides do
      on_condition! :test_name
    end.dump["Condition"].must_equal "TestName"
  end

  it "should define an if condition" do
    result = @sfn.overrides do
      test if!(:my_condition, "true", "false")
      test_string if!("my_condition"._no_hump, "true", "false")
    end.dump
    result["Test"].must_equal "Fn::If" => ["MyCondition", "true", "false"]
    result["TestString"].must_equal "Fn::If" => ["my_condition", "true", "false"]
  end

  it "should define an `and`" do
    result = @sfn.overrides do
      test and!(:test_one, :test_two)
      test_direct and!(condition!(:test_one), :test_two)
    end.dump
    result["Test"].must_equal "Fn::And" => [{"Condition" => "TestOne"}, {"Condition" => "TestTwo"}]
    result["TestDirect"].must_equal "Fn::And" => [{"Condition" => "TestOne"}, {"Condition" => "TestTwo"}]
  end

  it "should define an `equals`" do
    result = @sfn.overrides do
      test equals!(:test_one, :test_two)
      test_direct equals!(ref!(:test_one), :test_two)
    end.dump
    result["Test"].must_equal "Fn::Equals" => ["test_one", "test_two"]
    result["TestDirect"].must_equal "Fn::Equals" => [{"Ref" => "TestOne"}, "test_two"]
  end

  it "should define a `not`" do
    result = @sfn.overrides do
      test not!(:test_one)
      test_string not!("test_one"._no_hump)
      test_direct not!(condition!(:test_one))
    end.dump
    result["Test"].must_equal "Fn::Not" => [{"Condition" => "TestOne"}]
    result["TestString"].must_equal "Fn::Not" => [{"Condition" => "test_one"}]
    result["TestDirect"].must_equal "Fn::Not" => [{"Condition" => "TestOne"}]
  end

  it "should define an `or`" do
    result = @sfn.overrides do
      test or!(:test_one, :test_two)
      test_direct or!(condition!(:test_one), :test_two)
    end.dump
    result["Test"].must_equal "Fn::Or" => [{"Condition" => "TestOne"}, {"Condition" => "TestTwo"}]
    result["TestDirect"].must_equal "Fn::Or" => [{"Condition" => "TestOne"}, {"Condition" => "TestTwo"}]
  end

  it "should return string from system command" do
    @sfn.overrides do
      test system!("ls -la")
    end.dump["Test"].must_include("..")
  end

  it "should generate a `no value`" do
    @attr.no_value!.must_equal "Ref" => "AWS::NoValue"
  end

  it "should generate a region ref" do
    @attr.region!.must_equal "Ref" => "AWS::Region"
  end

  it "should generate a notification arns ref" do
    @attr.notification_arns!.must_equal "Ref" => "AWS::NotificationARNs"
  end

  it "should generate an account ID ref" do
    @attr.account_id!.must_equal "Ref" => "AWS::AccountId"
  end

  it "should generate a stack ID ref" do
    @attr.stack_id!.must_equal "Ref" => "AWS::StackId"
  end

  it "should generate a stack name ref" do
    @attr.stack_name!.must_equal "Ref" => "AWS::StackName"
  end

  it "should generate a partition ref" do
    @attr.partition!.must_equal "Ref" => "AWS::Partition"
  end

  it "should generate a URL suffix ref" do
    @attr.url_suffix!.must_equal "Ref" => "AWS::URLSuffix"
  end

  it "should generate a depends on array" do
    @attr.depends_on!("ResourceOne", :resource_two).must_equal ["ResourceOne", "ResourceTwo"]
    @attr._dump.must_equal "DependsOn" => ["ResourceOne", "ResourceTwo"]
  end

  it "should generate a stack output attribute" do
    @attr.stack_output!(:stack_resource, :output_name).must_equal(
      "Fn::GetAtt" => ["StackResource", "Outputs.OutputName"],
    )
    @attr.stack_output!("stack_resource", "output_name").must_equal(
      "Fn::GetAtt" => ["StackResource", "Outputs.OutputName"],
    )
  end

  it "should generate a hash of tags" do
    @attr.tags!(:foo => "bar").must_equal([
      "Key" => "Foo",
      "Value" => "bar",
    ])
    @attr._dump.must_equal(
      "Tags" => [
        "Key" => "Foo",
        "Value" => "bar",
      ],
    )
  end

  it "should provide resource name for resource block" do
    result = @sfn.overrides do
      resources.my_custom_resource do
        properties do
          resource_name resource_name!
          nested do
            resource_name resource_name!
          end
        end
        my_name resource_name!
      end
    end.dump
    result["Resources"]["MyCustomResource"]["MyName"].must_equal "MyCustomResource"
    result["Resources"]["MyCustomResource"]["Properties"]["ResourceName"].must_equal "MyCustomResource"
    result["Resources"]["MyCustomResource"]["Properties"]["Nested"]["ResourceName"].must_equal "MyCustomResource"
  end
end
