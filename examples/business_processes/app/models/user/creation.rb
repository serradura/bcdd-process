# frozen_string_literal: true

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
        email_already_taken: :empty_hash,
      )

      user = contract[::User] & :is_persisted
      token = contract[Token] & :is_persisted

      Success(user_created: { user:, token: })
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
