require_relative "../rspecs"

RSpec.describe SparkleFormation::AuditLog do
  describe SparkleFormation::AuditLog::SourcePoint do
    let(:path) { "PATH" }
    let(:line) { 3 }

    it "should allow explicit arguments" do
      i = described_class.new(path, line)
      expect(i.path).to eq(path)
      expect(i.line).to eq(line)
    end

    it "should allow named arguments" do
      i = described_class.new(path: path, line: line)
      expect(i.path).to eq(path)
      expect(i.line).to eq(line)
    end

    it "should typecast string line to integer" do
      i = described_class.new(path, line.to_s)
      expect(i.line).to eq(line)
    end

    it "should raise error when path is not a string" do
      expect { described_class.new(line, path) }.
        to raise_error(TypeError)
    end

    it "should raise error when path is not provided" do
      expect { described_class.new(line: line) }.
        to raise_error(ArgumentError)
    end
  end

  describe SparkleFormation::AuditLog::Record do
    let(:name) { "NAME" }
    let(:type) { :dynamic }
    let(:location_args) { ["LOCATION_PATH", 5] }
    let(:caller_args) { ["CALLERS_ARGS", 6] }

    let(:instance) {
      described_class.new(name, type, location_args, caller_args)
    }

    it "should convert location arguments to SourcePoint" do
      expect(instance.location).to be_a(SparkleFormation::AuditLog::SourcePoint)
    end

    it "should convert caller arguments to SourcePoint" do
      expect(instance.caller).to be_a(SparkleFormation::AuditLog::SourcePoint)
    end

    it "should have correct location information" do
      expect(instance.location.path).to eq(location_args.first)
      expect(instance.location.line).to eq(location_args.last)
    end

    it "should have correct caller information" do
      expect(instance.caller.path).to eq(caller_args.first)
      expect(instance.caller.line).to eq(caller_args.last)
    end

    it "should create its own audit log" do
      expect(instance.audit_log).to be_a(SparkleFormation::AuditLog)
    end
  end

  let(:record_hash) {
    {name: "NAME", type: :dynamic, location: ["LOCATION_PATH", 5],
     caller: ["CALLER_PATH", 6]}
  }
  let(:record_args) { record_hash.values }
  let(:record) { SparkleFormation::AuditLog::Record.new(*record_args) }
  let(:instance) { described_class.new }

  it "should accept Record pushes" do
    expect(instance.push(record)).to eq(record)
  end

  it "should accept hash pushes" do
    expect(instance.push(record_hash)).to be_a(record.class)
  end

  it "should accept array pushes" do
    expect(instance.push(record_args)).to be_a(record.class)
  end

  it "should add pushes to list" do
    expect(instance.list).to be_empty
    instance.push(record)
    expect(instance.list).to eq([record])
  end

  it "should add new items to end of list" do
    instance.push(record_args)
    instance.push(record)
    expect(instance.list.first).not_to eq(record)
    expect(instance.list.last).to eq(record)
  end
end
