require_relative '../spec'

describe SparkleFormation::SparkleCollection do

  describe 'Basic behavior' do

    before do
      @collection = SparkleFormation::SparkleCollection.new
    end

    let(:collection){ @collection }
    let(:root_pack){
      SparkleFormation::Sparkle.new(
        :root => File.join(File.dirname(__FILE__), 'sparkleformation')
      )
    }
    let(:extra_pack){
      SparkleFormation::Sparkle.new(
        :root => File.join(File.dirname(__FILE__), 'packs', 'valid_pack')
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

  end

  describe SparkleFormation::SparkleCollection::Rainbow do



  end

end
