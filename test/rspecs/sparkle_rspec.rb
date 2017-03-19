require_relative '../rspecs'

RSpec.describe SparkleFormation::Sparkle do
  let(:root_dir){ Dir.mktmpdir('sparkleformation-sparkle-rspec') }

  context "with pack defined" do
    let(:instance){ described_class.new(:root => root_dir) }

    before do
      sprkl_dir = Pathname.new(File.join(root_dir, 'sparkleformation'))
      FileUtils.mkdir_p(sprkl_dir.to_s)
      sprkl_dir.join('t1.rb').open('w'){|f| f.write 'SparkleFormation.new(:t1){ key "value"}'}
      sprkl_dir.join('t2.rb').open('w'){|f| f.write 'SparkleFormation.new(:t2){ key "value"}'}
      sprkl_dir.join('c1.rb').open('w'){|f| f.write 'SparkleFormation.component(:c1){ key "value"}'}
      sprkl_dir.join('c2.rb').open('w'){|f| f.write 'SparkleFormation.component(:c2){ key "value"}'}
      sprkl_dir.join('d1.rb').open('w'){|f| f.write 'SparkleFormation.dynamic(:d1){ key "value"}'}
      sprkl_dir.join('r1.rb').open('w'){|f| f.write 'SfnRegistry.register(:r1){ key "value"}'}
      sprkl_dir.join('t1-google.rb').open('w'){|f| f.write 'SparkleFormation.new(:t1, :provider => :azure){ key "value"}'}
    end

    it 'should load the given directory' do
      expect(instance).to be_a(SparkleFormation::Sparkle)
    end

    it 'should automatically set provider to aws' do
      expect(instance.provider).to eq(:aws)
    end

    it 'should load templates' do
      expect(instance.templates).not_to be_empty
    end

    it 'should load components' do
      expect(instance.components).not_to be_empty
    end

    it 'should load dynamics' do
      expect(instance.dynamics).not_to be_empty
    end

    it 'should load registries' do
      expect(instance.registries).not_to be_empty
    end

    context '#get' do
      it 'should get requested template' do
        expect(instance.get(:template, :t1)).to be_a(Smash)
      end

      it 'should get requested template with matching provider' do
        expect(instance.get(:template, :t1, :aws)).to be_a(Smash)
      end

      it 'should error requesting template with non-matching provider' do
        expect{instance.get(:template, :t1, :google)}.to raise_error(SparkleFormation::Error::NotFound)
      end

      it 'should get requested component' do
        expect(instance.get(:component, :c1)).to be_a(Smash)
      end

      it 'should get requested component with matching provider' do
        expect(instance.get(:component, :c1, :aws)).to be_a(Smash)
      end

      it 'should error requesting component with non-matching provider' do
        expect{instance.get(:component, :c1, :google)}.to raise_error(SparkleFormation::Error::NotFound)
      end

      it 'should get requested dynamic' do
        expect(instance.get(:dynamic, :d1)).to be_a(Smash)
      end

      it 'should get requested dynamic with matching provider' do
        expect(instance.get(:dynamic, :d1, :aws)).to be_a(Smash)
      end

      it 'should error requesting dynamic with non-matching provider' do
        expect{instance.get(:dynamic, :d1, :google)}.to raise_error(SparkleFormation::Error::NotFound)
      end

      it 'should get requested registry' do
        expect(instance.get(:registry, :r1)).to be_a(Smash)
      end

      it 'should get requested registry with matching provider' do
        expect(instance.get(:registry, :r1, :aws)).to be_a(Smash)
      end

      it 'should error requesting registry with non-matching provider' do
        expect{instance.get(:registry, :r1, :google)}.to raise_error(SparkleFormation::Error::NotFound)
      end

      it 'should get requested template for non-default provider' do
        expect(instance.get(:template, :t1, :azure)).to be_a(Smash)
      end

      it 'should error when invalid type requested' do
        expect{instance.get(:unknown, :name)}.to raise_error(NameError)
      end
    end
  end
end
