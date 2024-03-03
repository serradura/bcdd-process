# frozen_string_literal: true

class Account
  class OwnerCreation < ::BCDD::Process
    include BCDD::Result::RollbackOnFailure

    input do
      attribute :uuid, value: :uuid, default: -> { ::SecureRandom.uuid }
      attribute :owner, contract: { type: ::Hash }
    end

    output do
      Failure(
        invalid_owner: contract.with(empty: false),
        invalid_account: contract.with(:errors_by_attribute)
      )

      Success account_owner_created: contract.schema(
        user: { type: ::User, persisted: true },
        account: { type: ::Account, persisted: true }
      )
    end

    def call(input)
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
