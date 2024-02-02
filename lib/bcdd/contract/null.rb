# frozen_string_literal: true

module BCDD::Contract
  # TODO: Move to bcdd-contract
  module Null
    class Checking
      include Core::Checking

      EMPTY_ARRAY = [].freeze

      def initialize(_checker, value)
        @value = value
        @errors = EMPTY_ARRAY
      end

      def errors_message
        ''
      end
    end
  end

  # TODO: Move to bcdd-contract
  def self.null(value)
    Null::Checking.new(nil, value)
  end
end
