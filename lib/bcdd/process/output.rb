# frozen_string_literal: true

module BCDD
  class Process
    module Output
      # :nodoc:
      class Properties
        attr_accessor :success

        def initialize
          @success = {}
          @failure = {}
        end

        attr_writer :failure

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

        module ContractWrapper
          def self.with(arg)
            options =
              case arg
              when ::Hash then { type: ::Hash }.merge(arg)
              when ::Symbol then { arg => true }
              else raise ArgumentError, "Invalid argument: #{arg.inspect}, expected Hash or Symbol"
              end

            ::BCDD::Contract.with(**options)
          end

          def self.schema(**options)
            with(schema: options)
          end

          def self.pairs(**options)
            with(pairs: options)
          end
        end

        def contract
          ContractWrapper
        end
      end
    end
  end
end
