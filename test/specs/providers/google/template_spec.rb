require_relative "../../../spec"

describe "Google templates" do
  describe "Basic template structure" do
    it "should automatically reformat resources when sparkle dumped" do
      result = SparkleFormation.new(:dummy, :provider => :google) do
        resources.test_resource do
          value true
        end
      end.sparkle_dump
      _(result.to_smash.get("resources", "testResource", "value")).must_equal true
    end

    it "should restructure template into nested template when dumped" do
      result = SparkleFormation.new(:dummy, :provider => :google) do
        resources.test_resource do
          value true
        end
      end.dump.to_smash
      _(result.keys.sort).must_equal ["config", "imports"]
      _(result[:imports].first.get(:content, :resources).first[:name]).must_equal "testResource"
      _(result[:imports].first.get(:content, :resources).first[:value]).must_equal true
      _(result.get(:config, :content, :imports).first).must_equal result[:imports].first[:name]
      _(result.get(:config, :content, :resources).first[:name]).must_equal "dummy"
      _(result.get(:config, :content, :resources).first[:type]).must_equal result[:imports].first[:name]
    end
  end

  describe "Helper functions behavior" do
    it "should automatically generate unique resource name when requested" do
      result = SparkleFormation.new(:dummy, :provider => :google) do
        dynamic!(:v1_bucket, :test, :sparkle_unique)
      end.dump.to_smash
      _(result[:imports].first.get(:content, :resources).first[:type]).must_equal "storage.v1.bucket"
      _(result[:imports].first.get(:content, :resources).first[:name]).must_equal "test-ywyleejouz"
    end

    it "should generate properly formatted refs" do
      result = SparkleFormation.new(:dummy, :provider => :google) do
        dynamic!(:v1_bucket, :test)
        dynamic!(:v1_bucket, :other).properties.direct ref!(:test_v1_bucket)
        dynamic!(:v1_bucket, :other).properties.name ref!(:test_v1_bucket).name
        dynamic!(:v1_bucket, :other).properties.name_args ref!(:test_v1_bucket).name("string", 0)
        dynamic!(:v1_bucket, :other).properties.array_int ref!(:test_v1_bucket)[0]
        dynamic!(:v1_bucket, :other).properties.array_string ref!(:test_v1_bucket)["test"]
        dynamic!(:v1_bucket, :other).properties.array_name ref!(:test_v1_bucket)[0].name
      end.sparkle_dump.to_smash
      _(result.get(:resources, :otherV1Bucket, :properties, :direct)).must_equal "$(ref.testV1Bucket)"
      _(result.get(:resources, :otherV1Bucket, :properties, :name)).must_equal "$(ref.testV1Bucket.name)"
      _(result.get(:resources, :otherV1Bucket, :properties, :nameArgs)).must_equal '$(ref.testV1Bucket.name("string", 0))'
      _(result.get(:resources, :otherV1Bucket, :properties, :arrayInt)).must_equal "$(ref.testV1Bucket[0])"
      _(result.get(:resources, :otherV1Bucket, :properties, :arrayString)).must_equal '$(ref.testV1Bucket["test"])'
      _(result.get(:resources, :otherV1Bucket, :properties, :arrayName)).must_equal "$(ref.testV1Bucket[0].name)"
    end

    it "should generate properly formatted property values" do
      result = SparkleFormation.new(:dummy, :provider => :google) do
        test_value property!(:my_property)
      end.sparkle_dump
      _(result["testValue"]).must_equal '{{ properties["myProperty"] }}'
    end

    it "should generate properly formatted environment values" do
      result = SparkleFormation.new(:dummy, :provider => :google) do
        test_value env!(:project)
      end.sparkle_dump
      _(result["testValue"]).must_equal '{{ env["project"] }}'
    end

    it "should generate properly formatted jinja calls" do
      result = SparkleFormation.new(:dummy, :provider => :google) do
        test_value jinja!.time.clock
        test_value_params jinja!.time.sleep(2)
      end.sparkle_dump
      _(result["testValue"]).must_equal "{{ time.clock }}"
      _(result["testValueParams"]).must_equal "{{ time.sleep(2) }}"
    end
  end
end
