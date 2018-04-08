require_relative "../../rspecs"

RSpec.describe SparkleFormation::Resources::Heat do
  before do
    described_class.unmemoize(:heat_resources, :global)
    if described_class.registry
      described_class.registry.clear
    end
  end

  describe "#base_key" do
    it 'should return "heat" string' do
      expect(described_class.base_key).to eq("heat")
    end
  end

  describe "#resource" do
    before { described_class.load! }

    it "should return resource information" do
      expect(described_class.resource(:os_nova_server)).to be_a(Hash)
    end

    it "should return nil if resource cannot be found" do
      expect(described_class.resource(:unknown_resource)).to be_nil
    end

    context "with data key provided" do
      it "should return specific resource data if resource exists" do
        expect(described_class.resource(:os_nova_server, :properties)).to be_a(Array)
      end

      it "should return nil if resource cannot be found" do
        expect(described_class.resource(:unknown_resource, :properties)).to be_nil
      end
    end
  end

  describe "#registry_key" do
    context "with registry loaded" do
      before { described_class.load! }

      it "should return key when exact key provided" do
        expect(described_class.registry_key("OS::Nova::Server")).to eq("OS::Nova::Server")
      end

      it "should return key when partial key provided" do
        expect(described_class.registry_key("Nova::Server")).to eq("OS::Nova::Server")
      end

      it "should return key using snake cased full name" do
        expect(described_class.registry_key("os_nova_server")).to eq("OS::Nova::Server")
      end

      it "should return key using snake cased partial name" do
        expect(described_class.registry_key("nova_server")).to eq("OS::Nova::Server")
      end
    end
  end

  describe "#lookup" do
    before { described_class.load! }

    it "should lookup resource with full name" do
      expect(described_class.lookup("OS::Nova::Server")).to be_a(Hash)
    end

    it "should lookup resource with partial name" do
      expect(described_class.lookup("Nova::Server")).to be_a(Hash)
    end

    it "should lookup resource with snake cased full name" do
      expect(described_class.lookup("os_nova_server")).to be_a(Hash)
    end

    it "should lookup resource with snake cased partial name" do
      expect(described_class.lookup("nova_server")).to be_a(Hash)
    end

    it "should return nil if no match found" do
      expect(described_class.lookup("example")).to be_nil
    end
  end

  describe "#registry" do
    context "with data loaded" do
      before { described_class.load! }

      it "should return the data Hash" do
        expect(described_class.registry).to be_a(Hash)
      end
    end
  end

  describe "#resource_lookup" do
    before { described_class.load! }

    it "should return a Resource if found" do
      expect(described_class.resource_lookup("OS::Nova::Server")).to be_a(SparkleFormation::Resources::Resource)
    end

    it "should raise error if resource is not found" do
      expect { described_class.resource_lookup(:example) }.to raise_error(KeyError)
    end
  end
end
