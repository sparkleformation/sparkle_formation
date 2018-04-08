require_relative "../spec"

describe SparkleFormation::Composition do
  it "should require `SparkleFormation` origin" do
    -> { SparkleFormation::Composition.new(:test) }.must_raise TypeError
  end

  describe "Basic usage" do
    before do
      @template = SparkleFormation.new(:testing)
      @composition = SparkleFormation::Composition.new(@template)
    end
    let(:composition) { @composition }
    let(:template) { @template }

    it "should accept new named components" do
      composition.new_component(:fubar).must_equal composition
      composition.components.first.must_be_kind_of SparkleFormation::Composition::Component
      composition.components.first.key.must_equal "fubar"
      composition.components.first.origin.must_equal template
    end

    it "should not add already defined component" do
      composition.new_component(:fubar).must_equal composition
      composition.new_component(:fubar).must_equal composition
      composition.components.first.must_be_kind_of SparkleFormation::Composition::Component
      composition.components.first.key.must_equal "fubar"
      composition.components.size.must_equal 1
    end

    it "should allow block component" do
      composition.new_component(:fubar) { true }.must_equal composition
      composition.components.first.must_be_kind_of SparkleFormation::Composition::Component
      composition.components.first.key.must_equal "fubar"
      composition.components.first.block.must_be_kind_of Proc
      composition.components.first.block.call.must_equal true
    end

    it "should accept pre-built components" do
      component = SparkleFormation::Composition::Component.new(template, :fubar)
      composition.add_component(component)
      composition.components.first.must_be_kind_of SparkleFormation::Composition::Component
      composition.components.first.key.must_equal "fubar"
      composition.components.first.origin.must_equal template
    end

    it "should accept new overrides" do
      composition.new_override { true }.must_equal composition
      composition.overrides.first.must_be_kind_of SparkleFormation::Composition::Override
      composition.overrides.first.block.call.must_equal true
    end

    it "should accept overrides with hash args" do
      composition.new_override(:fubar => :ohai) { true }.must_equal composition
      composition.overrides.first.must_be_kind_of SparkleFormation::Composition::Override
      composition.overrides.first.block.call.must_equal true
      composition.overrides.first.args.must_equal :fubar => :ohai
    end

    it "should accept pre-built overrides" do
      override = SparkleFormation::Composition::Override.new(template, {}, -> { true })
      composition.add_override(override).must_equal composition
      composition.overrides.first.must_be_kind_of SparkleFormation::Composition::Override
      composition.overrides.first.block.call.must_equal true
    end

    it "should accept overrides within components list" do
      override = SparkleFormation::Composition::Override.new(template, {}, -> { true })
      composition.add_component(override).must_equal composition
      composition.components.first.must_be_kind_of SparkleFormation::Composition::Override
      composition.components.first.block.call.must_equal true
    end
  end

  describe "Modification" do
    before do
      @template = SparkleFormation.new(:testing)
      @composition = SparkleFormation::Composition.new(@template).
        new_component(:fubar).new_component(:feebar).new_component(:item) { :component }.
        new_override { :override }.new_override { Class.new }.new_component(:last)
    end
    let(:composition) { @composition }
    let(:template) { @template }

    it "should provide list of component keys" do
      composition.send(:component_keys).must_equal %w(fubar feebar item last)
    end

    it "should contain two overrides" do
      composition.overrides.size.must_equal 2
    end

    it "should have a composite of six items" do
      composition.composite.size.must_equal 6
    end

    it "should add new component to start of list" do
      composition.new_component(:first, :prepend)
      composition.components.first.key.must_equal "first"
    end

    it "should add new override to start of list" do
      composition.new_override(:prepend) { :new_override }
      composition.overrides.first.block.call.must_equal :new_override
    end

    it "should add new override with args to start of list" do
      composition.new_override({:fubar => :ohai}, :prepend) { :new_override }
      composition.overrides.first.block.call.must_equal :new_override
      composition.overrides.first.args.must_equal :fubar => :ohai
    end
  end
end
