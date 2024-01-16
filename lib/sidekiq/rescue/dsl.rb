# frozen_string_literal: true

module Sidekiq
  module Rescue
    # This module is included into the job class to provide the DSL for
    # configuring rescue options.
    module DSL
      def self.included(base)
        base.extend(ClassMethods)
        base.sidekiq_class_attribute(:sidekiq_rescue_options)
      end

      # Module containing the DSL methods
      module ClassMethods
        # Configure rescue options for the job.
        # @param error [StandardError] The error class to rescue.
        # @param error [Array<StandardError>] The error classes to rescue.
        # @param delay [Integer] The delay in seconds before retrying the job.
        # @param limit [Integer] The maximum number of retries.
        # @return [void]
        # @raise [ArgumentError] if error is not a StandardError
        # @raise [ArgumentError] if error is not an array of StandardError
        # @raise [ArgumentError] if delay is not an Integer or Float
        # @raise [ArgumentError] if limit is not an Integer
        # @example
        #  sidekiq_rescue NetworkError, delay: 60, limit: 10
        def sidekiq_rescue(error, delay: nil, limit: nil)
          validate_error_argument(error)
          validate_delay_argument(delay)
          validate_limit_argument(limit)

          self.sidekiq_rescue_options = {
            error: error,
            delay: delay || Sidekiq::Rescue::DEFAULT_DELAY,
            limit: limit || Sidekiq::Rescue::DEFAULT_LIMIT
          }
        end

        private

        def validate_error_argument(error)
          error_arg_valid = if error.is_a?(Array)
                              error.all? { |e| e < StandardError }
                            else
                              error < StandardError
                            end
          return if error_arg_valid

          raise ArgumentError,
                "error must be an ancestor of StandardError or an array of ancestors of StandardError"
        end

        def validate_delay_argument(delay)
          return unless delay && !delay.is_a?(Integer) && !delay.is_a?(Float)

          raise ArgumentError,
                "delay must be integer or float"
        end

        def validate_limit_argument(limit)
          raise ArgumentError, "limit must be integer" if limit && !limit.is_a?(Integer)
        end
      end
    end
  end
end
