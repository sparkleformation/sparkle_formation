require_relative "../spec"

describe SparkleFormation::SparkleAttribute do
  before { SparkleFormation._cleanify! }

  before do
    @attr = Object.new
    @attr.extend(SparkleFormation::SparkleAttribute)
    @attr.extend(SparkleFormation::Utils::TypeCheckers)
    @sfn = SparkleFormation.new(:test)
  end

  it "should execute a system command" do
    _(@attr.system!("ls #{File.expand_path(__FILE__)}")).must_include "sparkle_attribute_spec.rb"
  end

  it "should print to stdout" do
    output = capture_stdout do
      @attr.puts! 111
    end
    _(output).must_equal "111\n"
  end

  it "should raise an exception" do
    _{ @attr.raise! RuntimeError }.must_raise RuntimeError
  end

  it "should provide method access" do
    _(@attr.method!(:system!)).must_be_kind_of Method
  end
end
