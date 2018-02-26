require_relative '../spec'

describe SparkleFormation::Sparkle do
  describe 'valid sparkle pack' do
    before do
      @pack = SparkleFormation::Sparkle.new(
        :root => File.join(File.dirname(__FILE__), 'packs/valid_pack'),
      )
    end

    it 'should have template registered' do
      @pack.get(:template, :stack).must_be_kind_of Hash
    end

    it 'should have a dynamic registered' do
      @pack.get(:dynamic, :base).must_be_kind_of Hash
    end

    it 'should have a component registered' do
      @pack.get(:component, :base).must_be_kind_of Hash
    end

    it 'should have a registry item registered' do
      @pack.get(:registry, :base).must_be_kind_of Hash
    end
  end

  describe 'sparkle pack loads dynamics from itself and another pack' do
    before do
      @template = SparkleFormation.compile(File.join(File.dirname(__FILE__), 'packs/base_pack/stack.rb'), :sparkle)
    end

    it 'should be able to compile a stack with the dynamics' do
      @template.to_json.must_be_kind_of String
    end
  end

  describe 'invalid name collision pack' do
    it 'should raise a KeyError on duplicate template name' do
      -> {
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), 'packs/name_collision_pack'),
        ).templates
      }.must_raise KeyError
    end

    it 'should raise a KeyError on duplicate dynamic name' do
      -> {
        SparkleFormation::Sparkle.new(
          :root => File.join(File.dirname(__FILE__), 'packs/name_collision_pack_item'),
        )
      }.must_raise KeyError
    end
  end
end
