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
        # @raise [ArgumentError] if jitter is not an Integer or Float
        # @raise [ArgumentError] if queue is not a String
        # @example
        #  sidekiq_rescue NetworkError, delay: 60, limit: 10
        def sidekiq_rescue(*errors, delay: Sidekiq::Rescue.config.delay, limit: Sidekiq::Rescue.config.limit,
                           jitter: Sidekiq::Rescue.config.jitter, queue: nil)
          unpacked_errors = validate_and_unpack_error_argument(errors)
          validate_delay_argument(delay)
          validate_limit_argument(limit)
          validate_jitter_argument(jitter)
          validate_queue_argument(queue)
          assign_sidekiq_rescue_options(
            errors: unpacked_errors, delay:, limit:, jitter:, queue:
          )
        end

        # Find the error group and options for the given exception.
        # @param exception [StandardError] The exception to find the error group for.
        # @return [Array<StandardError>, Hash] The error group and options.
        def sidekiq_rescue_error_group_with_options_by(exception)
          sidekiq_rescue_options.reverse_each.find do |error_group, _options|
            Array(error_group).any? { |error_klass| exception.is_a?(error_klass) }
          end
        end

        private

        def validate_and_unpack_error_argument(error)
          error_arg_valid = error.any? && error.flatten.all? { |e| e < StandardError } if error.is_a?(Array)
          return error.flatten if error_arg_valid

          raise ArgumentError,
                "error must be an ancestor of StandardError"
        end

        def validate_delay_argument(delay)
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

        def validate_jitter_argument(jitter)
          return if jitter.is_a?(Integer) || jitter.is_a?(Float)

          raise ArgumentError,
                "jitter must be integer or float"
        end

        def validate_queue_argument(queue)
          return if queue.nil? || queue.is_a?(String)

          raise ArgumentError,
                "queue must be a string"
        end

        def assign_sidekiq_rescue_options(errors:, delay:, limit:, jitter:, queue:)
          self.sidekiq_rescue_options ||= {}
          self.sidekiq_rescue_options = self.sidekiq_rescue_options.merge(errors => {
            delay:, limit:, jitter:, queue:
          }.compact)
        end
      end
    end
    # Alias for Dsl; TODO: remove in 1.0.0
    # @deprecated
    # @see Dsl
    DSL = Dsl
  end
end
