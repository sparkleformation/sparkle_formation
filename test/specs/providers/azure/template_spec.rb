require_relative "../../../spec"

describe "Azure templates" do
  describe "Basic template structure" do
    it "should automatically reformat resources" do
      result = SparkleFormation.new(:dummy, :provider => :azure) do
        resources.test_resource do
          value true
        end
      end.dump
      _(result.keys).must_include "resources"
      _(result["resources"]).must_be_kind_of Array
      _(result["resources"].first).must_equal "value" => true, "name" => "testResource"
    end
  end

  describe "Helper functions behavior" do
    it "should automatically include versioning and location information on builtin dynamics" do
      result = SparkleFormation.new(:dummy, :provider => :azure) do
        dynamic!(:compute_virtual_machines, :test)
      end.dump
      _(result["resources"].first["name"]).must_equal "testComputeVirtualMachines"
      _(result["resources"].first.keys).must_include "apiVersion"
      _(result["resources"].first.keys).must_include "type"
      _(result["resources"].first.keys).must_include "location"
    end
  end
end
