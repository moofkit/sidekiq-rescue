# frozen_string_literal: true

RSpec.describe Sidekiq::Rescue do
  it "has a version number" do
    expect(Sidekiq::Rescue::VERSION).not_to be_nil
  end

  it "provides a default sidekiq logger" do
    expect(described_class.logger).to be_a(Sidekiq::Logger)
  end

  it "allows to set a custom logger" do
    logger = Logger.new($stdout)
    described_class.logger = logger
    expect(described_class.logger).to eq(logger)
  end
end
