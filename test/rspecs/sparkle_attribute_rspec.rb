require_relative "../rspecs"

RSpec.describe SparkleFormation::SparkleAttribute do
  before { SparkleFormation._cleanify! }

  let(:instance) do
    obj = Class.new(SparkleFormation::SparkleStruct).new
    obj._set_self(SparkleFormation.new("test"))
    obj
  end

  context "#_resource_name" do
    context "with resource structure defined" do
      before do
        instance.resources.my_resource.type "Test"
      end

      it "should walk up one context to return `my_resource` name" do
        expect(instance.resources.my_resource { _resource_name }).to eql("my_resource")
      end

      it "should walk up multiple contexts to return `my_resource` name" do
        expect(instance.resources.my_resource.properties.nested { _resource_name }).to eql("my_resource")
      end
    end

    context "without resource structure defined" do
      it "should raise error" do
        expect { instance.dummy { _resource_name } }.to raise_error(NameError)
      end
    end
  end

  context "#_system" do
    it "should run a system command" do
      expect(Kernel).to receive("`").with("ls")
      instance._system("ls")
    end
  end

  context "#_puts" do
    it "should print string to STDOUT" do
      expect(STDOUT).to receive("puts").with("test")
      instance._puts("test")
    end
  end

  context "#_raise" do
    it "should raise an exception" do
      expect { instance._raise("error") }.to raise_error(StandardError)
    end
  end

  context "#_method" do
    it "should return method binding" do
      expect(instance._method(:_puts)).to be_a(Method)
    end
  end

  context "#_dynamic" do
    it "should proxy call to SparkleFormation.insert" do
      expect(SparkleFormation).to receive(:insert).
                                    with("test", instance, "val")
      instance._dynamic("test", "val")
    end
  end

  context "#_registry" do
    it "should proxy call to SparkleFormation.registry" do
      expect(SparkleFormation).to receive(:registry).
                                    with("test", instance, "val")
      instance._registry("test", "val")
    end
  end

  context "#_nest" do
    it "should proxy call to SparkleFormation.nest" do
      expect(SparkleFormation).to receive(:nest).
                                    with("template", instance, "val")
      instance._nest("template", "val")
    end
  end

  context "#_attribute_key" do
    it "should apply formatting if String given" do
      expect(instance.__attribute_key("test_string")).to eq("TestString")
    end

    it "should force formatting if Symbol given" do
      expect(instance.__attribute_key(:test_string)).to eq("TestString")
    end

    context "with key processing disabled" do
      before { instance.camel_keys_set!(:auto_disable) }

      it "should not apply formatting if String given" do
        expect(instance.__attribute_key("test_string")).to eq("test_string")
      end

      it "should force formatting if Symbol given" do
        expect(instance.__attribute_key(:test_string)).to eq("TestString")
      end
    end
  end
end
