# frozen_string_literal: true

RSpec.describe Sidekiq::Rescue::Dsl do
  let(:job_class) do
    Class.new do
      include Sidekiq::Job
      include Sidekiq::Rescue::Dsl
    end
  end

  def define_dsl(...)
    job_class.instance_eval(...)
  end

  describe "#sidekiq_rescue" do
    it "sets error and default options" do
      define_dsl { sidekiq_rescue TestError }

      expect(job_class.sidekiq_rescue_options).to eq({ [TestError] => { delay: 60, limit: 10, jitter: 0.15 } })
    end

    it "sets the error classes" do
      define_dsl { sidekiq_rescue TestError, ParentError, ChildError }

      expect(job_class.sidekiq_rescue_options.keys).to eq([[TestError, ParentError, ChildError]])
      expect(job_class.sidekiq_rescue_options.values).to all(include(delay: 60, limit: 10))
    end

    it "supports multiple calls" do
      define_dsl do
        sidekiq_rescue TestError
        sidekiq_rescue ParentError
      end

      expect(job_class.sidekiq_rescue_options.keys).to eq([[TestError], [ParentError]])
    end

    it "sets the delay" do
      define_dsl { sidekiq_rescue TestError, delay: 10 }

      expect(job_class.sidekiq_rescue_options.dig([TestError], :delay)).to eq(10)
    end

    it "sets proc as the delay" do
      define_dsl { sidekiq_rescue TestError, delay: ->(counter) { counter * 10 } }

      expect(job_class.sidekiq_rescue_options.dig([TestError], :delay)).to be_a(Proc)
    end

    it "raises an ArgumentError if delay proc has no arguments" do
      expect { define_dsl { sidekiq_rescue TestError, delay: -> { 10 } } }.to raise_error(
        ArgumentError,
        "delay proc must accept counter as argument"
      )
    end

    it "sets the limit" do
      define_dsl { sidekiq_rescue TestError, limit: 5 }

      expect(job_class.sidekiq_rescue_options.dig([TestError], :limit)).to eq(5)
    end

    it "raises ArgumentError if there are no arguments" do
      expect do
        define_dsl do
          sidekiq_rescue
        end
      end.to raise_error(ArgumentError, "error must be an ancestor of StandardError")
    end

    it "raises ArgumentError if there are unknown options" do
      expect do
        define_dsl do
          sidekiq_rescue TestError, unknown: "option"
        end
      end.to raise_error(ArgumentError, "unknown keyword: :unknown")
    end

    it "raises ArgumentError if error is not a StandardError child" do
      exception_class = Class.new(Exception) # rubocop:disable Lint/InheritException

      expect { define_dsl { sidekiq_rescue exception_class } }.to raise_error(
        ArgumentError,
        "error must be an ancestor of StandardError"
      )
    end

    it "raises ArgumentError if error is not an array of StandardError children" do
      klass = Class.new

      expect { define_dsl { sidekiq_rescue [TestError, klass] } }.to raise_error(
        ArgumentError,
        "error must be an ancestor of StandardError"
      )
    end

    it "raises ArgumentError if delay is not an integer or float" do
      expect { define_dsl { sidekiq_rescue TestError, delay: "60" } }.to raise_error(
        ArgumentError,
        "delay must be integer, float or proc"
      )
    end

    it "raises ArgumentError if limit is not an integer" do
      expect { define_dsl { sidekiq_rescue TestError, limit: "10" } }.to raise_error(
        ArgumentError,
        "limit must be integer"
      )
    end

    it "sets jitter" do
      define_dsl { sidekiq_rescue TestError, jitter: 0.1 }

      expect(job_class.sidekiq_rescue_options.dig([TestError], :jitter)).to eq(0.1)
    end

    it "inherits the parent's options in right order" do
      parent = Class.new do
        include Sidekiq::Job
        include Sidekiq::Rescue::Dsl

        sidekiq_rescue ParentError, delay: 10
      end

      child = Class.new(parent) do
        sidekiq_rescue ChildError, delay: 20
      end

      expect(parent.sidekiq_rescue_options).to eq({ [ParentError] => { delay: 10, limit: 10, jitter: 0.15 } })
      expect(child.sidekiq_rescue_options.to_a).to eq([[[ParentError], { delay: 10, limit: 10, jitter: 0.15 }],
                                                       [[ChildError], { delay: 20, limit: 10, jitter: 0.15 }]])
    end
  end

  describe "#sidekiq_rescue_error_group_with_options_by" do
    it "returns the options for the error" do
      parent = Class.new do
        include Sidekiq::Job
        include Sidekiq::Rescue::Dsl

        sidekiq_rescue ParentError, delay: 10
      end

      child = Class.new(parent) do
        sidekiq_rescue ChildError, delay: 20
      end

      expect(parent.sidekiq_rescue_error_group_with_options_by(ParentError.new).last).to eq(delay: 10, limit: 10,
                                                                                            jitter: 0.15)
      expect(child.sidekiq_rescue_error_group_with_options_by(ParentError.new).last).to eq(delay: 10, limit: 10,
                                                                                           jitter: 0.15)
      expect(child.sidekiq_rescue_error_group_with_options_by(ChildError.new).last).to eq(delay: 20, limit: 10,
                                                                                          jitter: 0.15)
    end
  end
end
