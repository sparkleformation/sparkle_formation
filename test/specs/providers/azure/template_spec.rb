require_relative '../../../spec'

describe 'Azure templates' do

  describe 'Basic template structure' do

    it 'should automatically reformat resources' do
      result = SparkleFormation.new(:dummy, :provider => :azure) do
        resources.test_resource do
          value true
        end
      end.dump
      result.keys.must_include 'resources'
      result['resources'].must_be_kind_of Array
      result['resources'].first.must_equal 'value' => true, 'name' => 'testResource'
    end

  end

  describe 'Helper functions behavior' do

    it 'should automatically include versioning and location information on builtin dynamics' do
      result = SparkleFormation.new(:dummy, :provider => :azure) do
        dynamic!(:compute_virtual_machines, :test)
      end.dump
      result['resources'].first['name'].must_equal 'testComputeVirtualMachines'
      result['resources'].first.keys.must_include 'apiVersion'
      result['resources'].first.keys.must_include 'type'
      result['resources'].first.keys.must_include 'location'
    end

  end

end
