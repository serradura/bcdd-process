# frozen_string_literal: true

require 'bcdd/contract'

require_relative 'contracts'
require_relative 'contract/null'

module BCDD::Contract
  # TODO: Move to bcdd-contract
  def self.type(arg)
    arg.is_a?(::Module) or raise ::ArgumentError, format('%p must be a class OR module', arg)

    unit(arg)
  end
end
