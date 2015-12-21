require_relative '../spec'

describe SparkleFormation do

  describe 'Class Methods' do

    describe 'Type checks' do

      before do
        @template = SparkleFormation.new(:template)
        @struct = @template.compile
      end

      it 'should require string-ish type for registry name' do
        ->{ SparkleFormation.registry(:thing, @struct) }.must_raise KeyError
        ->{ SparkleFormation.registry('thing', @struct) }.must_raise KeyError
        ->{ SparkleFormation.registry(false, @struct) }.must_raise TypeError
      end

      it 'should require string-ish type for dynamic name' do
        ->{ SparkleFormation.insert(:thing, @struct) }.must_raise RuntimeError
        ->{ SparkleFormation.insert('thing', @struct) }.must_raise RuntimeError
        ->{ SparkleFormation.insert(false, @struct) }.must_raise TypeError
      end

      it 'should require string-ish type for template name and additional args for nest' do
        ->{ SparkleFormation.nest(:thing, @struct, 'thing1', :thing2) }.must_raise SparkleFormation::Error::NotFound::Template
        ->{ SparkleFormation.nest('thing1', @struct, 'thing1', :thing2) }.must_raise SparkleFormation::Error::NotFound::Template
        ->{ SparkleFormation.nest(false, @struct, 'thing1', :thing2) }.must_raise TypeError
        ->{ SparkleFormation.nest(false, @struct, 'thing1', :thing2, 10) }.must_raise TypeError
        ->{ SparkleFormation.nest(:thing, @struct, 'thing1', :thing2, 10) }.must_raise TypeError
      end

    end
  end

end
