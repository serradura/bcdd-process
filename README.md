<p align="center">
  <h1 align="center" id="-bcddresult">🚄 BCDD::Process</h1>
  <p align="center"><i>Write reliable, self-documented, and self-observable business processes in Ruby.</i></p>
</p>

## Ruby Version

`>= 2.7.0`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bcdd-process'
```

And then execute:

    $ bundle install

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install bcdd-process

And require it in your code:

    require 'bcdd/process'

## Usage Example

Check out the [examples/business_processes](examples/business_processes) directory for a complete (Rails like app) example.

```ruby
class User
  class Creation < ::BCDD::Process
    include BCDD::Result::RollbackOnFailure

    input do
      attribute :uuid, contract: :is_uuid, normalize: -> { _1.strip.downcase }, default: -> { ::SecureRandom.uuid }
      attribute :name, contract: :is_str, normalize: -> { _1.strip.gsub(/\s+/, ' ') }
      attribute :email, contract: :is_email, normalize: -> { _1.strip.downcase }
      attribute :password, contract: :is_password
      attribute :password_confirmation, contract: :is_password
    end

    output do
      Failure(
        invalid_user: :errors_by_attribute,
        email_already_taken: :empty_hash
      )

      Success user_created: {
        user: contract[::User] & :is_persisted,
        token: contract[Token] & :is_persisted
      }
    end

    def call(**input)
      Given(input)
        .and_then(:validate_email_uniqueness)
        .then { |result|
          rollback_on_failure {
            result
              .and_then(:create_user)
              .and_then(:create_user_token)
          }
        }
        .and_expose(:user_created, %i[user token])
    end

    private

    def validate_email_uniqueness(email:, **)
      ::User.exists?(email:) ? Failure(:email_already_taken) : Continue()
    end

    def create_user(uuid:, name:, email:, password:, password_confirmation:)
      user = ::User.create(uuid:, name:, email:, password:, password_confirmation:)

      user.persisted? ? Continue(user:) : Failure(:invalid_user, **user.errors.messages)
    end

    def create_user_token(user:, **)
      Token::Creation.new.call(user: user).handle do |on|
        on.success { |output| Continue(token: output[:token]) }
        on.failure { raise 'Token creation failed' }
      end
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/b-cdd/process. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/b-cdd/process/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BCDD::Process project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/b-cdd/process/blob/master/CODE_OF_CONDUCT.md).
