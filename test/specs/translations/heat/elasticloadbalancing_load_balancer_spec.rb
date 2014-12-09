describe SparkleFormation::Translation::Heat do
  describe 'ElasticLoadbalancing::LoadBalancer' do

    it 'should translate to HOT format' do
      template = SparkleFormation.compile(
        File.join(SparkleFormation.sparkle_path, 'translations/elasticloadbalancing_load_balancer.rb')
      )
      translator = SparkleFormation::Translation::Heat.new(template, {})
      translator.translate!
      MultiJson.dump(translator.translated).must_equal File.read(
        File.join(
          SparkleFormation.sparkle_path, '..',
          'results/translations/heat/elasticloadbalancing_load_balancer.json'
        )
      )
    end

  end
end
