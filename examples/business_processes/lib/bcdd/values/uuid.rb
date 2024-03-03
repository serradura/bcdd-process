# frozen_string_literal: true

require_relative '../contracts'

module BCDD
  module Values
    register(
      name: :uuid,
      contract: { uuid: true },
      normalize: -> { _1.strip.downcase }
    )
  end
end
