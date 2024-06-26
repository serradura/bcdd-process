# frozen_string_literal: true

class Account
  class OwnerCreation < ::BCDD::Process
    include BCDD::Result::RollbackOnFailure

    input do
      attribute :uuid, value: :uuid
      attribute :owner, type: ::Hash, contract: :is_present
    end

    output do
      Failure(
        invalid_owner: ::Hash,
        invalid_account: :errors_by_attribute
      )

      Success account_owner_created: {
        user: contract[::User] & :is_persisted,
        account: contract[::Account] & :is_persisted
      }
    end

    def call(**input)
      rollback_on_failure {
        Given(input)
          .and_then(:create_owner)
          .and_then(:create_account)
          .and_then(:link_owner_to_account)
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
