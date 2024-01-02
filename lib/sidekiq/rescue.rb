# frozen_string_literal: true

module Sidekiq
  # Sidekiq::Rescue is a Sidekiq plugin which allows you to easily handle
  # exceptions thrown by your jobs.
  #
  # To use Sidekiq::Rescue, you need to include Sidekiq::Rescue::DSL module
  # in your job class and use the sidekiq_rescue class method to define
  # exception handlers.
  #
  #     class MyJob
  #       include Sidekiq::Job
  #       include Sidekiq::Rescue::DSL
  #
  #       sidekiq_rescue NetworkError, delay: 60, limit: 10
  #
  #       def perform
  #         # ...
  #       end
  #     end
  #
  # Also it needs to be registered in Sidekiq server middleware chain:
  #    Sidekiq.configure_server do |config|
  #      config.server_middleware do |chain|
  #        chain.add Sidekiq::Rescue::ServerMiddleware
  #        ...
  module Rescue
    DEFAULT_DELAY = 60
    DEFAULT_LIMIT = 10

    class << self
      attr_writer :logger

      # Returns the logger instance. If no logger is set, it defaults to Sidekiq.logger.
      #
      # @return [Logger] The logger instance.
      def logger
        @logger ||= Sidekiq.logger
      end
    end
  end
end
