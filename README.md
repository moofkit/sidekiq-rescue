# Sidekiq::Rescue

[![Build Status](https://github.com/moofkit/sidekiq-rescue/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/moofkit/sidekiq-rescue/actions/workflows/main.yml)

[Sidekiq](https://github.com/sidekiq/sidekiq) plugin to rescue jobs from expected errors and retry them later.
Catch expected errors and retry the job with a delay and a limit. It's useful when you want to retry jobs that failed due to expected errors and not spam your exception tracker with these errors. If the exception will getting raised beyond the limit, it will be re-raised and will be handled by Sidekiq standard retry mechanism.

Handlers are searched from bottom to top, and up the inheritance chain. The first handler that `exception.is_a?(klass)` holds true will be used.

## Example

```ruby
class MyJob
  include Sidekiq::Job
  include Sidekiq::Rescue::Dsl

  sidekiq_rescue CustomAppException # defaults to 60 seconds delay and 10 retries
  sidekiq_rescue AnotherCustomAppException, delay: ->(counter) { counter * 2 }
  sidekiq_rescue CustomInfrastructureException, delay: 5.minutes
  sidekiq_rescue ActiveRecord::Deadlocked, delay: 5.seconds, limit: 3
  sidekiq_rescue Net::OpenTimeout, Timeout::Error, limit: 10 # retries at most 10 times for Net::OpenTimeout and Timeout::Error combined

  def perform(*args)
    # Might raise CustomAppException, AnotherCustomAppException, or YetAnotherCustomAppException for something domain specific
    # Might raise ActiveRecord::Deadlocked when a local db deadlock is detected
    # Might raise Net::OpenTimeout or Timeout::Error when the remote service is down
  end
end
```


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
    chain.add Sidekiq::Rescue::ServerMiddleware
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

  sidekiq_rescue ExpectedError, delay: 60, limit: 5, jitter: 0.15

  def perform(*)
    # ...
  end
end
```

The `delay` is not the exact time between retries, but a minimum delay. The actual delay calculates based on jitter and `delay` value. The formula is `delay + delay * jitter * rand` seconds. Randomization is used to avoid retry storms. The `jitter` represents the upper bound of possible wait time (expressed as a percentage) and defaults to 0.15 (15%).

The default values are:
- `delay`: 60 seconds
- `limit`: 5 retries
- `jitter`: 0.15

Delay, limit and jitter can be configured globally:

```ruby
Sidekiq::Rescue.configure do |config|
  config.delay = 65
  config.limit = 10
  config.jitter = 0.2
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

### Testing

1. Unit tests (recommended)

In case you want to test the rescue configuration, this gem provides RSpec matchers:

```ruby
RSpec.cofigure do |config|
  config.include Sidekiq::Rescue::RSpec::Matchers, type: :job
end

RSpec.describe MyJob do
  it "rescues from expected errors" do
    expect(MyJob).to have_sidekiq_rescue(ExpectedError)
  end
end
```

It also provides a way to test the delay and limit:

```ruby
RSpec.describe MyJob do
  it "rescues from expected errors with custom delay and limit" do
    expect(MyJob).to have_sidekiq_rescue(ExpectedError).with_delay(60).with_limit(5)
  end
end
```

2. Integration tests with `Sidekiq::Testing`
Firstly, you need to configure `Sidekiq::Testing` to use `Sidekiq::Rescue::ServerMiddleware` middleware:

```ruby
# spec/spec_helper.rb or spec/rails_helper.rb
require "sidekiq/testing"

RSpec.configure do |config|
  config.before(:all) do
    Sidekiq::Testing.fake!

    Sidekiq::Testing.server_middleware do |chain|
      chain.add Sidekiq::Rescue::ServerMiddleware
    end
  end
end
```

And test the job with the next snippet

```ruby
# spec/jobs/my_job_spec.rb
RSpec.describe MyJob do
  before do
    allow(ApiClient).to receive(:new).and_raise(ApiClient::SomethingWentWrongError)
  end

  it "retries job if it fails with ExpectedError" do
    MyJob.perform_async('test')
    expect { MyJob.perform_one }.not_to raise_error # pefrom_one is a method from Sidekiq::Testing that runs the job once
  end
end
```

## Use cases

Sidekiq::Rescue is useful when you want to retry jobs that failed due to expected errors and not spam your exception tracker with these errors. For example, you may want to retry a job that failed due to a network error or a temporary outage of a third party service, rather than a bug in your code.

## Examples

### Retry a job that may failed due to a network error

```ruby
class MyJob
  include Sidekiq::Job
  include Sidekiq::Rescue::Dsl

  sidekiq_rescue Faraday::ConnectionFailed

  def perform(*)
    # ...
  end
end
```

### Retry a job that may failed due to different errors

```ruby
class MyJob
  include Sidekiq::Job
  include Sidekiq::Rescue::Dsl

  sidekiq_rescue Faraday::ConnectionFailed, Faraday::TimeoutError

  def perform(*)
    # ...
  end
end
```

### Retry a job that may failed due to different errors with custom delay

```ruby
class MyJob
  include Sidekiq::Job
  include Sidekiq::Rescue::Dsl

  sidekiq_rescue Faraday::ConnectionFailed, Faraday::TimeoutError, delay: 60

  def perform(*)
    # ...
  end
end
```

### Retry a job that may failed due to different errors with custom delays and limits

```ruby
class MyJob
  include Sidekiq::Job
  include Sidekiq::Rescue::Dsl

  sidekiq_rescue Faraday::ConnectionFailed, Faraday::TimeoutError, delay: 60, limit: 5

  def perform(*)
    # ...
  end
end
```

## Motivation

Sidekiq provides a retry mechanism for jobs that failed due to unexpected errors. However, it does not provide a way to retry jobs that failed due to expected errors. This gem aims to fill this gap.
In addition, it provides a way to configure the number of retries and the delay between retries independently from the Sidekiq standard retry mechanism. Mostly inspired by [ActiveJob](https://edgeapi.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on)

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
