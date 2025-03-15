# frozen_string_literal: true

require_relative "lib/sidekiq/rescue/version"

Gem::Specification.new do |spec|
  spec.name = "sidekiq-rescue"
  spec.version = Sidekiq::Rescue::VERSION
  spec.authors = ["Dmitrii Ivliev"]
  spec.email = ["mail@ivda.dev"]
  spec.license = "MIT"

  spec.summary = "Rescue Sidekiq jobs on expected error and reschedule them"
  spec.homepage = "https://github.com/moofkit/sidekiq-rescue"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/sidekiq-rescue/#{spec.version}"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir["{lib}/**/*"] + %w[LICENSE.txt Rakefile README.md CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "sidekiq", ">= 7.0"

  spec.metadata["rubygems_mfa_required"] = "true"
end
