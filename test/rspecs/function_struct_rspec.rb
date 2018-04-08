require_relative "../rspecs"

RSpec.describe SparkleFormation do
  describe SparkleFormation::FunctionStruct do
    let(:instance) { described_class.new }

    describe "#nil?" do
      it "should always be false" do
        expect(instance.nil?).to be(false)
      end
    end

    describe "#root?" do
      context "without parent defined" do
        it "should return true" do
          expect(instance.root?).to be(true)
        end
      end
      context "with parent defined" do
        before { instance._parent(described_class.new) }

        it "should return false" do
          expect(instance.root?).to be(false)
        end
      end
    end

    describe "#[]" do
      context "with String value" do
        it "should quote key entry within internal data Hash" do
          instance["test"]
          expect(instance.data!.keys).to include("['test']")
        end
      end

      context "with non-String value" do
        it "should not quote key entry within internal data Hash" do
          instance[true]
          expect(instance.data!.keys).to include("[true]")
        end
      end
    end

    describe "#_dump" do
      context "with empty function structure" do
        it "should return an empty function wrapped string" do
          expect(instance._dump).to eq("[]")
        end
      end

      context "with named function" do
        let(:instance) { described_class.new("custom_name") }

        it "should return wrapped function string with defined name and empty parameter list" do
          expect(instance._dump).to eq("[custom_name()]")
        end

        context "with chained simple function" do
          before { instance.second_function }

          it "should return wrapped chained function" do
            expect(instance._dump).to eq("[custom_name().second_function]")
          end

          context "with collection result" do
            it "should properly access as Array" do
              instance.second_function[0]
              expect(instance._dump).to eq("[custom_name().second_function[0]]")
            end

            it "should properly access as Hash" do
              instance.second_function["string"]
              expect(instance._dump).to eq("[custom_name().second_function['string']]")
            end
          end
        end

        context "with chained function with arguments" do
          before { instance.second_function("string", 1, true) }

          it "should include arguments with proper types" do
            expect(instance._dump).to eq("[custom_name().second_function('string', 1, true)]")
          end
        end
      end

      context "with initial parameters" do
        let(:instance) { described_class.new("custom_name", "param1", 2) }

        it "should include arguments in function" do
          expect(instance._dump).to eq("[custom_name('param1', 2)]")
        end

        context "with chained function" do
          before { instance.second_function }

          it "should properly include initial arguments" do
            expect(instance._dump).to eq("[custom_name('param1', 2).second_function]")
          end
        end
      end
    end
  end

  describe SparkleFormation::JinjaExpressionStruct do
    describe "#_dump" do
      let(:instance) { described_class.new("custom_name") }

      it "should not include parenthesis when no arguments are defined" do
        expect(instance._dump).to eq("{{ custom_name }}")
      end

      it "should produce double quoted strings" do
        instance.second_function("test")
        expect(instance._dump).to eq('{{ custom_name.second_function("test") }}')
      end
    end
  end

  describe SparkleFormation::JinjaStatementStruct do
    describe "#_dump" do
      let(:instance) { described_class.new("custom_name") }

      it "should not include parenthesis when no arguments are defined" do
        expect(instance._dump).to eq("{% custom_name %}")
      end

      it "should produce double quoted strings" do
        instance.second_function("test")
        expect(instance._dump).to eq('{% custom_name.second_function("test") %}')
      end
    end
  end

  describe SparkleFormation::GoogleStruct do
    describe "#_dump" do
      let(:instance) { described_class.new("custom_name") }

      it "should not include parenthesis when no arguments are defined" do
        expect(instance._dump).to eq("$(custom_name)")
      end

      it "should produce double quoted strings" do
        instance.second_function("test")
        expect(instance._dump).to eq('$(custom_name.second_function("test"))')
      end
    end
  end

  describe SparkleFormation::TerraformStruct do
    describe "#_dump" do
      let(:instance) { described_class.new("custom_name") }

      it "should not include parenthesis when no arguments are defined" do
        expect(instance._dump).to eq("${custom_name}")
      end

      it "should produce double quoted strings" do
        instance.second_function("test")
        expect(instance._dump).to eq('${custom_name.second_function("test")}')
      end
    end
  end
end
