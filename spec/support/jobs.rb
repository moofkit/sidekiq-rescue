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

class WithTestErrorAndWithoutRescue < BaseJob
  def perform(*)
    raise TestError
  end
end

class WithMultipleErrorsJob < BaseJob
  sidekiq_rescue [TestError, ParentError, ChildError]

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

ChildJobWithExpectedError = Class.new(WithTestErrorJob)
