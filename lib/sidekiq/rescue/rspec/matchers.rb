# frozen_string_literal: true

return unless defined?(RSpec)

require "rspec/matchers"

module Sidekiq
  module Rescue
    module RSpec
      # RSpec matchers for Sidekiq::Rescue
      module Matchers
        ::RSpec::Matchers.define :have_sidekiq_rescue do |expected| # rubocop:disable Metrics/BlockLength
          description { "be rescueable with #{expected}" }
          failure_message do |actual|
            str = "expected #{actual} to be rescueable with #{expected}"
            str += " and delay #{@delay}" if @delay
            str += " and limit #{@limit}" if @limit
            str
          end
          failure_message_when_negated { |actual| "expected #{actual} not to be rescueable with #{expected}" }

          chain :with_delay do |delay|
            @delay = delay
          end

          chain :with_limit do |limit|
            @limit = limit
          end

          match do |actual|
            actual.is_a?(Class) &&
              actual.include?(Sidekiq::Rescue::Dsl) &&
              actual.respond_to?(:sidekiq_rescue_options) &&
              Array(actual&.sidekiq_rescue_options&.[](:error)).include?(expected) &&
              (@delay.nil? || actual.sidekiq_rescue_options[:delay] == @delay) &&
              (@limit.nil? || actual.sidekiq_rescue_options[:limit] == @limit)
          end

          match_when_negated do |actual|
            raise NotImplementedError, "it's confusing to use `not_to be_rescueable` with `with_delay`" if @delay
            raise NotImplementedError, "it's confusing to use `not_to be_rescueable` with `with_limit`" if @limit

            actual.is_a?(Class) &&
              actual.include?(Sidekiq::Rescue::Dsl) &&
              actual.respond_to?(:sidekiq_rescue_options) &&
              !Array(actual&.sidekiq_rescue_options&.[](:error)).include?(expected)
          end
        end
      end
    end
  end
end
