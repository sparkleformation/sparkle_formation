require_relative "../spec"

describe SparkleFormation do
  before { SparkleFormation._cleanify! }

  before do
    SparkleFormation.sparkle_path = File.join(File.dirname(__FILE__), "sparkleformation")
  end

  describe "Dummy template" do
    it "should build the dummy template" do
      result = SparkleFormation.compile("dummy.rb")
      _(result).must_be :is_a?, Hash
      _(result.to_smash.get("Outputs", "Dummy", "Value")).must_equal "Dummy value"
      _(result.to_smash.get("Parameters", "Creator", "Default")).must_equal "Fubar"
    end
  end

  describe "Nested template" do
    it "should build the nested template" do
      result = SparkleFormation.compile("nest.rb")
      simple = SparkleFormation.compile("simple.rb")
      dummy = SparkleFormation.compile("dummy.rb")
      _(result).must_be :is_a?, Hash
      _(simple).must_be :is_a?, Hash
      _(dummy).must_be :is_a?, Hash
      _(result.to_smash.get("Resources", "Dummy", "Properties", "Stack").to_json).must_equal dummy.to_smash.to_json
      _(result.to_smash.get("Resources", "Simple", "Properties", "Stack").to_json).must_equal simple.to_smash.to_json
      _(result.to_smash.get("Resources", "DummySecond")).wont_be_nil
      _(result.to_smash.get("Resources", "DummySecond", "Properties", "Stack").to_json).must_equal dummy.to_smash.to_json
      _(result.to_smash.get("Resources", "Third")).wont_be_nil
      _(result.to_smash.get("Resources", "Third", "Properties", "Stack").to_json).must_equal dummy.to_smash.to_json
    end

    it "should pass loaded packs to nested templates" do
      template = SparkleFormation.compile("pack-nester.rb", :sparkle)
      template.sparkle.add_sparkle(
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs/valid_pack"),
        )
      )
      result = template.dump.to_smash
      _(result.get("Resources", "PackTemplate", "Properties", "Stack", "AwsDynamic")).must_equal true
    end
  end

  describe "Component registry usage" do
    it "should properly handle multiple registry requests" do
      result = SparkleFormation.compile("registry_in_component.rb")
      _(result["Complete"]).must_equal true
    end
  end

  describe "Hash loading within template" do
    it "should properly load Hash types into struct instances" do
      result = SparkleFormation.compile("hash_loading_root.rb", :sparkle)
      _(result.apply_nesting { |*_| }).wont_be_nil
    end
  end

  describe "Custom error output" do
    it "should provide file and line number of error" do
      e = nil
      begin
        SparkleFormation.compile("type_error")
      rescue => e
      end
      _(e.message).must_be :include?, "type_error.rb"
      _(e.message).must_be :include?, "line 2"
    end

    it "should provide expected error when using sparkle_formation path" do
      e = nil
      begin
        SparkleFormation.compile("path_test")
      rescue => e
      end
      _(e.message).must_be :include?, "sparkle_formation/path_test.rb"
      _(e.message).must_be :include?, "line 2"
    end
  end

  describe "List types with shallow nesting" do
    it "should properly join lists when passing to stack resource" do
      result = SparkleFormation.compile("nest_list.rb", :sparkle)
      result.apply_nesting(:shallow) { |*_| }
      result = result.dump.to_smash
      _(result.get("Resources", "ListParameters", "Properties", "Parameters", "BasicString").keys.first).must_equal "Ref"
      _(result.get("Resources", "ListParameters", "Properties", "Parameters", "CommaList").keys.first).must_equal "Fn::Join"
      _(result.get("Resources", "ListParameters", "Properties", "Parameters", "TypeList").keys.first).must_equal "Fn::Join"
    end
  end
end
