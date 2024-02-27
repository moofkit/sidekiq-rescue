# frozen_string_literal: true

require "sidekiq"
require "forwardable"
require_relative "sidekiq/rescue/config"
require_relative "sidekiq/rescue"
require_relative "sidekiq/rescue/version"
require_relative "sidekiq/rescue/dsl"
require_relative "sidekiq/rescue/server_middleware"
require_relative "sidekiq/rescue/rspec/matchers"
