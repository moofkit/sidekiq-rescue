PHONY: test lint

init:
	bundle install
	bundle exec appraisal generate
	bundle exec appraisal install

test:
	bundle exec appraisal rake spec

lint:
	bundle exec rubocop
