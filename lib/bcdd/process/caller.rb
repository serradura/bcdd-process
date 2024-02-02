# frozen_string_literal: true

module BCDD
  class Process
    module Caller
      PrepareInputs = ->(spec, input) do
        spec.each_with_object({}) do |(name, options), result|
          value = input.fetch(name) do
            if options.key?(:default)
              default = options[:default]

              default.is_a?(::Proc) ? default.call : default
            end
          end

          value = options[:normalize].call(value) if options.key?(:normalize)

          result[name] = options.key?(:contract) ? options[:contract][value] : Contract.null(value)
        end
      end

      def call(**inputs)
        prepared_input = PrepareInputs[self.class.__input__, inputs]

        Result.transitions(name: self.class.name) do
          if self.class.__input_contract__
            invalid_input = prepared_input.select { |_key, value| value.invalid? }

            return Failure(:invalid_input, **invalid_input.transform_values(&:errors)) unless invalid_input.empty?
          end

          super(**prepared_input.transform_values!(&:value))
        end
      end
    end
  end
end
