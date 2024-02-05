# frozen_string_literal: true

require 'test_helper'

class BCDD::Process::InputRespondToTest < Minitest::Test
  class MyProcess < BCDD::Process
    input do
      attribute :str, respond_to: :to_str
      attribute :sym, respond_to: :to_sym
      attribute :str_sym, respond_to: %i[to_str to_sym]
    end

    output(expectations: false)

    def call(**input)
      Success(:input, **input)
    end
  end

  test 'input respond_to (valid)' do
    # Arrange
    input = {
      str: 'John Doe',
      sym: :john_doe,
      str_sym: 'John Doe'
    }

    # Act
    result = MyProcess.call(**input)

    # Assert
    assert_predicate result, :success?

    assert_equal input, result.value
  end

  test 'input respond_to (invalid)' do
    # Arrange
    input = {
      str: 123,
      sym: 123,
      str_sym: :symbol
    }

    # Act
    result = MyProcess.call(**input)

    # Assert
    assert_predicate result, :failure?

    assert_equal(
      {
        str: ['123 must respond to [:to_str]'],
        sym: ['123 must respond to [:to_sym]'],
        str_sym: [':symbol must respond to [:to_str, :to_sym]']
      },
      result.value
    )
  end
end
