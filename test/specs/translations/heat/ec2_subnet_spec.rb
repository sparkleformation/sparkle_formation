describe SparkleFormation::Translation::Heat do
  describe 'EC2::Subnet' do

    it 'should translate to HOT format' do
      template = SparkleFormation.compile(
        File.join(SparkleFormation.sparkle_path, 'translations/ec2_subnet.rb')
      )
      translator = SparkleFormation::Translation::Heat.new(template, {})
      translator.translate!
      MultiJson.dump(translator.translated).must_equal File.read(
        File.join(
          SparkleFormation.sparkle_path, '..',
          'results/translations/heat/ec2_subnet.json'
        )
      )
    end

  end
end
