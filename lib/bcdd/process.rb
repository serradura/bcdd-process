# frozen_string_literal: true

require 'bcdd/result'

require_relative 'ext/contract'
require_relative 'ext/data'

require_relative 'process/version'
require_relative 'process/output'

module BCDD
  class Process
    module Caller
      def call(arg)
        input = self.class::Input.new(**arg)

        Result.transitions(name: self.class.name) do
          return Failure(:invalid_input, **input.violations) if input.violations.any?

          super(input.attributes)
        end
      end
    end

    def self.input(&block)
      return if const_defined?(:Input)

      const_set(:Input, ::BCDD::Data.new(&block))
    end

    RESULT_CONFIG = { addon: { given: true, continue: true }.freeze }.freeze

    def self.output(expectations: true, &block)
      return if const_defined?(:Result, false)

      if expectations
        evaluator = Output::Evaluator.new
        evaluator.instance_eval(&block)

        success = evaluator.__properties__.success
        failure = evaluator.__properties__.failure

        include(Result::Context::Expectations.mixin(config: RESULT_CONFIG, success: success, failure: failure))
      else
        include(Result::Context.mixin(config: RESULT_CONFIG))
      end
    end

    def self.inherited(subclass)
      subclass.prepend(Caller)
    end

    def self.call(input)
      new.call(input)
    end

    private_constant :Caller, :RESULT_CONFIG
  end
end
