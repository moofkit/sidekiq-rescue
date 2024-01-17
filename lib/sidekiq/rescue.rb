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
    @mutex = Mutex.new
    @config = Config.new.freeze

    class << self
      extend Forwardable
      # Returns the logger instance
      #
      # @return [Logger] The logger instance.
      def_delegators :config, :logger

      # @return [Sidekiq::Rescue::Config] The configuration object.
      attr_reader :config

      # Configures Sidekiq::Rescue
      # @return [void]
      # @yieldparam config [Sidekiq::Rescue::Config] The configuration object.
      # @example
      #  Sidekiq::Rescue.configure do |config|
      #    config.delay = 10
      #    config.limit = 5
      #    config.logger = Logger.new($stdout)
      #  end
      def configure
        @mutex.synchronize do
          config = @config.dup
          yield(config)
          @config = config.freeze
        end
      end
    end
  end
end
