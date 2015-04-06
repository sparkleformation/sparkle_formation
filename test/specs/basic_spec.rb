describe SparkleFormation do

  before do
    SparkleFormation.sparkle_path = File.join(File.dirname(__FILE__), 'cloudformation')
  end

  describe 'Basic Usage' do

    it 'should dump hashes' do
      SparkleFormation.new(:dummy) do
        test true
      end.dump.must_equal 'Test' => true
    end

    it 'should include file named components' do
      SparkleFormation.new(:dummy).load(:ami).
        dump.keys.must_include 'Mappings'
    end

    it 'should include explicitly named components' do
      SparkleFormation.new(:dummy).load(:user_info).
        dump.keys.must_include 'Parameters'
    end

    it 'should process overrides' do
      SparkleFormation.new(:dummy).overrides do
        test true
      end.dump.must_equal 'Test' => true
    end

    it 'should apply components on top of initial block' do
      result = SparkleFormation.new(:dummy) do
        mappings true
      end.load(:ami).dump
      result['Mappings'].must_be :is_a?, Hash
    end

    it 'should apply overrides on top of initial block and components' do
      SparkleFormation.new(:dummy) do
        mappings true
      end.load(:ami).overrides do
        mappings true
      end.dump.must_equal 'Mappings' => true
    end

    it 'should should build component hash' do
      component = MultiJson.load(File.read(File.join(File.dirname(__FILE__), 'results', 'component.json')))
      SparkleFormation.new(:dummy).load(:ami).dump.must_equal component
    end

    it 'should build full stack' do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), 'results', 'base.json')))
      SparkleFormation.new(:dummy).load(:ami).overrides do
        dynamic!(:node, :my)
      end.dump.must_equal full_stack
    end

    it 'should load dynamics via deprecated inserts' do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), 'results', 'base.json')))
      SparkleFormation.new(:dummy).load(:ami).overrides do
        SparkleFormation.insert(:node, self, :my)
      end.dump.to_smash(:sorted).must_equal full_stack.to_smash(:sorted)
    end

    it 'should allow dynamic customization' do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), 'results', 'base_with_map.json')))
      SparkleFormation.new(:dummy).load(:ami).overrides do
        dynamic!(:node, :my) do
          properties do
            image_id map!(:region_map, 'AWS::Region', :ami)
          end
        end
      end.dump.must_equal full_stack
    end

    it 'should allow customization of defined items' do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), 'results', 'base_with_map.json')))
      SparkleFormation.new(:dummy).load(:ami).overrides do
        dynamic!(:node, :my)
        resources.my_ec2_instance.properties.image_id map!(:region_map, 'AWS::Region', :ami)
      end.dump.must_equal full_stack
    end

  end

end
