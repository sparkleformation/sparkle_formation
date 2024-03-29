require_relative "../../spec"

describe SparkleFormation::SparkleAttribute::Heat do
  before do
    klass = Class.new(AttributeStruct)
    klass.include(SparkleFormation::SparkleAttribute)
    klass.include(SparkleFormation::SparkleAttribute::Heat)
    klass.include(SparkleFormation::Utils::TypeCheckers)
    @attr = klass.new
    @attr._camel_keys = false
    @sfn = SparkleFormation.new(:test, :provider => :heat)
  end

  it "should generate get_attr" do
    _(@attr.attr!(:resource_name, :attribute_name)).must_equal "get_attr" => ["resource_name", "attribute_name"]
  end

  it "should generate list_join" do
    _(@attr.join!("v1", "v2")).must_equal "list_join" => ["", ["v1", "v2"]]
  end

  it "should generate list_join with custom delimiter" do
    _(@attr.join!("v1", "v2", :options => {:delimiter => ","})).must_equal "list_join" => [",", ["v1", "v2"]]
  end

  it "should generate get_file" do
    _(@attr.file!("http://example.com/file.txt")).must_equal "get_file" => "http://example.com/file.txt"
  end

  it "should generate get_param" do
    _(@attr.param!(:param_name)).must_equal "get_param" => "param_name"
  end

  it "should generate get_param with index" do
    _(@attr.param!(:param_name, :metadata)).must_equal "get_param" => ["param_name", "metadata"]
  end

  it "should generate get_resource" do
    _(@attr.resource!(:my_resource)).must_equal "get_resource" => "my_resource"
  end

  it "should generate digest" do
    _(@attr.digest!("value")).must_equal "digest" => ["sha512", "value"]
  end

  it "should generate digest with custom algorithm" do
    _(@attr.digest!("value", "sha256")).must_equal "digest" => ["sha256", "value"]
  end

  it "should generate resource_facade" do
    _(@attr.facade!("metadata")).must_equal "resource_facade" => "metadata"
  end

  it "should generate str_replace" do
    _(@attr.replace!("%t%", "t" => "value")).must_equal "str_replace" => {"template" => "%t%", "params" => {"t" => "value"}}
  end

  it "should generate str_split" do
    _(@attr.split!(" ", "the string")).must_equal "str_split" => [" ", "the string"]
  end

  it "should generate str_split with index" do
    _(@attr.split!(" ", "the string", 5)).must_equal "str_split" => [" ", "the string", 5]
  end

  it "should generate map_merge" do
    _(@attr.map_merge!({"a" => 1}, {"b" => 2})).must_equal "map_merge" => [{"a" => 1}, {"b" => 2}]
  end

  it "should generate stack ID" do
    _(@attr.stack_id!).must_equal "get_param" => "OS::stack_id"
  end

  it "should generate stack name" do
    _(@attr.stack_name!).must_equal "get_param" => "OS::stack_name"
  end

  it "should generate project ID" do
    _(@attr.project_id!).must_equal "get_param" => "OS::project_id"
  end

  it "should generate stack output structure" do
    _(@attr.stack_output!(:stack_name, :output_name)).must_equal "get_attr" => ["stack_name", "output_name"]
  end

  it "should generate and set depends on information" do
    @sfn.overrides do
      my_resource do
        depends_on! :other_resource
      end
      other_resource do
        depends_on! :my_resource, :unknown_resource
      end
    end
    _(@sfn.dump).must_equal(
      "my_resource" => {
        "depends_on" => [
          "other_resource",
        ],
      },
      "other_resource" => {
        "depends_on" => [
          "my_resource",
          "unknown_resource",
        ],
      },
    )
  end
end
