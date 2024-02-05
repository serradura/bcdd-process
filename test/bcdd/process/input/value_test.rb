# frozen_string_literal: true

require 'test_helper'

class BCDD::Process::InputValueTest < Minitest::Test
  class MyProcess < BCDD::Process
    input do
      attribute :uuid1, value: :uuid
      attribute :uuid2, value: :uuid
    end

    output(expectations: false)

    def call(**input)
      Success(:input, **input)
    end
  end

  test 'valid value' do
    # Arrange
    input = {
      uuid1: '   324bba8c-deb5-48ab-8a84-53ab3e045836',
      uuid2: nil
    }

    # Act
    result = MyProcess.call(**input)

    # Assert

    assert_equal('324bba8c-deb5-48ab-8a84-53ab3e045836', result.value[:uuid1])
    assert_match(TestUtils::UUID_REGEX, result.value[:uuid1])
  end

  test 'invalid value' do
    # Arrange
    input = {
      uuid1: '324bba8c',
      uuid2: 1
    }

    # Act
    result = MyProcess.call(**input)

    # Assert
    assert result.failure?(:invalid_input)

    assert_equal(['"324bba8c" must be an UUID'], result.value[:uuid1])
    assert_equal(['1 must be a String'], result.value[:uuid2])
  end
end
