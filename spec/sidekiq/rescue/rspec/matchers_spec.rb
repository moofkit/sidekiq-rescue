# frozen_string_literal: true

RSpec.describe Sidekiq::Rescue::RSpec::Matchers do
  let(:job_class) { WithTestErrorJob }

  it "matches" do
    expect(job_class).to have_sidekiq_rescue(TestError)
  end

  it "does not match" do
    expect(job_class).not_to have_sidekiq_rescue(StandardError)
  end

  context "with multiple errors" do
    let(:job_class) { WithMultipleErrorsJob }

    it "matches TestError" do
      expect(job_class).to have_sidekiq_rescue(TestError)
    end

    it "matches ParentError" do
      expect(job_class).to have_sidekiq_rescue(ParentError)
    end

    it "matches ChildError" do
      expect(job_class).to have_sidekiq_rescue(ChildError)
    end
  end

  describe "#failure_message" do
    it "returns the correct message" do
      matcher = have_sidekiq_rescue(TestError)
      matcher.matches?(job_class)
      expect(matcher.failure_message).to eq("expected WithTestErrorJob to be rescueable with TestError")
    end

    it "returns the correct message when job is not rescueable" do
      matcher = have_sidekiq_rescue(StandardError)
      matcher.matches?(BaseJob)
      expect(matcher.failure_message).to eq("expected BaseJob to be rescueable with StandardError")
    end
  end

  describe "#failure_message_when_negated" do
    it "returns the correct message" do
      matcher = have_sidekiq_rescue(TestError)
      matcher.matches?(job_class)
      expect(matcher.failure_message_when_negated)
        .to eq("expected WithTestErrorJob not to be rescueable with TestError")
    end
  end

  describe "#matches?" do
    it "returns true when the job is rescueable" do
      expect(have_sidekiq_rescue(TestError)).to be_matches(job_class)
    end

    it "returns false when the job is not rescueable" do
      expect(have_sidekiq_rescue(StandardError)).not_to be_matches(job_class)
    end
  end

  describe "#description" do
    it "returns the correct description" do
      expect(have_sidekiq_rescue(TestError).description).to eq("be rescueable with TestError")
    end
  end

  describe "#with_delay" do
    let(:job_class) { Class.new(BaseJob).tap { |klass| klass.sidekiq_rescue TestError, delay: 10 } }

    it "matches" do
      expect(job_class).to have_sidekiq_rescue(TestError).with_delay(10)
    end

    describe "#failure_message" do
      it "returns the correct message" do
        matcher = have_sidekiq_rescue(TestError).with_delay(10)
        matcher.matches?(WithTestErrorJob)
        expect(matcher.failure_message).to eq("expected WithTestErrorJob to be rescueable with TestError and delay 10")
      end
    end
  end

  describe "#with_limit" do
    let(:job_class) { Class.new(BaseJob).tap { |klass| klass.sidekiq_rescue TestError, limit: 10 } }

    it "matches" do
      expect(job_class).to have_sidekiq_rescue(TestError).with_limit(10)
    end

    describe "#failure_message" do
      it "returns the correct message" do
        matcher = have_sidekiq_rescue(TestError).with_limit(10)
        matcher.matches?(WithTestErrorJob)
        expect(matcher.failure_message).to eq("expected WithTestErrorJob to be rescueable with TestError and limit 10")
      end
    end
  end

  it "works with both delay and limit" do
    job_class = Class.new(BaseJob).tap { |klass| klass.sidekiq_rescue TestError, delay: 10, limit: 20 }
    expect(job_class).to have_sidekiq_rescue(TestError).with_delay(10).with_limit(20)
  end
end
