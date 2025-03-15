# frozen_string_literal: true

module Sidekiq
  module Rescue
    # Server middleware for sidekiq-rescue
    # It is responsible for catching the errors and rescheduling the job
    # according to the options provided
    # @api private
    class ServerMiddleware
      include Sidekiq::ServerMiddleware

      def call(job_instance, job_payload, _queue, &)
        job_class = job_instance.class
        if job_class.respond_to?(:sidekiq_rescue_options) && !job_class.sidekiq_rescue_options.nil?
          sidekiq_rescue(job_payload, job_class, &)
        else
          yield
        end
      end

      private

      def sidekiq_rescue(job_payload, job_class)
        yield
      rescue StandardError => e
        error_group, options = job_class.sidekiq_rescue_error_group_with_options_by(e)
        raise e unless error_group

        rescue_error(e, error_group, options, job_payload)
      end

      def rescue_error(error, error_group, options, job_payload)
        delay, limit, jitter = options.fetch_values(:delay, :limit, :jitter)
        queue = options.fetch(:queue, job_payload["queue"])

        rescue_counter = increment_rescue_counter_for(error_group, job_payload)
        raise error if rescue_counter > limit

        calculated_delay = calculate_delay(delay, rescue_counter, jitter)
        log_reschedule_info(rescue_counter, error, calculated_delay)
        reschedule_job(job_payload:, delay: calculated_delay, rescue_counter:,
                       error_group:, queue:)
      end

      def increment_rescue_counter_for(error_group, job_payload)
        rescue_counter = job_payload.dig("sidekiq_rescue_exceptions_counter", error_group.to_s) || 0
        rescue_counter += 1
        rescue_counter
      end

      def calculate_delay(delay, rescue_counter, jitter)
        delay = delay.call(rescue_counter) if delay.is_a?(Proc)
        jitter_delay = calculate_delay_jitter(jitter, delay)
        delay + jitter_delay
      end

      def calculate_delay_jitter(jitter, delay)
        return 0.0 if jitter.zero?

        jitter * Kernel.rand * delay
      end

      def log_reschedule_info(rescue_counter, error, delay)
        Sidekiq::Rescue.logger.info("[sidekiq_rescue] Job failed #{rescue_counter} times with error: " \
                                    "#{error.message}; rescheduling in #{delay} seconds")
      end

      def reschedule_job(job_payload:, delay:, rescue_counter:, error_group:, queue:)
        payload = job_payload.dup
        payload["at"] = Time.now.to_f + delay if delay.positive?
        payload["sidekiq_rescue_exceptions_counter"] = { error_group.to_s => rescue_counter }
        payload["queue"] = queue
        Sidekiq::Client.push(payload)
      end
    end
  end
end
