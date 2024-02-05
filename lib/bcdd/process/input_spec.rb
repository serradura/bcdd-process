# frozen_string_literal: true

module BCDD
  class Process
    class InputSpec
      module MapContract
        def self.[](options)
          required = options.fetch(:required, true)

          if options.key?(:type) || options.key?(:contract) || options.key?(:respond_to)
            resolve(options).then { required ? _1 : (_1 | nil) }
          elsif required
            Contracts::NotNil
          end
        end

        def self.resolve(options)
          type = ::BCDD::Contract.type(options[:type]) if options.key?(:type)
          contract = ::BCDD::Contract[options[:contract]] if options.key?(:contract)
          respond_to = ::BCDD::Contract.respond_to(Array(options[:respond_to])) if options.key?(:respond_to)

          [type, contract, respond_to].compact.reduce(:&)
        end
      end

      MapDefault = ->(options) do
        value = options[:default]

        return value unless value.is_a?(Proc)
        return value if value.lambda? && value.arity.zero?

        raise ArgumentError, 'Default value must be a lambda with zero arity'
      end

      MapNormalize = ->(options) do
        value = options[:normalize]

        return value if value.is_a?(Proc)

        raise ArgumentError, 'normalize value must be a lambda'
      end

      # :nodoc:
      attr_reader :__result__

      def initialize
        @__result__ = {}
      end

      def attribute(name, **options)
        name.is_a?(Symbol) or raise ArgumentError, "#{name.inspect} must be a Symbol"

        spec = {}
        spec[:default] = MapDefault[options] if options.key?(:default)
        spec[:normalize] = MapNormalize[options] if options.key?(:normalize)

        MapContract[options].then { spec[:contract] = _1 if _1 }

        __result__[name] = spec
      end

      def contract
        BCDD::Contract
      end
    end
  end
end
