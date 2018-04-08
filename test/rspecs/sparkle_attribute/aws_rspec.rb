require_relative "../../rspecs"

RSpec.describe SparkleFormation::SparkleAttribute::Aws do
  let(:instance) do
    klass = Class.new(SparkleFormation::SparkleStruct)
    klass.include(described_class)
    klass.new
  end

  describe "#_cf_join" do
    it "should create join function data structure" do
      expect(instance._cf_join("a", "b", "c")).to eq("Fn::Join" => ["", ["a", "b", "c"]])
    end

    it "should create join with custom delimiter" do
      result = instance._cf_join("a", "b", :options => {:delimiter => ","})
      expect(result).to eq("Fn::Join" => [",", ["a", "b"]])
    end
  end

  describe "#_cf_split" do
    it "should create split data structure" do
      expect(instance._cf_split("string", ".")).to eq("Fn::Split" => [".", "string"])
    end

    it "should raise error if non-String value provided" do
      expect { instance._cf_split(true, ".") }.to raise_error(TypeError)
    end

    it "should raise error if non-String delimiter provided" do
      expect { instance._cf_split("string", true) }.to raise_error(TypeError)
    end
  end

  describe "#_cf_sub" do
    it "should create sub data structure" do
      expect(instance._cf_sub("string", "Var1" => "Val1")).to eq("Fn::Sub" => ["string", "Var1" => "Val1"])
    end

    it "should create sub data structure with no variables" do
      expect(instance._cf_sub("string")).to eq("Fn::Sub" => "string")
    end

    it "should raise error if non-Hash variables argument provided" do
      expect { instance._cf_sub("string", "variables") }.to raise_error(TypeError)
    end
  end

  describe "#_cf_ref" do
    it "should create ref data structure" do
      expect(instance._cf_ref("item")).to eq("Ref" => "Item")
    end

    it "should raise error if non-String value provided" do
      expect { instance._cf_ref(true) }.to raise_error(TypeError)
    end
  end

  describe "#_cf_value_import" do
    it "should create import value data structure" do
      expect(instance._cf_value_import("item")).to eq("Fn::ImportValue" => "Item")
    end

    it "should raise error if non-String value provided" do
      expect { instance._cf_value_import(true) }.to raise_error(TypeError)
    end
  end

  describe "#_cf_map" do
    it "should create map data structure" do
      result = instance._cf_map("map_name", "top_key", "second_key")
      expect(result).to eq("Fn::FindInMap" => ["MapName", "top_key", "second_key"])
    end

    it "should error if map name is not a Stringish value" do
      expect { instance._cf_map(true, "a", "b") }.to raise_error(TypeError)
    end

    it "should accept data structures for top level key" do
      result = instance._cf_map("map_name", instance._cf_ref("item"), "thing")
      expect(result).to eq("Fn::FindInMap" => ["MapName", {"Ref" => "Item"}, "thing"])
    end
  end

  describe "#_cf_attr" do
    it "should create attr data structure" do
      result = instance._cf_attr("resource", "attribute")
      expect(result).to eq("Fn::GetAtt" => ["Resource", "attribute"])
    end

    it "should force key processing on Symbol attribute" do
      result = instance._cf_attr("resource", :attribute)
      expect(result).to eq("Fn::GetAtt" => ["Resource", "Attribute"])
    end

    it "should raise error if non-String resource name provided" do
      expect { instance._cf_attr(true) }.to raise_error(TypeError)
    end
  end

  describe "#_cf_base64" do
    it "should create base64 data structure" do
      expect(instance._cf_base64("item")).to eq("Fn::Base64" => "item")
    end
  end

  describe "#_cf_get_azs" do
    it "should create get AZs data structure" do
      expect(instance._cf_get_azs).to eq("Fn::GetAZs" => "")
    end

    it "should accept specific region" do
      expect(instance._cf_get_azs("region")).to eq("Fn::GetAZs" => "region")
    end

    it "should convert region Symbol into ref data structure" do
      expect(instance._cf_get_azs(:region)).to eq("Fn::GetAZs" => {"Ref" => "Region"})
    end
  end

  describe "#_cf_select" do
    it "should create select data structure" do
      expect(instance._cf_select(0, {"Ref" => "Item"})).to eq("Fn::Select" => [0, {"Ref" => "Item"}])
    end

    it "should convert target to ref data structure if Symbol provided" do
      expect(instance._cf_select(0, :item)).to eq("Fn::Select" => [0, {"Ref" => "Item"}])
    end
  end

  describe "#_condition" do
    it "should create condition data structure" do
      expect(instance._condition("item")).to eq("Condition" => "Item")
    end

    it "should raise error if condition name is not a String" do
      expect { instance._condition(true) }.to raise_error(TypeError)
    end
  end

  describe "#_on_condition" do
    it "should add a condition data structure into the underlying data" do
      instance._on_condition("item")
      expect(instance._dump).to eq("Condition" => "Item")
    end
  end

  describe "#_if" do
    it "should create an if data structure" do
      expect(instance._if("condition", true, false)).to eq("Fn::If" => ["Condition", true, false])
    end
  end

  describe "#_and" do
    it "should create an and data structure of two conditions" do
      result = instance._and("cond_one", "cond_two")
      expect(result).to eq("Fn::And" => [{"Condition" => "CondOne"}, {"Condition" => "CondTwo"}])
    end

    it "should create an and data structure without conversions" do
      result = instance._and({"Condition" => "one"}, {"Condition" => "two"})
      expect(result).to eq("Fn::And" => [{"Condition" => "one"}, {"Condition" => "two"}])
    end
  end

  describe "#_equals" do
    it "should create an equals data structure" do
      expect(instance._equals("one", "two")).to eq("Fn::Equals" => ["one", "two"])
    end
  end

  describe "#_not" do
    it "should create a not data structure" do
      expect(instance._not({"Condition" => "item"})).to eq("Fn::Not" => [{"Condition" => "item"}])
    end

    it "should auto convert String argument into condition" do
      expect(instance._not("item")).to eq("Fn::Not" => [{"Condition" => "Item"}])
    end
  end

  describe "#_or" do
    it "should create an or data structure" do
      result = instance._or({"Condition" => "one"}, {"Condition" => "two"})
      expect(result).to eq("Fn::Or" => [{"Condition" => "one"}, {"Condition" => "two"}])
    end

    it "should auto convert String arguments into conditions" do
      result = instance._or("one", "two")
      expect(result).to eq("Fn::Or" => [{"Condition" => "One"}, {"Condition" => "Two"}])
    end
  end

  describe "#_no_value" do
    it "should create a no data data structure" do
      expect(instance._no_value).to eq("Ref" => "AWS::NoValue")
    end
  end

  describe "#_region" do
    it "should create a region data structure" do
      expect(instance._region).to eq("Ref" => "AWS::Region")
    end
  end

  describe "#_notification_arns" do
    it "should create a notification arns data structure" do
      expect(instance._notification_arns).to eq("Ref" => "AWS::NotificationARNs")
    end
  end

  describe "#_account_id" do
    it "should create an account id data structure" do
      expect(instance._account_id).to eq("Ref" => "AWS::AccountId")
    end
  end

  describe "#_stack_id" do
    it "should create a stack id data structure" do
      expect(instance._stack_id).to eq("Ref" => "AWS::StackId")
    end
  end

  describe "#_stack_name" do
    it "should create a stack name data structure" do
      expect(instance._stack_name).to eq("Ref" => "AWS::StackName")
    end
  end

  describe "#_depends_on" do
    it "should set depends on data structure into underlying structure" do
      instance._depends_on(:item)
      expect(instance._dump).to eq("DependsOn" => ["Item"])
    end
  end

  describe "#_stack_output" do
    it "should create stack output data structure" do
      result = instance._stack_output("stack_name", "output_name")
      expect(result).to eq("Fn::GetAtt" => ["StackName", "Outputs.OutputName"])
    end
  end

  describe "#taggable?" do
    context "with resource that can be tagged" do
      before do
        instance._set_self(SparkleFormation.new("test"))
        instance.resources.item.type "AWS::EC2::Instance"
      end

      it "should return true within context that can be tagged" do
        instance.resources.item.properties do
          if taggable?
            tagged true
          end
        end
        result = instance._dump.to_smash
        expect(result.get("Resources", "Item", "Properties", "Tagged")).to be(true)
      end
    end

    context "with resource that cannot be tagged" do
      before do
        instance._set_self(SparkleFormation.new("test"))
        instance.resources.item.type "Custom::Resource"
      end

      it "should return false within context that cannot be tagged" do
        instance.resources.item.properties do
          if taggable?
            tagged true
          end
        end
        result = instance._dump.to_smash
        expect(result.get("Resources", "Item", "Properties" "Tagged")).to be_nil
      end
    end
  end

  describe "#_tags" do
    it "should create tags data structure" do
      result = instance._tags("k" => "v")
      expect(result).to eq([{"Key" => "K", "Value" => "v"}])
    end
  end
end
