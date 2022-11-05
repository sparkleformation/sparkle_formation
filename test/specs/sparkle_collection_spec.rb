require_relative "../spec"

describe SparkleFormation::SparkleCollection do
  describe "Basic behavior" do
    before do
      @collection = SparkleFormation::SparkleCollection.new
    end

    let(:collection) { @collection }
    let(:root_pack) {
      SparkleFormation::Sparkle.new(
        :root => File.join(File.dirname(__FILE__), "sparkleformation"),
      )
    }
    let(:extra_pack) {
      SparkleFormation::Sparkle.new(
        :root => File.join(File.dirname(__FILE__), "packs", "valid_pack"),
      )
    }

    it "should return empty when it has no contents" do
      _(collection.empty?).must_equal true
    end

    it "should have no size when empty" do
      _(collection.size).must_equal 0
    end

    it "should register root pack at index 0" do
      _(collection.set_root(root_pack)).must_equal collection
      _(collection.sparkle_at(0)).must_equal root_pack
    end

    it "should accept additional packs" do
      _(collection.set_root(root_pack)).must_equal collection
      _(collection.add_sparkle(extra_pack)).must_equal collection
      _(collection.sparkle_at(0)).must_equal extra_pack
      _(collection.sparkle_at(1)).must_equal root_pack
    end

    it "should allow removal of packs" do
      _(collection.set_root(root_pack)).must_equal collection
      _(collection.add_sparkle(extra_pack)).must_equal collection
      _(collection.size).must_equal 2
      _(collection.remove_sparkle(extra_pack)).must_equal collection
      _(collection.size).must_equal 1
    end

    it "should provide templates when contained within pack" do
      collection.set_root(root_pack)
      _(collection.templates).wont_be :empty?
    end

    it "should apply empty settings to other collection" do
      new_collection = SparkleFormation::SparkleCollection.new
      new_collection.apply(collection)
      _(new_collection.send(:sparkles)).must_equal collection.send(:sparkles)
    end

    it "should apply settings to other collection" do
      collection.set_root(root_pack).add_sparkle(extra_pack)
      new_collection = SparkleFormation::SparkleCollection.new
      new_collection.apply(collection)
      _(new_collection.send(:sparkles)).must_equal collection.send(:sparkles)
    end
  end

  describe SparkleFormation::SparkleCollection::Rainbow do
    before do
      @rainbow = SparkleFormation::SparkleCollection::Rainbow.new(:dummy, :component)
    end

    let(:rainbow) { @rainbow }

    it "should have a name" do
      _(rainbow.name).must_equal "dummy"
    end

    it "should have a type" do
      _(rainbow.type).must_equal :component
    end

    it "should have an empty spectrum" do
      _(rainbow.spectrum).must_be :empty?
    end

    it "should act like a hash" do
      _(rainbow.empty?).must_equal true
      _(rainbow[:item]).must_be_nil
    end

    it "should error when created with invalid type" do
      _{
        SparkleFormation::SparkleCollection::Rainbow.new(:test, :invalid)
      }.must_raise ArgumentError
    end

    it "should error when invalid type added as layer" do
      _{ rainbow.add_layer(:symbol) }.must_raise TypeError
    end

    it "should allow adding layers" do
      _(rainbow.add_layer(:one => true).add_layer(:two => true)).must_equal rainbow
    end

    it "should access top layer when used as a hash" do
      rainbow.add_layer(:one => true).add_layer(:two => true)
      _(rainbow[:one]).must_be_nil
      _(rainbow[:two]).must_equal true
    end

    it "should collapse spectrum to just top layer when no merging" do
      rainbow.add_layer(:one => true).add_layer(:two => true)
      _(rainbow.monochrome).must_equal ["two" => true]
    end

    it "should collapse spectrum to just last merging layers" do
      rainbow.add_layer(:one => true).add_layer(:two => true, :args => {:layering => :merge})
      rainbow.add_layer(:three => true).add_layer(:four => true, :args => {:layering => :merge})
      _(rainbow.monochrome).must_equal [
        {"three" => true},
        {"four" => true, "args" => {"layering" => :merge}},
      ]
    end

    it "should allow layer access by index" do
      rainbow.add_layer(:one => true).add_layer(:two => true, :args => {:layering => :merge})
      rainbow.add_layer(:three => true).add_layer(:four => true, :args => {:layering => :merge})
      _(rainbow.layer_at(0)).must_equal "one" => true
      _(rainbow.layer_at(2)).must_equal "three" => true
    end
  end

  describe "Provider specific loading" do
    before do
      @collection = SparkleFormation::SparkleCollection.new
      @collection.set_root(
        SparkleFormation::Sparkle.new(
          :root => File.join(
            File.dirname(__FILE__), "packs", "valid_pack"
          ),
        )
      )
      @collection
    end

    it "should load AWS by default" do
      template = @collection.get(:template, :stack)
      template = SparkleFormation.compile(template[:path], :sparkle)
      template.sparkle.apply @collection
      result = template.dump.to_smash
      _(result["AwsTemplate"]).must_equal true
      _(result["AwsDynamic"]).must_equal true
      _(result["Registry"]).must_equal "aws"
      _(result["SharedItem"]).must_equal "shared"
    end

    it "should load HEAT when defined as provider" do
      template = @collection.get(:template, :stack, :heat)
      template = SparkleFormation.compile(template[:path], :sparkle)
      template.sparkle.apply @collection
      result = template.dump.to_smash
      _(result["heat_template"]).must_equal true
      _(result["heat_dynamic"]).must_equal true
      _(result["registry"]).must_equal "heat"
      _(result["shared_item"]).must_equal "shared"
    end
  end
end
