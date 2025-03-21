# frozen_string_literal: true

RSpec.describe Sidekiq::Rescue::ServerMiddleware do
  let(:middleware) { described_class.new }
  let(:job_instance) { WithTestErrorJob.new }
  let(:job_payload) do
    {
      "class" => "TestJob",
      "args" => [1],
      "retry" => true,
      "queue" => "default",
      "jid" => "123",
      "created_at" => Time.now.to_f
    }
  end

  context "with expected error" do
    subject(:call_with_expected_error) { middleware.call(job_instance, job_payload, "default") { raise TestError } }

    it "reschedules the job on expected error and increments counter" do
      allow(Sidekiq::Client).to receive(:push)

      call_with_expected_error
      expect(Sidekiq::Client).to have_received(:push).with(
        job_payload.merge("at" => be_within(0.15 * 60).of(Time.now.to_f + 60),
                          "sidekiq_rescue_exceptions_counter" => { "[TestError]" => 1 })
      )
    end

    it "suppress the error" do
      expect { call_with_expected_error }.not_to raise_error
    end
  end

  context "with expected error and delay proc" do
    subject(:call_with_expected_error_and_delay_proc) do
      middleware.call(job_instance, job_payload, "default") { raise TestError }
    end

    let(:job_instance) { WithTestErrorAndDelayProc.new }
    let(:job_payload) do
      {
        "class" => "TestJob",
        "args" => [1],
        "retry" => true,
        "queue" => "default",
        "jid" => "123",
        "created_at" => Time.now.to_f,
        "sidekiq_rescue_exceptions_counter" => { "[TestError]" => 1 }
      }
    end

    it "reschedules the job on expected error and increments counter" do
      allow(Sidekiq::Client).to receive(:push)

      call_with_expected_error_and_delay_proc
      expect(Sidekiq::Client).to have_received(:push).with(
        job_payload.merge("at" => be_within(0.15 * 20).of(Time.now.to_f + 20),
                          "sidekiq_rescue_exceptions_counter" => { "[TestError]" => 2 })
      )
    end
  end

  context "with unexpected error" do
    subject(:call_with_unexpected_error) do
      middleware.call(job_instance, job_payload, "default") { raise UnexpectedError }
    end

    let(:job_instance) { WithUnexpectedErrorJob.new }

    it "does not reschedule the job" do
      allow(Sidekiq::Client).to receive(:push)

      expect { call_with_unexpected_error }.to raise_error(UnexpectedError)
      expect(Sidekiq::Client).not_to have_received(:push)
    end

    it "does not suppress the error" do
      expect { call_with_unexpected_error }.to raise_error(UnexpectedError)
    end
  end

  context "with grouped errors" do
    subject(:call_with_multiple_errors) do
      middleware.call(job_instance, job_payload, "default") { raise TestError }
    end

    let(:job_instance) { WithGroupErrorsJob.new }

    it "reschedules the job on expected error and increments counter" do
      allow(Sidekiq::Client).to receive(:push)

      call_with_multiple_errors
      expect(Sidekiq::Client).to have_received(:push).with(
        job_payload.merge("at" => be_within(0.15 * 60).of(Time.now.to_f + 60),
                          "sidekiq_rescue_exceptions_counter" => { "[TestError, ParentError, ChildError]" => 1 })
      )
    end
  end

  context "with alterated jitter" do
    subject(:call_with_jitter) do
      middleware.call(job_instance, job_payload, "default") { raise TestError }
    end

    let(:job_instance) { WithCustomJitterJob.new }

    it "reschedules the job on expected error and increments counter" do
      allow(Sidekiq::Client).to receive(:push)

      call_with_jitter
      expect(Sidekiq::Client).to have_received(:push).with(
        job_payload.merge("at" => be_within(0.15 * 60).of(Time.now.to_f + 60),
                          "sidekiq_rescue_exceptions_counter" => { "[TestError]" => 1 })
      )
    end
  end

  context "with zero jitter and delay" do
    subject(:call_with_zero_jitter) do
      middleware.call(job_instance, job_payload, "default") { raise TestError }
    end

    let(:job_instance) { WithZeroJitterAndDelayJob.new }

    it "reschedules the job without delay" do
      allow(Sidekiq::Client).to receive(:push)

      call_with_zero_jitter
      expect(Sidekiq::Client).to have_received(:push).with(
        job_payload.merge("sidekiq_rescue_exceptions_counter" => { "[TestError]" => 1 })
      )
    end
  end

  context "with custom queue" do
    subject(:call_with_custom_queue) do
      middleware.call(job_instance, job_payload, "default") { raise TestError }
    end

    let(:job_instance) { WithCustomQueueJob.new }

    it "reschedules the job on expected error and increments counter" do
      allow(Sidekiq::Client).to receive(:push)

      call_with_custom_queue
      expect(Sidekiq::Client).to have_received(:push).with(
        job_payload.merge("at" => anything,
                          "sidekiq_rescue_exceptions_counter" => { "[TestError]" => 1 },
                          "queue" => "custom_queue")
      )
    end
  end
end
