# frozen_string_literal: true

RSpec.describe Sidekiq::Rescue do
  it "has a version number" do
    expect(Sidekiq::Rescue::VERSION).not_to be_nil
  end

  it "provides a default sidekiq logger" do
    expect(described_class.logger).to be_a(Sidekiq::Logger)
  end

  describe "#configure" do
    it "allows to configurate the default delay" do
      described_class.configure do |config|
        config.delay = 10
      end

      expect(described_class.config.delay).to eq(10)
    end

    it "allows to configurate the default limit" do
      described_class.configure do |config|
        config.limit = 5
      end

      expect(described_class.config.limit).to eq(5)
    end

    it "allows to configurate the logger" do
      logger = Logger.new(nil)

      described_class.configure do |config|
        config.logger = logger
      end

      expect(described_class.config.logger).to eq(logger)
    end
  end
end
