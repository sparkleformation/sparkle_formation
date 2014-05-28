describe SparkleFormation::SparkleAttribute do

  before do
    @attr = Object.new
    @attr.extend(SparkleFormation::SparkleAttribute)
  end

  it 'should generate Fn::Join' do
    @attr.join!('a', 'b', 'c').must_equal 'Fn::Join' => ['', ['a', 'b', 'c']]
  end

  it 'should generate Fn::Join with custom delimiter' do
    @attr.join!('a', 'b', 'c', :options => {:delimiter => '-'}).
      must_equal 'Fn::Join' => ['-', ['a', 'b', 'c']]
  end

  it 'should generate Ref' do
    @attr.ref!('Item').must_equal 'Ref' => 'Item'
  end

  it 'should process symbol when generating Ref' do
    SparkleFormation.new(:dummy) do
      thing ref!(:item)
    end.dump.must_equal 'Thing' => {'Ref' => 'Item'}
  end

  it 'should generate Fn::FindInMap' do
    SparkleFormation.new(:dummy) do
      thing find_in_map!('MyMap', 'MyKey', 'SubKey')
    end.dump.
      must_equal 'Thing' => {'Fn::FindInMap' => ['MyMap', {'Ref' => 'MyKey'}, 'SubKey']}
  end

  it 'should generate Fn::GetAtt' do
    SparkleFormation.new(:dummy) do
      thing attr!(:resource, 'my_instance', :ip_address)
    end.dump.
      must_equal 'Thing' => {'Fn::GetAtt' => ['Resource', 'my_instance', 'IpAddress']}
  end

  it 'should generate Fn::Base64' do
    @attr.base64!('my string!').must_equal 'Fn::Base64' => 'my string!'
  end

  it 'should generate Fn::GetAZs' do
    @attr.azs!.must_equal 'Fn::GetAZs' => ''
  end

  it 'should generate Fn::GetAZs with argument' do
    @attr.azs!('fubar').must_equal 'Fn::GetAZs' => 'fubar'
  end

  it 'should generate Fn::GetAZs with Ref when provided symbol' do
    SparkleFormation.new(:dummy) do
      thing azs!(:item)
    end.dump.
      must_equal 'Thing' => {'Fn::GetAZs' => {'Ref' => 'Item'}}
  end

  it 'should generate Fn::Select' do
    @attr.select!(1, 'fubar').must_equal 'Fn::Select' => [1, 'fubar']
    @attr.select!('1', 'fubar').must_equal 'Fn::Select' => ['1', 'fubar']
  end

  it 'should generate Fn::Select with Ref when provided symbol' do
    SparkleFormation.new(:dummy) do
      thing select!(:param, :fubar)
    end.dump.
      must_equal 'Thing' => {'Fn::Select' => [{'Ref' => 'Param'}, {'Ref' => 'Fubar'}]}
  end

end
