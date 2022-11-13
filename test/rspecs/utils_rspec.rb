require_relative "../rspecs"

RSpec.describe SparkleFormation::Utils do
  before { SparkleFormation._cleanify! }

  let(:subject) do
    mod = Module.new
    mod.extend(described_class)
    mod
  end

  describe SparkleFormation::Utils::TypeCheckers do
    describe "stringish value check" do
      it "should not raise for string value" do
        expect(subject.__t_stringish("value")).to be_nil
      end

      it "should not raise for symbol value" do
        expect(subject.__t_stringish(:value)).to be_nil
      end

      it "should raise for Numeric value" do
        expect { subject.__t_stringish(1) }.to raise_error(TypeError)
      end
    end

    describe "hashish value check" do
      it "should not raise for Hash value" do
        expect(subject.__t_hashish(:key => "value")).to be_nil
      end

      it "should not raise for Smash value" do
        expect(subject.__t_hashish(Smash.new(:key => "value"))).to be_nil
      end

      it "should raise for String value" do
        expect { subject.__t_hashish(1) }.to raise_error(TypeError)
      end
    end
  end

  describe SparkleFormation::Utils::AnimalStrings do
    describe "#camel" do
      it "should camel case a snake cased string" do
        expect(subject.camel("snake_cased_string")).to eql("SnakeCasedString")
      end

      it "should not modify a camel cased string" do
        expect(subject.camel("CamelCasedString")).to eql("CamelCasedString")
      end
    end

    describe "#snake" do
      it "should return a symbol value" do
        expect(subject.snake("value")).to be_a(Symbol)
      end

      it "should snake case a camel cased string" do
        expect(subject.snake("CamelCasedString")).to eql(:camel_cased_string)
      end

      it "should not modify a snake cased string" do
        expect(subject.snake("snake_cased_string")).to eql(:snake_cased_string)
      end
    end
  end

  describe SparkleFormation::Registry do
    before { described_class.init! }

    describe ".register" do
      it "should register an item into the registry" do
        expect(described_class.register(:item) { true }).to be_truthy
      end
    end

    describe ".insert" do
      it "should evaluate registry item into location" do
        struct = AttributeStruct.new
        described_class.register(:item) do
          test_key "test value"
        end
        described_class.insert(:item, struct)
        result = struct.dump
        expect(result).to eql("test_key" => "test value")
      end

      it "should evaluate registry item into location with arguments" do
        struct = AttributeStruct.new
        described_class.register(:item) do |value|
          test_key value
        end
        described_class.insert(:item, struct, "test value")
        result = struct.dump
        expect(result).to eql("test_key" => "test value")
      end
    end
  end

  describe SparkleFormation::Cache do
    before { described_class.init! }

    describe "#[]=" do
      it "should set value into cache and return value" do
        expect(described_class["key"] = "value").to eql("value")
      end
    end

    describe "#[]" do
      it "should be able to access cached value" do
        described_class["key"] = "value"
        expect(described_class["key"]).to eql("value")
      end

      it "should only be able to access value from current thread" do
        described_class["key"] = "value"
        expect(described_class["key"]).to eql("value")
        Thread.new do
          expect(described_class["key"]).to be_nil
        end
      end
    end
  end
end
