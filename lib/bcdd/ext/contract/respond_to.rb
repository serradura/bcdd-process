# frozen_string_literal: true

module BCDD::Contract
  # TODO: Move to bcdd-contract
  module RespondTo
    class Checking
      include Core::Checking

      def initialize(method_names, value)
        @value = value
        @errors = []

        validate(method_names, @errors)
      end

      def errors_message
        valid? ? '' : errors[0]
      end

      private

      def validate(method_names, errors)
        return if method_names.all? { |method_name| value.respond_to?(method_name) }

        errors << format('%p must respond to %p', value, method_names)
      end
    end

    module Checker
      include Core::Checker
    end

    def self.new(args)
      args.is_a?(Array) or raise ::ArgumentError, format('%p must be an array', args)

      raise ::ArgumentError, "Must provide at least one symbol #{args.inspect}" if args.empty? || !args.all?(::Symbol)

      Core::Factory.new(Checker, Checking, args)
    end
  end

  # TODO: Move to bcdd-contract
  def self.respond_to(args)
    RespondTo.new(args)
  end

  private_constant :RespondTo
end
