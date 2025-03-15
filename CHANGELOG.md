## [Unreleased]

## [0.6.0] - 2025-03-15
- Add support for Sidekiq 8.0, Ruby 3.4 [#6](https://github.com/moofkit/sidekiq-rescue/pull/6)

## [0.5.0] - 2024-10-17
- Add support for queue configuration [#5](https://github.com/moofkit/sidekiq-rescue/pull/5)

## [0.4.0] - 2024-06-03
- Add support for jitter configuration [#4](https://github.com/moofkit/sidekiq-rescue/pull/4)
- Changes the strategy for retry delay. Now it's calculated using the formula `delay + delay * jitter * rand`

## [0.3.1] - 2024-05-30

- Fix bug with inheritance of DSL options

## [0.3.0] - 2024-05-30

- Fix issue with RSpec matcher when job is not rescueable
- Add support for multiple invocations of the DSL
- Update documentation with new features

## [0.2.1] - 2024-02-27

- Fix readme with correct middleware name
- Add RSpec matchers

## [0.2.0] - 2024-02-03

- Rename `Sidekiq::Rescue::DSL` to `Sidekiq::Rescue::Dsl`
- Update the `delay` option to now accept a proc as an argument
- Update dsl to accept a list of errors

## [0.1.0] - 2024-01-20

- Initial release
- Add DSL to configure retries and delay
- Add middleware to rescue jobs
- Add specs
- Add documentation
- Add CI

[Unreleased]: https://github.com/moofkit/sidekiq-rescue/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/moofkit/sidekiq-rescue/releases/tag/v0.6.0
[0.5.0]: https://github.com/moofkit/sidekiq-rescue/releases/tag/v0.5.0
[0.4.0]: https://github.com/moofkit/sidekiq-rescue/releases/tag/v0.4.0
[0.3.1]: https://github.com/moofkit/sidekiq-rescue/releases/tag/v0.3.1
[0.3.0]: https://github.com/moofkit/sidekiq-rescue/releases/tag/v0.3.0
[0.2.1]: https://github.com/moofkit/sidekiq-rescue/releases/tag/v0.2.1
[0.2.0]: https://github.com/moofkit/sidekiq-rescue/releases/tag/v0.2.0
[0.1.0]: https://github.com/moofkit/sidekiq-rescue/releases/tag/v0.1.0
