# Sidekiq::Rescue

[![Build Status](https://github.com/moofkit/sidekiq-rescue/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/moofkit/sidekiq-rescue/actions/workflows/main.yml)

[Sidekiq](https://github.com/sidekiq/sidekiq) plugin to rescue jobs from expected errors and retry them later.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "sidekiq-rescue"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install sidekiq-rescue

## Usage

1. Add the middleware to your Sidekiq configuration:

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Rescue::Middleware
  end
end
```

2. Add DSL to your job:

```ruby
class MyJob
  include Sidekiq::Job
  include Sidekiq::Rescue::Dsl

  sidekiq_rescue ExpectedError

  def perform(*)
    # ...
  end
end
```

## Configuration

You can configure the number of retries and the delay (in seconds) between retries:

```ruby
class MyJob
  include Sidekiq::Job
  include Sidekiq::Rescue::Dsl

  sidekiq_rescue ExpectedError, delay: 60, limit: 5

  def perform(*)
    # ...
  end
end
```

The `delay` is not the exact time between retries, but a minimum delay. The actual delay calculates based on retries counter and `delay` value. The formula is `delay + retries * rand(10)` seconds. Randomization is used to avoid retry storms.

The default values are:
- `delay`: 60 seconds
- `limit`: 5 retries

Delay and limit can be configured globally:

```ruby
Sidekiq::Rescue.configure do |config|
  config.delay = 65
  config.limit = 10
end
```

You can also configure a job to have the delay to be a proc:

```ruby
sidekiq_rescue ExpectedError, delay: ->(counter) { counter * 60 }
```

or globally:

```ruby
Sidekiq::Rescue.configure do |config|
  config.delay = ->(counter) { counter * 60 }
end
```


## Use cases

Sidekiq::Rescue is useful when you want to retry jobs that failed due to expected errors and not spam your exception tracker with these errors. For example, you may want to retry a job that failed due to a network error or a temporary outage of a third party service, rather than a bug in your code.

## Motivation

Sidekiq provides a retry mechanism for jobs that failed due to unexpected errors. However, it does not provide a way to retry jobs that failed due to expected errors. This gem aims to fill this gap.
In addition, it provides a way to configure the number of retries and the delay between retries independently from the Sidekiq standard retry mechanism.

## Supported Ruby versions

This gem supports Ruby 2.7+

If something doesn't work on one of these versions, it's a bug

## Supported Sidekiq versions

This gem supports Sidekiq 6.5+. It may work with older versions, but it's not tested.

If you need support for older versions, please open an issue

## Development

To install dependencies and run tests:
```bash
make init
make test
make lint
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/moofkit/sidekiq-rescue.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
