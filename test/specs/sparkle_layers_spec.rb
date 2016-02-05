require_relative '../spec'

describe SparkleFormation do

  describe 'Basic template inheritance' do

    before do
      @collection = SparkleFormation::SparkleCollection.new
      @collection.add_sparkle(
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), 'packs', 'rainbow-core')
        )
      )
    end

    let(:collection){ @collection }

    it 'should should inherit the core template' do
      template = SparkleFormation.compile(
        :extended,
        :sparkle,
        :sparkle_path => collection.sparkle_at(0).root,
      )
      template.sparkle.add_sparkle collection.sparkle_at(0)
      result = template.dump.to_smash
      result.get('CoreCustomBlock', 'BaseDynamic').must_equal true
      result.get('ExtendedCustomBlock', 'BaseDynamic').must_equal true
    end

    it 'should error on self inherit' do
      template = SparkleFormation.compile(
        :self_parent,
        :sparkle,
        :sparkle_path => collection.sparkle_at(0).root,
      )
      template.sparkle.add_sparkle collection.sparkle_at(0)
      ->{ template.dump }.must_raise SparkleFormation::Error::CircularInheritance
    end

    it 'should error on non-direct circular inheritance' do
      template = SparkleFormation.compile(
        :circular,
        :sparkle,
        :sparkle_path => collection.sparkle_at(0).root,
      )
      template.sparkle.add_sparkle collection.sparkle_at(0)
      ->{ template.dump }.must_raise SparkleFormation::Error::CircularInheritance
    end

  end

end
