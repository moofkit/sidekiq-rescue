# frozen_string_literal: true

RSpec.describe "Sidekiq::Rescue", :integration do
  subject(:perform_async) do
    job_class.perform_async(*args)
    job_class.perform_one
  end

  let(:args) { [1, 2, 3] }
  let(:last_job) { job_class.jobs.last }

  context "with expected error" do
    let(:job_class) { WithTestErrorJob }

    it "rescues the expected error" do
      expect { perform_async }.not_to raise_error
      expect(job_class.jobs.size).to eq(1)
    end

    it "reschedules the job with correct arguments" do
      perform_async
      scheduled_job = last_job
      expect(scheduled_job["args"]).to eq(args)
      expect(scheduled_job["sidekiq_rescue_counter"]).to eq(1)
    end

    it "reschedules the job with correct arguments and delay" do
      perform_async

      expect(last_job["at"]).to be_within(10).of(Time.now.to_f + 60)
    end

    it "increments the counter" do
      perform_async

      expect(last_job["sidekiq_rescue_counter"]).to eq(1)
    end

    it "raises an error if the counter is greater than the limit" do
      limit = 10

      job_class.perform_async(*args)
      limit.times { job_class.perform_one }

      expect { perform_async }.to raise_error(TestError, "TestError")
    end
  end

  context "with unexpected error" do
    let(:job_class) { WithUnexpectedErrorJob }

    it "does not rescue the unexpected error" do
      expect { perform_async }.to raise_error(UnexpectedError)
      expect(job_class.jobs.size).to eq(0)
    end
  end

  context "with multiple errors" do
    let(:job_class) { WithMultipleErrorsJob }

    it "rescues the expected error" do
      expect { perform_async }.not_to raise_error

      expect(job_class.jobs.size).to eq(1)
    end
  end

  context "with child job" do
    let(:job_class) { ChildJobWithExpectedError }

    it "rescues the expected error" do
      expect { perform_async }.not_to raise_error

      expect(job_class.jobs.size).to eq(1)
    end
  end

  context "without rescue" do
    let(:job_class) { WithTestErrorAndWithoutRescue }

    it "does not rescue the error" do
      expect { perform_async }.to raise_error(TestError)
      expect(job_class.jobs.size).to eq(0)
    end
  end

  context "with proc as delay" do
    let(:job_class) { WithTestErrorAndDelayProc }

    it "reschedules the job with correct delay" do
      expect { perform_async }.not_to raise_error
      expect(last_job["at"]).to be_within(10).of(Time.now.to_f + 10)
    end
  end

  context "with multiple errors and delay" do
    let(:job_class) { WithMultipleErrorsAndDelayJob }

    context "with TestError" do
      let(:args) { "TestError" }

      it "reschedules the job with correct delay" do
        expect { perform_async }.not_to raise_error
        expect(last_job["at"]).to be_within(10).of(Time.now.to_f + 10)
      end
    end

    context "with ParentError" do
      let(:args) { "ParentError" }

      it "reschedules the job with correct delay" do
        expect { perform_async }.not_to raise_error
        expect(last_job["at"]).to be_within(10).of(Time.now.to_f + 20)
      end
    end

    context "with ChildError" do
      let(:args) { "ChildError" }

      it "reschedules the job with correct delay" do
        expect { perform_async }.not_to raise_error
        expect(last_job["at"]).to be_within(10).of(Time.now.to_f + 30)
      end
    end
  end
end
