require_relative "../spec"

describe SparkleFormation do
  before { SparkleFormation._cleanify! }

  describe "Class Methods" do
    before do
      @template = SparkleFormation.new(:template)
      @struct = @template.compile
    end

    describe "Type checks" do
      it "should require string-ish type for registry name" do
        _{ SparkleFormation.registry(:thing, @struct) }.must_raise KeyError
        _{ SparkleFormation.registry("thing", @struct) }.must_raise KeyError
        _{ SparkleFormation.registry(false, @struct) }.must_raise TypeError
      end

      it "should require string-ish type for dynamic name" do
        _{ SparkleFormation.insert(:thing, @struct) }.must_raise TypeError
        _{ SparkleFormation.insert("thing", @struct) }.must_raise TypeError
        _{ SparkleFormation.insert(false, @struct) }.must_raise TypeError
      end

      it "should require string-ish type for template name and additional args for nest" do
        _{ SparkleFormation.nest(:thing, @struct, "thing1", :thing2) }.must_raise SparkleFormation::Error::NotFound::Template
        _{ SparkleFormation.nest("thing1", @struct, "thing1", :thing2) }.must_raise SparkleFormation::Error::NotFound::Template
        _{ SparkleFormation.nest(false, @struct, "thing1", :thing2) }.must_raise TypeError
        _{ SparkleFormation.nest(false, @struct, "thing1", :thing2, 10) }.must_raise TypeError
        _{ SparkleFormation.nest(:thing, @struct, "thing1", :thing2, 10) }.must_raise TypeError
      end
    end

    describe "Builtin resource dynamics" do
      it "should raise error on ambiguous names" do
        _{ SparkleFormation.insert(:security_group, @struct, :test) }.must_raise ArgumentError
        _(SparkleFormation.insert(:ec2_security_group, @struct, :test)).wont_be_nil
      end
    end
  end
end
