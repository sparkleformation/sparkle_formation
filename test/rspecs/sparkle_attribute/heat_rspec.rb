require_relative "../../rspecs"

RSpec.describe SparkleFormation::SparkleAttribute::Heat do
  let(:instance) do
    klass = Class.new(SparkleFormation::SparkleStruct)
    klass.include described_class
    obj = klass.new
    obj._set_self(SparkleFormation.new("test"))
    obj._camel_keys = klass.const_get(:CAMEL_KEYS)
    obj
  end

  context "#_get_attr" do
    it "should generate the function structure" do
      result = instance._get_attr(:my_resource, :attribute)
      expect(result).to eq("get_attr" => ["my_resource", "attribute"])
    end

    it "should raise error if first argument is not a string" do
      expect { instance._get_attr(true) }.to raise_error(TypeError)
    end
  end

  context "#_list_join" do
    it "should generate the function structure" do
      result = instance._list_join("a", "b")
      expect(result).to eq("list_join" => ["", ["a", "b"]])
    end

    it "should use custom delimiter" do
      result = instance._list_join("a", "b", :options => {:delimiter => "."})
      expect(result).to eq("list_join" => [".", ["a", "b"]])
    end
  end

  context "#_get_file" do
    it "should generate the function structure" do
      result = instance._get_file("path")
      expect(result).to eq("get_file" => "path")
    end

    it "should raise error if argument is not a string" do
      expect { instance._get_file(true) }.to raise_error(TypeError)
    end
  end

  context "#_get_param" do
    it "should generate the function structure with single argument" do
      result = instance._get_param("param", "value")
      expect(result).to eq("get_param" => ["param", "value"])
    end

    it "should generate the function structure with index argument" do
      result = instance._get_param("param", 1, "value")
      expect(result).to eq("get_param" => ["param", 1, "value"])
    end

    it "should raise error if first argument is not a string" do
      expect { instance._get_param(true) }.to raise_error(TypeError)
    end
  end

  context "#_get_resource" do
    it "should generate the function structure" do
      result = instance._get_resource(:my_resource)
      expect(result).to eq("get_resource" => "my_resource")
    end

    it "should raise error if argument is not a string" do
      expect { instance._get_resource(true) }.to raise_error(TypeError)
    end
  end

  context "#_digest" do
    it "should generate the function structure" do
      result = instance._digest("value")
      expect(result).to eq("digest" => ["sha512", "value"])
    end

    it "should allow custom algorithm" do
      result = instance._digest("value", "sha256")
      expect(result).to eq("digest" => ["sha256", "value"])
    end

    it "should raise error if algorithm is not a string" do
      expect { instance._digest("value", true) }.to raise_error(TypeError)
    end
  end

  context "#_resource_facade" do
    it "should generate the function structure" do
      result = instance._resource_facade("value")
      expect(result).to eq("resource_facade" => "value")
    end

    it "should raise error if argument is not a string" do
      expect { instance._resource_facade(true) }.to raise_error(TypeError)
    end
  end

  context "#_str_replace" do
    it "should generate the function structure" do
      result = instance._str_replace("v$replace", {"$replace" => "value"})
      expect(result).to eq("str_replace" => {"template" => "v$replace", "params" => {"$replace" => "value"}})
    end

    it "should raise error if first argument is not a string" do
      expect { instance._str_replace(true, {}) }.to raise_error(TypeError)
    end

    it "should raise error if second argument is not a hash" do
      expect { instance._str_replace("string", "value") }.to raise_error(TypeError)
    end
  end

  context "#_str_split" do
    it "should generate the function structure" do
      result = instance._str_split(",", "1,2,3")
      expect(result).to eq("str_split" => [",", "1,2,3"])
    end

    it "should generate the function structure with index" do
      result = instance._str_split(",", "1,2,3", 1)
      expect(result).to eq("str_split" => [",", "1,2,3", 1])
    end

    it "should raise error if first argument is not a string" do
      expect { instance._str_split(true, "value") }.to raise_error(TypeError)
    end
  end

  context "#_map_merge" do
    it "should generate the function structure" do
      result = instance._map_merge("item1", "item2")
      expect(result).to eq("map_merge" => ["item1", "item2"])
    end
  end

  context "#_stack_id" do
    it "should generate the function structure" do
      expect(instance._stack_id).to eq("get_param" => "OS::stack_id")
    end
  end

  context "#_stack_name" do
    it "should generate the function structure" do
      expect(instance._stack_name).to eq("get_param" => "OS::stack_name")
    end
  end

  context "#_project_id" do
    it "should generate the function structure" do
      expect(instance._project_id).to eq("get_param" => "OS::project_id")
    end
  end

  context "#_depends_on" do
    it "should generate the function structure" do
      instance._depends_on(:resource)
      expect(instance._dump).to eq("depends_on" => ["resource"])
    end

    it "should allow multiple resources in argument list" do
      instance._depends_on(:resource1, :resource2)
      expect(instance._dump).to eq("depends_on" => ["resource1", "resource2"])
    end

    it "should allow multiple resources provided as array" do
      instance._depends_on([:resource1, :resource2])
      expect(instance._dump).to eq("depends_on" => ["resource1", "resource2"])
    end
  end

  context "#_stack_output" do
    it "should generate the function structure" do
      result = instance._stack_output(:my_stack, :my_resource)
      expect(result).to eq("get_attr" => ["my_stack", "my_resource"])
    end
  end
end
