# frozen_string_literal: true

require_relative 'value'

module BCDD
  class Data
    class Object
      attr_reader :attributes, :errors

      def initialize(**kargs)
        properties = self.class::Properties
        attributes = properties.map(kargs)

        @errors = {}
        @attributes =
          if properties.contract?
            attributes.each_with_object({}) do |(key, value), output|
              output[key] = value.valid? ? value.value : (errors[key] = value.errors)
            end
          else
            attributes.transform_values!(&:value)
          end
      end
    end

    class Properties
      attr_reader :spec, :contract

      def initialize
        @spec = {}
        @contract = false
      end

      def attribute(name, **options)
        name.is_a?(Symbol) or raise ArgumentError, "#{name.inspect} must be a Symbol"

        value_option = options[:value]

        spec[name] =
          if value_option
            (value_option.is_a?(Value::Object) ? value_option : Value[value_option])::Properties
          else
            Value::Properties.new(options).freeze
          end
      end

      def freeze
        @contract = spec.any? { |_, properties| properties.contract? }

        spec.freeze

        super
      end

      def contract?
        contract
      end

      def map(input)
        spec.each_with_object({}) do |(name, properties), output|
          output[name] = properties.map(input[name])
        end
      end
    end

    class Evaluator
      # :nodoc:
      attr_reader :properties

      def initialize
        @properties = Data::Properties.new
      end

      def attribute(name, **options)
        properties.attribute(name, **options)
      end

      private

      def contract
        BCDD::Contract
      end
    end

    def self.new(&block)
      evaluator = Evaluator.new
      evaluator.instance_eval(&block)

      klass = ::Class.new(Object)
      klass.const_set(:Properties, evaluator.properties.freeze)
      klass
    end
  end
end
