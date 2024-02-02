# frozen_string_literal: true

require 'bcdd/result'
require 'bcdd/contract'

require_relative 'contracts'
require_relative 'contract/null'

require_relative 'process/version'
require_relative 'process/caller'
require_relative 'process/input_spec'
require_relative 'process/output_spec'

module BCDD
  class Process
    class << self
      attr_reader :__input__, :__input_contract__, :__output__

      def input(&block)
        return @__input__ if defined?(@__input__)

        spec = InputSpec.new
        spec.instance_eval(&block)
        spec.__result__.transform_values!(&:freeze).freeze

        @__input_contract__ = spec.__result__.any? { |_key, value| value.key?(:contract) }
        @__input__ = spec.__result__
      end

      def output(expectations: true, &block)
        @__output__ and raise ArgumentError, 'outputs already defined'

        config = { addon: { given: true, continue: true } }

        if expectations
          spec = OutputSpec.new
          spec.instance_eval(&block)

          output = spec.__result__
          success = output[:success]
          failure = output.fetch(:failure, {}).merge(invalid_input: ::Hash)

          include(Result::Context::Expectations.mixin(config: config, success: success, failure: failure))
        else
          include(Result::Context.mixin(config: config))
        end

        @__output__ = { expectations: expectations }.freeze
      end

      def inherited(subclass)
        subclass.prepend(Caller)
      end

      def call(**input)
        new.call(**input)
      end
    end
  end
end
