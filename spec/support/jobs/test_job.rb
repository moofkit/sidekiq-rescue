# frozen_string_literal: true

class TestJob
  include Sidekiq::Job
  include Sidekiq::Rescue::DSL

  sidekiq_rescue TestError

  def perform(*)
    raise TestError
  end
end
