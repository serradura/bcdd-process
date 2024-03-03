# frozen_string_literal: true

require 'singleton'

module BCDD
  class Value
    class Object
      attr_reader :value, :contract

      def initialize(value = nil)
        properties = self.class::Properties
        contract = properties.map(value)

        @contract = contract
        @value = contract.value
      end
    end

    class Properties
      Contract = ->(options) do
        contract = options[:contract]
        required = options.fetch(:required, true)

        if contract.is_a?(BCDD::Contract::Value::Checker) ||
           contract.is_a?(BCDD::Contract::Data::Schema) ||
           contract.is_a?(BCDD::Contract::Data::Pairs)
          return contract
        end

        return unless contract || required

        !contract && required and return BCDD::Contract.with(allow_nil: false)

        BCDD::Contract.with(**(required ? contract : contract.merge(allow_nil: true)))
      end

      Default = ->(options) do
        value = options[:default]

        return value unless value.is_a?(Proc)
        return value if value.lambda? && value.arity.zero?

        raise ArgumentError, 'Default value must be a lambda with zero arity'
      end

      Normalize = ->(options) do
        value = options[:normalize]

        return value if value.is_a?(Proc)

        raise ArgumentError, 'normalize value must be a lambda'
      end

      attr_reader :spec, :contract

      def initialize(options)
        @contract = false

        contract = Contract[options]

        @spec = {}
        @spec[:default] = Default[options] if options.key?(:default)
        @spec[:contract] = contract if contract
        @spec[:normalize] = Normalize[options] if options.key?(:normalize)
      end

      def freeze
        @contract = spec.key?(:contract)

        spec.freeze

        super
      end

      def contract?
        contract
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def map(value)
        if !value && spec.key?(:default)
          default = spec[:default]

          value = default.is_a?(::Proc) ? default.call : default
        end

        type = spec[:contract]&.clauses&.[](:type)

        value = spec[:normalize].call(value) if spec.key?(:normalize) && (!type || type.any? { |type| type === value })

        spec.key?(:contract) ? spec[:contract][value] : Contract.null(value)
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end

    class Registry
      include ::Singleton

      attr_reader :registry

      def initialize
        @registry = {}
      end

      def self.write(options)
        name = options.delete(:name)

        name.is_a?(Symbol) or raise ArgumentError, "#{name.inspect} must be a Symbol"

        instance.registry[name] = Value.new(**options)
      end

      def self.read(name)
        value_object = instance.registry[name]

        value_object or raise ArgumentError, "#{name.inspect} is not registered"
      end
    end

    def self.new(**options)
      klass = ::Class.new(Object)
      klass.const_set(:Properties, Properties.new(options).freeze)
      klass
    end

    def self.[](name)
      Registry.read(name)
    end
  end

  module Values
    class << self
      private

      def register(**options)
        Value::Registry.write(options)
      end
    end
  end
end
