require_relative '../spec'

describe SparkleFormation do

  before do
    SparkleFormation.sparkle_path = File.join(File.dirname(__FILE__), 'sparkleformation')
  end

  describe 'Dummy template' do

    it 'should build the dummy template' do
      result = SparkleFormation.compile('dummy.rb')
      result.must_be :is_a?, Hash
      result.to_smash.get('Outputs', 'Dummy', 'Value').must_equal 'Dummy value'
      result.to_smash.get('Parameters', 'Creator', 'Default').must_equal 'Fubar'
    end

  end

  describe 'Nested template' do

    it 'should build the nested template' do
      result = SparkleFormation.compile('nest.rb')
      simple = SparkleFormation.compile('simple.rb')
      dummy = SparkleFormation.compile('dummy.rb')
      result.must_be :is_a?, Hash
      simple.must_be :is_a?, Hash
      dummy.must_be :is_a?, Hash
      result.to_smash.get('Resources', 'Dummy', 'Properties', 'Stack').to_json.must_equal dummy.to_smash.to_json
      result.to_smash.get('Resources', 'Simple', 'Properties', 'Stack').to_json.must_equal simple.to_smash.to_json
      result.to_smash.get('Resources', 'DummySecond').wont_be_nil
      result.to_smash.get('Resources', 'DummySecond', 'Properties', 'Stack').to_json.must_equal dummy.to_smash.to_json
      result.to_smash.get('Resources', 'Third').wont_be_nil
      result.to_smash.get('Resources', 'Third', 'Properties', 'Stack').to_json.must_equal dummy.to_smash.to_json
    end

  end

  describe 'Component registry usage' do

    it 'should properly handle multiple registry requests' do
      result = SparkleFormation.compile('registry_in_component.rb')
      result['Complete'].must_equal true
    end

  end

end
