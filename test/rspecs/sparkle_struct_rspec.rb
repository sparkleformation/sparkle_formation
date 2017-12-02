require_relative '../rspecs'

RSpec.describe SparkleFormation::SparkleStruct do
  let(:instance) { described_class.new }

  describe '#_set_self' do
    context 'when set with SparkleFormation type value' do
      it 'should not raise error' do
        u_self = SparkleFormation.new(:test)
        expect(instance._set_self(u_self)).to be(u_self)
      end
    end
    context 'when set with non-SparkleFormation type value' do
      it 'should raise a TypeError exception' do
        expect { instance._set_self('string') }.to raise_error(TypeError)
      end
    end
  end

  describe '#_self' do
    context 'when underlying self has been set' do
      let(:u_self) { SparkleFormation.new(:test) }
      before { instance._set_self(u_self) }
      it 'should return underlying self' do
        expect(instance._self).to eql(u_self)
      end
    end
    context 'when underlying self has not been set' do
      it 'should raise an ArgumentError exception' do
        expect { instance._self }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#function_bubbler' do
  end

  describe '#_klass' do
    it 'should return the SparkleStruct constant' do
      expect(instance._klass).to be(SparkleFormation::SparkleStruct)
    end
  end

  describe '#_klass_new' do
    context 'when underlying self has been set' do
      before { instance._set_self(SparkleFormation.new(:test)) }
      it 'should create a new instance of SparkleStruct' do
        expect(instance._klass_new).to be_a(SparkleFormation::SparkleStruct)
      end
    end
    context 'when underlying self has not been set' do
      it 'should raise an ArgumentError exception' do
        expect { instance._klass_new }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#_state' do
    context 'without underlying self set' do
    end
    context 'with underlying self set' do
      context 'when no state has been set' do
        it 'should return nil' do
          expect(instance.state!(:test_value)).to be_nil
        end
      end
      context 'when state has been set' do
        before { instance._set_state[:test_value] = 'string' }
        it 'should return test value' do
          expect(instance.state!(:test_value)).to eql('string')
        end
      end
    end
    context 'when state has been set with underlying self' do
      before { instance._set_self(SparkleFormation.new(:test)) }
      context 'when no state has been set' do
        it 'should return nil when state is unset' do
          expect(instance.state!(:test_value)).to be_nil
        end
        context 'when parameter is defined without default value' do
          before do
            u_self = SparkleFormation.new(:test,
                                          :compile_time_parameters => {:test_value => {:type => 'string'}})
            instance._set_self(u_self)
          end

          it 'should raise ArgumentError exception' do
            expect { instance.state!(:test_value) }.to raise_error(ArgumentError)
          end
        end
      end
      context 'when state has been set' do
        before { instance._set_state[:test_value] = 'string' }
        it 'should return test value' do
          expect(instance.state!(:test_value)).to eql('string')
        end
      end
      context 'when SparkleFormation instance parameters are set' do
        before do
          u_self = SparkleFormation.new(:test,
                                        :compile_time_parameters => {:test_value => {:default => 'string'}})
          instance._set_self(u_self)
        end
        it 'should extract state from SparkleFormation instance parameters' do
          expect(instance.state!(:test_value)).to eql('string')
        end
      end
    end
  end

  describe '#_sparkle_dump_unpacker' do
  end

  describe '#_sparkle_dump' do
  end
end
