describe SparkleFormation do

  before do
    SparkleFormation.sparkle_path = File.join(File.dirname(__FILE__), 'cloudformation')
  end

  describe 'Simple template' do

    it 'should build the template' do
      SparkleFormation.compile('dummy.rb')
    end

  end
end
