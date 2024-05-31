# frozen_string_literal: true

class BaseJob
  include Sidekiq::Job
  include Sidekiq::Rescue::Dsl
end

class WithTestErrorJob < BaseJob
  sidekiq_rescue TestError

  def perform(*)
    raise TestError
  end
end

class WithTestErrorAndDelayProc < BaseJob
  sidekiq_rescue TestError, delay: ->(counter) { counter * 10 }

  def perform(*)
    raise TestError
  end
end

class WithTestErrorAndWithoutRescue < BaseJob
  def perform(*)
    raise TestError
  end
end

class WithGroupErrorsJob < BaseJob
  sidekiq_rescue TestError, ParentError, ChildError

  def perform(*)
    raise [TestError, ParentError, ChildError].sample
  end
end

class WithUnexpectedErrorJob < BaseJob
  sidekiq_rescue TestError

  def perform(*)
    raise UnexpectedError
  end
end

class WithMultipleErrorsAndDelayJob < BaseJob
  sidekiq_rescue TestError, delay: 10, limit: 5
  sidekiq_rescue ParentError, delay: 20, limit: 10
  sidekiq_rescue ChildError, delay: 30, limit: 15

  def perform(error_class)
    raise Object.const_get(error_class)
  end
end

ChildJobWithExpectedError = Class.new(WithTestErrorJob)

class WithCustomJitterJob < BaseJob
  sidekiq_rescue TestError, jitter: 0.1
end

class WithZeroJitterAndDelayJob < BaseJob
  sidekiq_rescue TestError, delay: 0, jitter: 0
end
