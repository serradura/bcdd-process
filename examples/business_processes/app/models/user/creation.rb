# frozen_string_literal: true

class User
  class Creation < ::BCDD::Process
    include BCDD::Result::RollbackOnFailure

    input do
      attribute :uuid, value: :uuid, default: -> { ::SecureRandom.uuid }
      attribute :name, contract: { type: ::String }, normalize: -> { _1.strip.gsub(/\s+/, ' ') }
      attribute :email, contract: { email: true }, normalize: -> { _1.strip.downcase }
      attribute :password, contract: { password: true }
      attribute :password_confirmation, contract: { password: true }
    end

    output do
      Failure(
        invalid_user: contract.with(:errors_by_attribute),
        email_already_taken: contract.with(empty: true)
      )

      Success user_created: contract.schema(
        user: { type: ::User, persisted: true },
        token: { type: Token, persisted: true }
      )
    end

    def call(input)
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
      ::RuntimeBreaker.try_to_interrupt(env: 'BREAK_USER_CREATION')

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
