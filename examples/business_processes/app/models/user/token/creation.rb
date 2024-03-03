# frozen_string_literal: true

class User::Token
  class Creation < ::BCDD::Process
    input do
      attribute :user, contract: { type: ::User, persisted: true }
      attribute :executed_at, contract: { type: ::Time }, default: -> { ::Time.current }
    end

    output do
      Failure(
        token_already_exists: contract.with(empty: true),
        token_creation_failed: contract.with(:errors_by_attribute)
      )

      Success token_created: contract.schema(
        token: { type: User::Token, persisted: true }
      )
    end

    def call(input)
      Given(input)
        .and_then(:validate_token_existence)
        .and_then(:create_token)
        .and_expose(:token_created, %i[token])
    end

    private

    def validate_token_existence(user:, **)
      user.token.nil? ? Continue() : Failure(:token_already_exists)
    end

    def create_token(user:, executed_at:, **)
      ::RuntimeBreaker.try_to_interrupt(env: 'BREAK_USER_TOKEN_CREATION')

      token = user.create_token(
        access_token: ::SecureRandom.hex(24),
        refresh_token: ::SecureRandom.hex(24),
        access_token_expires_at: executed_at + 15.days,
        refresh_token_expires_at: executed_at + 30.days
      )

      token.persisted? ? Continue(token:) : Failure(:token_creation_failed, **token.errors.messages)
    end
  end
end
