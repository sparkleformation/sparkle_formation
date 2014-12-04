describe SparkleFormation::Translation::Heat do

  def files
    %w{ cloudformation/components/network.rb }.map do |file|
      file = File.join(File.dirname(__FILE__), file)
    end
  end

  def translate(file)
    compiled = SparkleFormation.compile(file)
    candidate = SparkleFormation::Translation::Heat.new(compiled)
    candidate.translate!
    candidate.translated
  end

  it 'should compile' do
    files.each do |file|
      SparkleFormation.compile(file).wont_equal nil
    end
  end

  it 'should translate' do
    files.each do |file|
      compiled = SparkleFormation.compile(file)
      candidate = SparkleFormation::Translation::Heat.new(compiled)
      candidate.translate!.must_equal true
    end
  end

  it 'should translate ANS::EC2::Subnet' do
    file = File.join(File.dirname(__FILE__), 'cloudformation/components/network.rb')
    translation = translate(file)
    ['Network', 'Network_OSNeutronSubnet'].each do |key|
      translation['resources'].keys.must_include key
    end
    translation['resources']['Network']['type'].must_equal 'OS::Neutron::Net'
    translation['resources']['Network_OSNeutronSubnet']['type'].must_equal 'OS::Neutron::Subnet'
    translation['resources']['Network_OSNeutronSubnet']['properties']['cidr'].must_equal '10.20.30.0/24'
  end

end
