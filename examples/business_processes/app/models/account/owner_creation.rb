# frozen_string_literal: true

class Account
  class OwnerCreation < ::BCDD::Process
    include BCDD::Result::RollbackOnFailure

    input do
      attribute :uuid, contract: :is_uuid, default: -> { ::SecureRandom.uuid }, normalize: -> { _1.strip.downcase }
      attribute :owner, type: ::Hash, validate: :is_present
    end

    output do
      Failure(
        invalid_owner: ::Hash,
        invalid_account: :errors_by_attribute,
      )

      user = contract[::User] & :is_persisted
      account = contract[::Account] & :is_persisted

      Success(account_owner_created: { account:, user: })
    end

    def call(**input)
      Given(input)
        .then { |result|
          rollback_on_failure {
            result
              .and_then(:create_owner)
              .and_then(:create_account)
              .and_then(:link_owner_to_account)
          }
        }.and_expose(:account_owner_created, %i[account user])
    end

    private

    def create_owner(owner:, **)
      ::User::Creation.call(**owner).handle do |on|
        on.success { |output| Continue(user: output[:user]) }
        on.failure { |output| Failure(:invalid_owner, **output) }
      end
    end

    def create_account(uuid:, **)
      ::RuntimeBreaker.try_to_interrupt(env: 'BREAK_ACCOUNT_CREATION')

      account = ::Account.create(uuid:)

      account.persisted? ? Continue(account:) : Failure(:invalid_account, **account.errors.messages)
    end

    def link_owner_to_account(account:, user:, **)
      Member.create!(account:, user:, role: :owner)

      Continue()
    end
  end
end
