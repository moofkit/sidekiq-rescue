# frozen_string_literal: true

require "sidekiq_rescue"
require "sidekiq/testing"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.include Sidekiq::Rescue::RSpec::Matchers

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    Sidekiq::Testing.fake!

    Sidekiq::Testing.server_middleware do |chain|
      chain.add Sidekiq::Rescue::ServerMiddleware
    end
  end

  config.before(:each, :integration) do
    Sidekiq::Queues.clear_all
  end

  if ENV["LOG"].nil?
    if defined?(Sidekiq::MAJOR) && Sidekiq::MAJOR >= 7
      Sidekiq.default_configuration.logger = nil
    else
      Sidekiq.logger = nil
    end
  end
end
