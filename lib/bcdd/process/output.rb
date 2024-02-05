# frozen_string_literal: true

module BCDD
  class Process
    module Output
      # :nodoc:
      class Properties
        attr_reader :success

        def initialize
          @success = {}
          @failure = {}
        end

        def success=(spec)
          @success = spec.transform_values(&BCDD::Contract)
        end

        def failure=(spec)
          @failure = spec.transform_values(&BCDD::Contract)
        end

        INVALID_INPUT = { invalid_input: ::Hash }.freeze

        def failure
          INVALID_INPUT.merge(@failure)
        end
      end

      class Evaluator
        # :nodoc:
        attr_reader :__properties__

        def initialize
          @__properties__ = Properties.new
        end

        private

        def Success(**spec)
          __properties__.success = spec
        end

        def Failure(**spec)
          __properties__.failure = spec
        end

        def contract
          ::BCDD::Contract
        end
      end
    end
  end
end
