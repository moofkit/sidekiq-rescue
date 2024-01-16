# frozen_string_literal: true

class WithTestErrorJob
  include Sidekiq::Job
  include Sidekiq::Rescue::DSL

  sidekiq_rescue TestError

  def perform(*)
    raise TestError
  end
end

class WithTestErrorWithoutResqueJob
  include Sidekiq::Job
  include Sidekiq::Rescue::DSL

  sidekiq_rescue TestError

  def perform(*)
    raise TestError
  end
end

class WithParentErrorJob
  include Sidekiq::Job
  include Sidekiq::Rescue::DSL

  sidekiq_rescue ParentError

  def perform(*)
    raise ParentError
  end
end

class WithChildErrorJob
  include Sidekiq::Job
  include Sidekiq::Rescue::DSL

  sidekiq_rescue ChildError

  def perform(*)
    raise ChildError
  end
end

class WithAllErrorJob
  include Sidekiq::Job
  include Sidekiq::Rescue::DSL

  sidekiq_rescue [TestError, ParentError, ChildError]

  def perform(*)
    raise [TestError, ParentError, ChildError].sample
  end
end

class WithUnexpectedErrorJob
  include Sidekiq::Job
  include Sidekiq::Rescue::DSL

  sidekiq_rescue TestError

  def perform(*)
    raise UnexpectedError
  end
end
