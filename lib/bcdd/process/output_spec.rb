# frozen_string_literal: true

module BCDD
  class Process
    class OutputSpec
      def initialize
        @success = {}
        @failure = {}
      end

      def Success(**spec)
        @success = spec.transform_values(&BCDD::Contract)
      end

      def Failure(**spec)
        @failure = spec.transform_values(&BCDD::Contract)
      end

      # :nodoc:
      def __result__
        { success: @success, failure: @failure }
      end

      private

      def contract
        ::BCDD::Contract
      end
    end
  end
end
