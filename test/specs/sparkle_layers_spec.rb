require_relative "../spec"

describe SparkleFormation do
  before { SparkleFormation._cleanify! }

  describe "Basic template inheritance" do
    before do
      SparkleFormation.sparkle_path = nil
      @collection = SparkleFormation::SparkleCollection.new
      @collection.set_root(
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs", "rainbow-core"),
        )
      )
    end

    let(:collection) { @collection }

    it "should should inherit the core template" do
      template = SparkleFormation.compile(
        :extended,
        :sparkle,
        :sparkle_path => collection.sparkle_at(0).root,
      )
      template.sparkle.set_root collection.sparkle_at(0)
      result = template.dump.to_smash
      _(result.get("CoreCustomBlock", "BaseDynamic")).must_equal true
      _(result.get("ExtendedCustomBlock", "BaseDynamic")).must_equal true
    end

    it "should error on self inherit" do
      template = SparkleFormation.compile(
        :self_parent,
        :sparkle,
        :sparkle_path => collection.sparkle_at(0).root,
      )
      template.sparkle.set_root collection.sparkle_at(0)
      _{ template.dump }.must_raise SparkleFormation::Error::CircularInheritance
    end

    it "should error on non-direct circular inheritance" do
      template = SparkleFormation.compile(
        :circular,
        :sparkle,
        :sparkle_path => collection.sparkle_at(0).root,
      )
      template.sparkle.set_root collection.sparkle_at(0)
      _{ template.dump }.must_raise SparkleFormation::Error::CircularInheritance
    end
  end

  describe "Inheritance and merging" do
    before do
      @collection = SparkleFormation::SparkleCollection.new
      @collection.add_sparkle(
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs", "rainbow-core"),
        )
      ).set_root(
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs", "rainbow-addon"),
        )
      )
      template = SparkleFormation.compile(
        collection.get(:template, :extended)[:path],
        :sparkle
      )
      template.sparkle.add_sparkle(collection.sparkle_at(0))
      template.sparkle.add_sparkle(collection.sparkle_at(1))
      @result = template.dump.to_smash
    end

    let(:collection) { @collection }
    let(:result) { @result }

    it "should inherit and merge template" do
      _(result.get("CoreCustomBlock", "BaseDynamic")).must_equal true
      _(result.get("ExtendedCustomBlock", "BaseDynamic")).must_equal true
      _(result.get("LayeredExtra")).must_equal true
    end

    it "should have merged component layer" do
      _(result["ExtraBaseComponent"]).must_equal true
    end

    it "should have merged dynamic layer" do
      _(result["ExpandedDynamic"]).must_equal "extended"
    end

    it "should have provided original dynamic return context" do
      _(result.get("ExtendedCustomBlock", "ReturnValue")).must_equal "test"
    end
  end

  describe "Inheritance merging and knockouts" do
    before do
      @collection = SparkleFormation::SparkleCollection.new
      @collection.add_sparkle(
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs", "rainbow-core"),
        )
      ).add_sparkle(
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs", "rainbow-addon"),
        )
      ).set_root(
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs", "rainbow-top"),
        )
      )
    end

    let(:collection) { @collection }

    let(:extended) do
      unless @extended
        template = SparkleFormation.compile(
          collection.get(:template, :extended)[:path],
          :sparkle
        )
        template.sparkle.add_sparkle(collection.sparkle_at(0))
        template.sparkle.add_sparkle(collection.sparkle_at(1))
        template.sparkle.set_root(collection.sparkle_at(2))
        @extended = template.dump.to_smash
      end
      @extended
    end

    let(:final) do
      unless @final
        template = SparkleFormation.compile(
          collection.get(:template, :final)[:path],
          :sparkle
        )
        template.sparkle.add_sparkle(collection.sparkle_at(0))
        template.sparkle.add_sparkle(collection.sparkle_at(1))
        template.sparkle.set_root(collection.sparkle_at(2))
        @final = template.dump.to_smash
      end
      @final
    end

    let(:complex) do
      unless @final
        template = SparkleFormation.compile(
          collection.get(:template, :complex_inherit)[:path],
          :sparkle
        )
        template.sparkle.add_sparkle(collection.sparkle_at(0))
        template.sparkle.add_sparkle(collection.sparkle_at(1))
        template.sparkle.set_root(collection.sparkle_at(2))
        @final = template.dump.to_smash
      end
      @final
    end

    it "should replace the previous template layer" do
      _(extended).must_equal "KnockoutTemplate" => true
    end

    it "should replace previous component layer" do
      _(final["KnockoutComponent"]).must_equal true
    end

    it "should replace previous dynamic layer" do
      _(final["KnockoutDynamic"]).must_equal "core"
    end

    it "should replace previous registry item" do
      _(final["Final"]).must_equal "Customvalue"
    end

    it "should properly order inherited template components" do
      _(complex["CoreBlock"]).must_equal "core"
      _(complex["TestValue"]).must_equal "inherit"
      _(complex["OverrideValue"]).must_equal "inherit"
      _(complex["KnockoutComponent"]).must_equal true
    end
  end
end
