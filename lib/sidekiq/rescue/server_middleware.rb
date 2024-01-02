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
        rescue_counter = job_payload["sidekiq_rescue_counter"].to_i
        rescue_counter += 1
        raise e if rescue_counter > limit

        # NOTE: we use the retry counter to increase the jitter
        # so that the jobs don't retry at the same time
        # inspired by sidekiq https://github.com/sidekiq/sidekiq/blob/73c150d0430a8394cadb5cd49218895b113613a0/lib/sidekiq/job_retry.rb#L188
        jitter = rand(10) * rescue_counter
        reschedule_at = Time.now.to_f + delay + jitter

        Sidekiq::Rescue.logger.info("[sidekiq_rescue] Job failed #{rescue_counter} times with error:" \
                                    "#{e.message}; rescheduling at #{reschedule_at}")
        Sidekiq::Client.push(job_payload.merge("at" => reschedule_at, "sidekiq_rescue_counter" => rescue_counter))
      end
    end
  end
end
