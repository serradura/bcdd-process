# frozen_string_literal: true

require 'test_helper'

class BCDD::Process::InputNormalizeTest < Minitest::Test
  class MyProcess < BCDD::Process
    input do
      attribute :name, normalize: -> { _1.strip.gsub(/\s+/, ' ') }
      attribute :string, normalize: proc(&:to_s)
      attribute :string_strip, normalize: proc(&:to_s) >> proc(&:strip)
    end

    output(expectations: false)

    def call(input)
      Success(:input, **input)
    end
  end

  test 'input normalization' do
    # Arrange
    input = {
      name: "\tJohn     Doe \n",
      string: 123,
      string_strip: "  \t 321 \n  "
    }

    # Act
    result = MyProcess.call(input)

    # Assert

    assert_equal({ name: 'John Doe', string: '123', string_strip: '321' }, result.value)
  end
end
