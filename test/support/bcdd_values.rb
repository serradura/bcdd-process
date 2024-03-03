# frozen_string_literal: true

require 'securerandom'

module BCDD
  module Contract
    register!(:uuid, type: String, format: /\A[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}\z/)
  end

  module Values
    register(
      name: :uuid,
      contract: { uuid: true },
      normalize: -> { _1.strip.downcase }
    )
  end
end
