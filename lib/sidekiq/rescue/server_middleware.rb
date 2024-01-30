# frozen_string_literal: true

module Sidekiq
  module Rescue
    # Server middleware for sidekiq-rescue
    # It is responsible for catching the errors and rescheduling the job
    # according to the options provided
    # @api private
    class ServerMiddleware
      include Sidekiq::ServerMiddleware

      def call(job_instance, job_payload, _queue, &block)
        job_class = job_instance.class
        options = job_class.sidekiq_rescue_options if job_class.respond_to?(:sidekiq_rescue_options)
        if options
          sidekiq_rescue(job_payload, **options, &block)
        else
          yield
        end
      end

      private

      def sidekiq_rescue(job_payload, delay:, limit:, error:, **)
        yield
      rescue *error => e
        rescue_counter = increment_rescue_counter(job_payload)
        raise e if rescue_counter > limit

        reschedule_at = calculate_reschedule_time(delay, rescue_counter)
        log_reschedule_info(rescue_counter, e, reschedule_at)
        reschedule_job(job_payload, reschedule_at, rescue_counter)
      end

      def increment_rescue_counter(job_payload)
        rescue_counter = job_payload["sidekiq_rescue_counter"].to_i
        rescue_counter += 1
        rescue_counter
      end

      def calculate_reschedule_time(delay, rescue_counter)
        # NOTE: we use the retry counter to increase the jitter
        # so that the jobs don't retry at the same time
        # inspired by sidekiq https://github.com/sidekiq/sidekiq/blob/73c150d0430a8394cadb5cd49218895b113613a0/lib/sidekiq/job_retry.rb#L188
        jitter = rand(10) * rescue_counter
        delay = delay.call(rescue_counter) if delay.is_a?(Proc)
        Time.now.to_f + delay + jitter
      end

      def log_reschedule_info(rescue_counter, error, reschedule_at)
        Sidekiq::Rescue.logger.info("[sidekiq_rescue] Job failed #{rescue_counter} times with error: " \
                                    "#{error.message}; rescheduling at #{reschedule_at}")
      end

      def reschedule_job(job_payload, reschedule_at, rescue_counter)
        Sidekiq::Client.push(job_payload.merge("at" => reschedule_at, "sidekiq_rescue_counter" => rescue_counter))
      end
    end
  end
end
