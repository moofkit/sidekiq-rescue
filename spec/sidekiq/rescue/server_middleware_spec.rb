# frozen_string_literal: true

RSpec.describe Sidekiq::Rescue::ServerMiddleware do
  let(:middleware) { described_class.new }
  let(:job_instance) { TestJob.new }
  let(:job_payload) do
    {
      "class" => "TestJob",
      "args" => [1],
      "retry" => true,
      "queue" => "default",
      "jid" => "123",
      "created_at" => Time.now.to_f,
      "sidekiq_rescue_counter" => 0
    }
  end

  context "with expected error" do
    subject(:call_with_expected_error) { middleware.call(job_instance, job_payload, "default") { raise TestError } }

    it "reschedules the job on expected error and increments counter" do
      allow(Sidekiq::Client).to receive(:push)

      call_with_expected_error
      expect(Sidekiq::Client).to have_received(:push).with(
        job_payload.merge("at" => anything, "sidekiq_rescue_counter" => 1)
      )
    end

    it "suppress the error" do
      expect { call_with_expected_error }.not_to raise_error
    end
  end

  context "with unexpected error" do
    subject(:call_with_unexpected_error) do
      middleware.call(job_instance, job_payload, "default") do
        raise StandardError
      end
    end

    it "does not reschedule the job" do
      allow(Sidekiq::Client).to receive(:push)

      expect { call_with_unexpected_error }.to raise_error(StandardError)
      expect(Sidekiq::Client).not_to have_received(:push)
    end
  end
end
