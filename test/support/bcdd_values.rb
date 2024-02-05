# frozen_string_literal: true

require 'securerandom'

module BCDD
  module Contracts
    is_uuid = ->(val) { val.match?(/\A[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}\z/) or '%p must be an UUID' }

    register(is_uuid: contract[::String] & is_uuid)
  end

  module Values
    register(
      name: :uuid,
      contract: :is_uuid,
      normalize: -> { _1.is_a?(::String) ? _1.strip.downcase : _1 },
      default: -> { ::SecureRandom.uuid }
    )
  end
end
