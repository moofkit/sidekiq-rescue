# frozen_string_literal: true

module Sidekiq
  module Rescue
    # This module is included into the job class to provide the Dsl for
    # configuring rescue options.
    module Dsl
      def self.included(base)
        base.extend(ClassMethods)
        base.sidekiq_class_attribute(:sidekiq_rescue_options)
      end

      # Module containing the Dsl methods
      module ClassMethods
        # Configure rescue options for the job.
        # @param error [StandardError] The error class to rescue.
        # @param error [Array<StandardError>] The error classes to rescue.
        # @param delay [Integer, Float, Proc] The delay in seconds before retrying the job.
        # @param limit [Integer] The maximum number of retries.
        # @return [void]
        # @raise [ArgumentError] if error is not a StandardError
        # @raise [ArgumentError] if error is not an array of StandardError
        # @raise [ArgumentError] if delay is not an Integer or Float
        # @raise [ArgumentError] if limit is not an Integer
        # @example
        #  sidekiq_rescue NetworkError, delay: 60, limit: 10
        def sidekiq_rescue(*error, delay: nil, limit: nil)
          error = validate_and_unpack_error_argument(error)
          validate_delay_argument(delay)
          validate_limit_argument(limit)

          self.sidekiq_rescue_options = {
            error: error,
            delay: delay || Sidekiq::Rescue.config.delay,
            limit: limit || Sidekiq::Rescue.config.limit
          }
        end

        private

        def validate_and_unpack_error_argument(error)
          error_arg_valid = error.any? && error.flatten.all? { |e| e < StandardError } if error.is_a?(Array)
          return error.flatten if error_arg_valid

          raise ArgumentError,
                "error must be an ancestor of StandardError"
        end

        def validate_delay_argument(delay)
          return if delay.nil?
          return if delay.is_a?(Integer) || delay.is_a?(Float)

          if delay.is_a?(Proc)
            raise ArgumentError, "delay proc must accept counter as argument" if delay.arity.zero?

            return
          end

          raise ArgumentError,
                "delay must be integer, float or proc"
        end

        def validate_limit_argument(limit)
          raise ArgumentError, "limit must be integer" if limit && !limit.is_a?(Integer)
        end
      end
    end
    # Alias for Dsl; TODO: remove in 1.0.0
    # @deprecated
    # @see Dsl
    DSL = Dsl
  end
end
