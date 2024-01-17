# frozen_string_literal: true

module Sidekiq
  module Rescue
    # Config class is used to store the configuration of Sidekiq::Rescue
    # and to allow to configure it.
    class Config
      DEFAULTS = {
        delay: 60,
        limit: 10
      }.freeze

      def initialize
        @delay = DEFAULTS[:delay]
        @limit = DEFAULTS[:limit]
        @logger = Sidekiq.logger
      end

      # Delay in seconds before retrying the job.
      # @return [Integer, Float]
      attr_reader :delay

      # @param delay [Integer, Float] The delay in seconds before retrying the job.
      # @return [void]
      # @raise [ArgumentError] if delay is not an Integer or Float
      def delay=(delay)
        raise ArgumentError, "delay must be an Integer or Float" unless delay.is_a?(Integer) || delay.is_a?(Float)

        @delay = delay
      end

      # The maximum number of retries.
      # @return [Integer]
      attr_reader :limit

      # @param limit [Integer] The maximum number of retries.
      # @return [void]
      # @raise [ArgumentError] if limit is not an Integer
      def limit=(limit)
        raise ArgumentError, "limit must be an Integer" unless limit.is_a?(Integer)

        @limit = limit
      end

      # The logger instance.
      # @return [Logger]
      # @note The default logger is Sidekiq's logger.
      attr_reader :logger

      # @param logger [Logger] The logger instance.
      # @return [void]
      # @raise [ArgumentError] if logger is not a Logger
      def logger=(logger)
        raise ArgumentError, "logger must be a Logger" if !logger.nil? && !logger.respond_to?(:info)

        @logger = logger
      end
    end
  end
end
