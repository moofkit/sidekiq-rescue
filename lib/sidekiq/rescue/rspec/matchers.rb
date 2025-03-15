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
            str += " and jitter #{@jitter}" if @jitter
            str += " and queue #{@queue}" if @queue
            str
          end
          failure_message_when_negated { |actual| "expected #{actual} not to be rescueable with #{expected}" }

          chain :with_delay do |delay|
            @delay = delay
          end

          chain :with_limit do |limit|
            @limit = limit
          end

          chain :with_jitter do |jitter|
            @jitter = jitter
          end

          chain :with_queue do |queue|
            @queue = queue
          end

          match do |actual|
            matched = actual.is_a?(Class) &&
                      actual.include?(Sidekiq::Rescue::Dsl) &&
                      actual.respond_to?(:sidekiq_rescue_options) &&
                      actual.sidekiq_rescue_options.is_a?(Hash) &&
                      actual.sidekiq_rescue_options.keys.flatten.include?(expected)

            return false unless matched

            _error_group, options = actual.sidekiq_rescue_error_group_with_options_by(expected.new)

            (@delay.nil? || options.fetch(:delay) == @delay) &&
              (@limit.nil? || options.fetch(:limit) == @limit) &&
              (@jitter.nil? || options.fetch(:jitter) == @jitter) &&
              (@queue.nil? || options.fetch(:queue) == @queue)
          end

          match_when_negated do |actual|
            raise NotImplementedError, "it's confusing to use `not_to be_rescueable` with `with_delay`" if @delay
            raise NotImplementedError, "it's confusing to use `not_to be_rescueable` with `with_limit`" if @limit
            raise NotImplementedError, "it's confusing to use `not_to be_rescueable` with `with_jitter`" if @jitter
            raise NotImplementedError, "it's confusing to use `not_to be_rescueable` with `with_queue`" if @queue

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
