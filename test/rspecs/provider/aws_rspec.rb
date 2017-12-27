require_relative '../../rspecs'

RSpec.describe SparkleFormation::Provider::Aws do
  let(:instance) { SparkleFormation.new('test', :provider => :aws) }

  describe '#stack_resource_type' do
    it 'should provide the proper resource type name' do
      expect(instance.stack_resource_type).to eq('AWS::CloudFormation::Stack')
    end
  end

  describe '#generate_policy' do
    context 'with no policy units defined' do
      it 'should return Hash' do
        expect(instance.generate_policy).to be_a(Hash)
      end

      it 'should return Hash with Statement key' do
        expect(instance.generate_policy.keys).to include('Statement')
      end

      it 'should return Hash with single statement' do
        expect(instance.generate_policy.values.first.size).to eq(1)
      end
    end

    context 'with policy units defined' do
      let(:result) { @result }

      before do
        instance.compile.resources.my_instance do
          type 'AWs::EC2::Instance'
          policy do
            allow 'Modify'
            deny 'Replace'
          end
        end
        @result = instance.generate_policy
      end

      it 'should remove policy from compiled template' do
        expect(instance.compile.resources.my_instance.policy).to be_nil
      end

      it 'should extract policy from compiled template' do
        expect(result['Statement']).to include(
          'Effect' => 'Allow',
          'Action' => ['Update:Modify'],
          'Resource' => 'LogicalResourceId/MyInstance',
          'Principal' => '*',
        )
        expect(result['Statement']).to include(
          'Effect' => 'Deny',
          'Action' => ['Update:Replace'],
          'Resource' => 'LogicalResourceId/MyInstance',
          'Principal' => '*',
        )
      end
    end
  end

  describe '#list_type?' do
    it 'should return true for CommaDelimitedList' do
      expect(instance.list_type?('CommaDelimitedList')).to be(true)
    end

    it 'should return true for list of type' do
      expect(instance.list_type?('List<Number>')).to be(true)
    end

    it 'should return false for non-list type' do
      expect(instance.list_type?('Number')).to be(false)
    end
  end

  context 'stack nesting' do
    context 'single depth nesting'
    before do
      instance.compile.resources do
        my_stack do
          type 'AWS::CloudFormation::Stack'
          properties do |ctx|
            data![:Stack] = ::SparkleFormation.new(
              :my_stack, :provider => :aws, :parent => ctx._self,
            ).load do
              parameters.some_input.type 'String'
              outputs.some_data.value '1'
            end
          end
        end
        my_other_stack do
          type 'AWS::CloudFormation::Stack'
          properties do |ctx|
            data![:Stack] = ::SparkleFormation.new(
              :my_other_stack, :provider => :aws, :parent => ctx._self,
            ).load do
              parameters do
                some_data.type 'String'
                other_data.type 'String'
              end
            end
          end
        end
      end
    end

    describe '#apply_deep_nesting' do
      it 'should map stack output to stack parameter input' do
        instance.apply_deep_nesting
        result = instance.dump.to_smash
        expect(result.get(
          'Resources', 'MyOtherStack', 'Properties', 'Parameters', 'SomeData'
        )).not_to be_nil
      end

      it 'should not create any root parameters' do
        instance.apply_deep_nesting
        result = instance.dump.to_smash
        expect(result['Parameters']).to be_nil
      end

      context 'with multiple nesting depth' do
        before do
          instance.compile.resources.my_stack.properties.stack.compile.
            resources.wrap_stack do
            type 'AWS::CloudFormation::Stack'
            properties do |ctx|
              data![:Stack] = ::SparkleFormation.new(
                :wrap_stack, :provider => :aws, :parent => ctx._self,
              ).load do
                resources.inner_stack do
                  type 'AWS::CloudFormation::Stack'
                  properties do |ctx|
                    data![:Stack] = ::SparkleFormation.new(
                      :inner_stack, :provider => :aws, :parent => ctx._self,
                    ).load do
                      outputs.other_data.type 'String'
                    end
                  end
                end
              end
            end
          end
        end

        it 'should bubble output to map stack parameter input' do
          instance.apply_deep_nesting
          result = instance.dump.to_smash
          expect(result.get('Resources', 'MyOtherStack', 'Properties',
                            'Parameters', 'OtherData')).not_to be_nil
        end
      end
    end

    describe '#apply_shallow_nesting' do
      it 'should map stack output to stack parameter input' do
        instance.apply_shallow_nesting
        result = instance.dump.to_smash
        expect(result.get(
          'Resources', 'MyOtherStack', 'Properties', 'Parameters', 'SomeData'
        )).not_to be_nil
      end

      it 'should map unmatched inputs to root parameters' do
        instance.apply_shallow_nesting
        result = instance.dump.to_smash
        expect(result.get('Parameters', 'SomeInput', 'Type')).to eq('String')
      end
    end
  end
end
