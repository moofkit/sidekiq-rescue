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
        # @example
        #  sidekiq_rescue NetworkError, delay: 60, limit: 10
        def sidekiq_rescue(error, **options)
          error_arg_valid = if error.is_a?(Array)
                              error.all? { _1 < StandardError }
                            else
                              error < StandardError
                            end
          unless error_arg_valid
            raise ArgumentError,
                  "error must be an ancestor of StandardError or an array of ancestors of StandardError"
          end
          raise ArgumentError, "delay must be integer" if options[:delay] && !options[:delay].is_a?(Integer)
          raise ArgumentError, "limit must be integer" if options[:limit] && !options[:limit].is_a?(Integer)

          self.sidekiq_rescue_options = {
            error: error,
            delay: Sidekiq::Rescue::DEFAULT_DELAY,
            limit: Sidekiq::Rescue::DEFAULT_LIMIT
          }.merge(options)
        end
      end
    end
  end
end
