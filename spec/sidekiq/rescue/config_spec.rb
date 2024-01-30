# frozen_string_literal: true

RSpec.describe Sidekiq::Rescue::Config do
  describe "#delay=" do
    it "sets the delay value" do
      config = described_class.new
      config.delay = 30
      expect(config.delay).to eq(30)
    end

    it "raises an ArgumentError if delay is not an Integer or Float" do
      config = described_class.new
      expect { config.delay = "invalid" }.to raise_error(ArgumentError)
    end

    it "sets the delay value as a Proc" do
      config = described_class.new
      config.delay = -> { 30 }
      expect(config.delay).to be_a(Proc)
    end
  end

  describe "#limit=" do
    it "sets the limit value" do
      config = described_class.new
      config.limit = 5
      expect(config.limit).to eq(5)
    end

    it "raises an ArgumentError if limit is not an Integer" do
      config = described_class.new
      expect { config.limit = "invalid" }.to raise_error(ArgumentError)
    end
  end

  describe "#logger=" do
    it "sets the logger value" do
      config = described_class.new
      logger = Logger.new(nil)
      config.logger = logger
      expect(config.logger).to eq(logger)
    end

    it "raises an ArgumentError if logger is not a Logger" do
      config = described_class.new
      expect { config.logger = "invalid" }.to raise_error(ArgumentError)
    end
  end
end
