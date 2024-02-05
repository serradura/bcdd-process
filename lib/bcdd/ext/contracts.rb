# frozen_string_literal: true

# TODO: Move to bcdd-contract
module BCDD::Contracts
  class << self
    private

    def contract
      ::BCDD::Contract
    end

    def register(**kargs)
      # TODO: Remove this method and make the use open BCDD::Contracts module to register contracts
      ::BCDD::Contract.register(**kargs)
    end
  end

  NotNil = contract[-> { _1.nil? and 'cannot be nil' }]

  register(not_nil: NotNil)
end
