require_relative "../spec"

describe SparkleFormation do
  before { SparkleFormation._cleanify! }

  before do
    SparkleFormation.sparkle_path = File.join(File.dirname(__FILE__), "sparkleformation")
  end

  describe "Basic Usage" do
    it "should dump hashes" do
      _(
        SparkleFormation.new(:dummy) do
          test true
        end.dump
      ).must_equal "Test" => true
    end

    it "should include file named components" do
      _(SparkleFormation.new(:dummy).load(:ami).
        dump.keys).must_include "Mappings"
    end

    it "should include explicitly named components" do
      _(SparkleFormation.new(:dummy).load(:user_info).
        dump.keys).must_include "Parameters"
    end

    it "should process overrides" do
      _(SparkleFormation.new(:dummy).overrides do
        test true
      end.dump).must_equal "Test" => true
    end

    it "should apply components on top of initial block" do
      result = SparkleFormation.new(:dummy) do
        mappings.region_map do
          set!("us-east-1"._no_hump, :ami => "dummy")
        end
      end.load(:ami).dump
      _(result["Mappings"]["RegionMap"]["us-east-1"]["Ami"]).must_equal "ami-7f418316"
    end

    it "should apply overrides on top of initial block and components" do
      _(
        SparkleFormation.new(:dummy) do
          mappings.region_map do
            set!("us-east-1"._no_hump, :ami => "initial")
          end
        end.load(:ami).overrides do
          mappings.region_map do
            set!("us-east-1"._no_hump, :ami => "override")
          end
        end.dump["Mappings"]["RegionMap"]["us-east-1"]["Ami"]
      ).must_equal "override"
    end

    it "should should build component hash" do
      component = MultiJson.load(File.read(File.join(File.dirname(__FILE__), "results", "component.json")))
      _(SparkleFormation.new(:dummy).load(:ami).dump).must_equal component
    end

    it "should build full stack" do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), "results", "base.json")))
      _(
        SparkleFormation.new(:dummy).load(:ami).overrides do
          dynamic!(:node, :my)
        end.dump
      ).must_equal full_stack
    end

    it "should load dynamics via deprecated inserts" do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), "results", "base.json")))
      _(
        SparkleFormation.new(:dummy).load(:ami).overrides do
          SparkleFormation.insert(:node, self, :my)
        end.dump.to_smash(:sorted)
      ).must_equal full_stack.to_smash(:sorted)
    end

    it "should allow dynamic customization" do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), "results", "base_with_map.json")))
      _(
        SparkleFormation.new(:dummy).load(:ami).overrides do
          dynamic!(:node, :my) do
            properties do
              image_id map!(:region_map, ref!("AWS::Region"), :ami)
            end
          end
        end.dump
      ).must_equal full_stack
    end

    it "should allow customization of defined items" do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), "results", "base_with_map.json")))
      _(
        SparkleFormation.new(:dummy).load(:ami).overrides do
          dynamic!(:node, :my)
          resources.my_ec2_instance.properties.image_id map!(:region_map, ref!("AWS::Region"), :ami)
        end.dump
      ).must_equal full_stack
    end

    it "should properly traverse ancestors" do
      full_stack = MultiJson.load(File.read(File.join(File.dirname(__FILE__), "results", "traversal.json")))
      _(SparkleFormation.compile(:traversal)).must_equal full_stack
    end

    it "should call puts" do
      output = capture_stdout do
        _(
          SparkleFormation.new(:dummy) do
            puts! 111
            test 111
          end.dump
        ).must_equal "Test" => 111
      end
      _(output).must_equal "111\n"
    end

    it "should call raise" do
      e = assert_raises RuntimeError do
        SparkleFormation.new(:dummy) do
          raise! "111"
          test 111
        end.dump
      end
      _(e.message).must_equal "111"
    end

    it "should look up a method" do
      _(
        SparkleFormation.new(:dummy) do
          test method!(:dynamic!).source_location
        end.dump["Test"].first
      ).must_include "sparkle_attribute.rb"
    end

    it "shows builtin dynamics when a dynamic could not be found" do
      e = assert_raises RuntimeError do
        SparkleFormation.new(:dummy) do
          dynamic! :foobar
        end.dump
      end
      _(e.message).must_include "dynamics pattern"
    end

    it "shows custom dynamics when a dynamic could not be found" do
      e = assert_raises RuntimeError do
        SparkleFormation.new(:dummy) do
          dynamic! :foobar
        end.dump
      end
      _(e.message).must_include "node"
    end

    it "returns values from dynamics" do
      e = nil
      SparkleFormation.new(:dummy) do
        e = dynamic!(:node, :test).resource_name!
      end.dump
      _(e).must_equal "TestEc2Instance"
    end

    it "properly locates dynamic" do
      SparkleFormation.new(:dummy, :provider => :azure) do
        dynamic!(:network_virtual_networks, :test)
      end.dump
    end

    it "should error on unknown helper underscore prefix method" do
      _{
        SparkleFormation.new(:dummy) do
          value _dummy
        end.dump
      }.must_raise NoMethodError
    end

    it "should error on unknown helper bang suffix method" do
      _{
        SparkleFormation.new(:dummy) do
          value dummy!
        end.dump
      }.must_raise NoMethodError
    end
  end
end
