require_relative '../spec'

describe SparkleFormation::SparkleCollection do
  describe 'Basic behavior' do
    before do
      @collection = SparkleFormation::SparkleCollection.new
    end

    let(:collection) { @collection }
    let(:root_pack) {
      SparkleFormation::Sparkle.new(
        :root => File.join(File.dirname(__FILE__), 'sparkleformation'),
      )
    }
    let(:extra_pack) {
      SparkleFormation::Sparkle.new(
        :root => File.join(File.dirname(__FILE__), 'packs', 'valid_pack'),
      )
    }

    it 'should return empty when it has no contents' do
      collection.empty?.must_equal true
    end

    it 'should have no size when empty' do
      collection.size.must_equal 0
    end

    it 'should register root pack at index 0' do
      collection.set_root(root_pack).must_equal collection
      collection.sparkle_at(0).must_equal root_pack
    end

    it 'should accept additional packs' do
      collection.set_root(root_pack).must_equal collection
      collection.add_sparkle(extra_pack).must_equal collection
      collection.sparkle_at(0).must_equal extra_pack
      collection.sparkle_at(1).must_equal root_pack
    end

    it 'should allow removal of packs' do
      collection.set_root(root_pack).must_equal collection
      collection.add_sparkle(extra_pack).must_equal collection
      collection.size.must_equal 2
      collection.remove_sparkle(extra_pack).must_equal collection
      collection.size.must_equal 1
    end

    it 'should provide templates when contained within pack' do
      collection.set_root(root_pack)
      collection.templates.wont_be :empty?
    end

    it 'should apply empty settings to other collection' do
      new_collection = SparkleFormation::SparkleCollection.new
      new_collection.apply(collection)
      new_collection.send(:sparkles).must_equal collection.send(:sparkles)
    end

    it 'should apply settings to other collection' do
      collection.set_root(root_pack).add_sparkle(extra_pack)
      new_collection = SparkleFormation::SparkleCollection.new
      new_collection.apply(collection)
      new_collection.send(:sparkles).must_equal collection.send(:sparkles)
    end
  end

  describe SparkleFormation::SparkleCollection::Rainbow do
    before do
      @rainbow = SparkleFormation::SparkleCollection::Rainbow.new(:dummy, :component)
    end

    let(:rainbow) { @rainbow }

    it 'should have a name' do
      rainbow.name.must_equal 'dummy'
    end

    it 'should have a type' do
      rainbow.type.must_equal :component
    end

    it 'should have an empty spectrum' do
      rainbow.spectrum.must_be :empty?
    end

    it 'should act like a hash' do
      rainbow.empty?.must_equal true
      rainbow[:item].must_be_nil
    end

    it 'should error when created with invalid type' do
      -> {
        SparkleFormation::SparkleCollection::Rainbow.new(:test, :invalid)
      }.must_raise ArgumentError
    end

    it 'should error when invalid type added as layer' do
      -> { rainbow.add_layer(:symbol) }.must_raise TypeError
    end

    it 'should allow adding layers' do
      rainbow.add_layer(:one => true).add_layer(:two => true).must_equal rainbow
    end

    it 'should access top layer when used as a hash' do
      rainbow.add_layer(:one => true).add_layer(:two => true)
      rainbow[:one].must_be_nil
      rainbow[:two].must_equal true
    end

    it 'should collapse spectrum to just top layer when no merging' do
      rainbow.add_layer(:one => true).add_layer(:two => true)
      rainbow.monochrome.must_equal ['two' => true]
    end

    it 'should collapse spectrum to just last merging layers' do
      rainbow.add_layer(:one => true).add_layer(:two => true, :args => {:layering => :merge})
      rainbow.add_layer(:three => true).add_layer(:four => true, :args => {:layering => :merge})
      rainbow.monochrome.must_equal [
        {'three' => true},
        {'four' => true, 'args' => {'layering' => :merge}},
      ]
    end

    it 'should allow layer access by index' do
      rainbow.add_layer(:one => true).add_layer(:two => true, :args => {:layering => :merge})
      rainbow.add_layer(:three => true).add_layer(:four => true, :args => {:layering => :merge})
      rainbow.layer_at(0).must_equal 'one' => true
      rainbow.layer_at(2).must_equal 'three' => true
    end
  end

  describe 'Provider specific loading' do
    before do
      @collection = SparkleFormation::SparkleCollection.new
      @collection.set_root(
        SparkleFormation::Sparkle.new(
          :root => File.join(
            File.dirname(__FILE__), 'packs', 'valid_pack'
          ),
        )
      )
      @collection
    end

    it 'should load AWS by default' do
      template = @collection.get(:template, :stack)
      template = SparkleFormation.compile(template[:path], :sparkle)
      template.sparkle.apply @collection
      result = template.dump.to_smash
      result['AwsTemplate'].must_equal true
      result['AwsDynamic'].must_equal true
      result['Registry'].must_equal 'aws'
      result['SharedItem'].must_equal 'shared'
    end

    it 'should load HEAT when defined as provider' do
      template = @collection.get(:template, :stack, :heat)
      template = SparkleFormation.compile(template[:path], :sparkle)
      template.sparkle.apply @collection
      result = template.dump.to_smash
      result['heat_template'].must_equal true
      result['heat_dynamic'].must_equal true
      result['registry'].must_equal 'heat'
      result['shared_item'].must_equal 'shared'
    end
  end
end
