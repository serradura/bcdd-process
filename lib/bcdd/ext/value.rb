# frozen_string_literal: true

require 'singleton'

module BCDD
  class Value
    class Object
      attr_reader :value, :errors

      def initialize(value = nil)
        properties = self.class::Properties
        contract = properties.map(value)

        @errors = contract.errors
        @value = contract.value
      end
    end

    class Properties
      module Contract
        def self.[](options)
          contract = compose(options)
          required = options.fetch(:required, true)

          if contract
            required ? contract : (contract | nil)
          elsif required
            Contracts::NotNil
          end
        end

        def self.compose(options)
          type = ::BCDD::Contract.type(options[:type]) if options.key?(:type)
          contract = ::BCDD::Contract[options[:contract]] if options.key?(:contract)
          respond_to = ::BCDD::Contract.respond_to(Array(options[:respond_to])) if options.key?(:respond_to)

          [type, contract, respond_to].compact!&.reduce(:&)
        end
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

      def map(value)
        if !value && spec.key?(:default)

          default = spec[:default]

          value = default.is_a?(::Proc) ? default.call : default
        end

        value = spec[:normalize].call(value) if spec.key?(:normalize)

        spec.key?(:contract) ? spec[:contract][value] : Contract.null(value)
      end
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
