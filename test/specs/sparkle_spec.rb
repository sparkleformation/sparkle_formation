require_relative "../spec"

describe SparkleFormation::Sparkle do
  describe "valid sparkle pack" do
    before do
      SparkleFormation.sparkle_path = nil
      @pack = SparkleFormation::Sparkle.new(
        :root => File.join(File.dirname(__FILE__), "packs/valid_pack"),
      )
    end

    it "should have template registered" do
      _(@pack.get(:template, :stack)).must_be_kind_of Hash
    end

    it "should have a dynamic registered" do
      _(@pack.get(:dynamic, :base)).must_be_kind_of Hash
    end

    it "should have a component registered" do
      _(@pack.get(:component, :base)).must_be_kind_of Hash
    end

    it "should have a registry item registered" do
      _(@pack.get(:registry, :base)).must_be_kind_of Hash
    end
  end

  describe "sparkle pack loads dynamics from itself and another pack" do
    before do
      ::SparkleFormation::SparklePack.register!("base_pack", File.join(File.dirname(__FILE__), "packs/base_pack"))
      @root_pack = ::SparkleFormation::SparklePack.new(:name => "base_pack")
      ::SparkleFormation.sparkle_path = File.join(File.dirname(__FILE__), "packs/base_pack")
      @template = ::SparkleFormation.compile(File.join(File.dirname(__FILE__), "packs/base_pack/stack.rb"), :sparkle => @root_pack)
    end

    it "should be able to compile a stack with the dynamics" do
      _(@template.to_json).must_be_kind_of String
    end
  end

  describe "invalid name collision pack" do
    it "should raise a KeyError on duplicate template name" do
      _{
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs/name_collision_pack"),
        ).templates
      }.must_raise KeyError
    end

    it "should raise a KeyError on duplicate dynamic name" do
      _{
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), "packs/name_collision_pack_item"),
        )
      }.must_raise KeyError
    end
  end
end
