# frozen_string_literal: true

require 'test_helper'

class BCDD::ProcessTest < Minitest::Test
  class UserCreation < BCDD::Process
    input do
      uuid_format = -> { _1.match?(/\A[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}\z/i) or 'must be an UUID' }

      attribute :uuid, type: ::String, contract: uuid_format, default: -> { ::SecureRandom.uuid }
      attribute :name, type: ::String, contract: :is_present, normalize: -> { _1.strip.gsub(/\s+/, ' ') }
      attribute :email, contract: :is_email, normalize: -> { _1.strip.downcase }
      attribute :password, contract: :is_password
      attribute :executed_at, type: ::Time, default: -> { ::Time.current }
    end

    output do
      Failure(email_already_taken: :empty_hash)

      Success user_created: { user: contract[::User] & :is_persisted }
    end

    def call(**input)
      Given(input)
        .and_then(:validate_email_has_not_been_taken)
        .and_then(:create_user)
        .and_expose(:user_created, %i[user])
    end

    private

    def validate_email_has_not_been_taken(email:, **)
      ::User.exists?(email: email) ? Failure(:email_already_taken) : Continue()
    end

    def create_user(uuid:, name:, email:, password:, executed_at:)
      user = ::User.create!(
        uuid: uuid,
        name: name,
        email: email,
        password: password,
        created_at: executed_at,
        updated_at: executed_at
      )

      Continue(user: user)
    end
  end

  def setup
    ::User.delete_all
  end

  def test_that_it_has_a_version_number
    refute_nil ::BCDD::Process::VERSION
  end

  test 'success' do
    # Arrange
    input = { name: "\tJohn     Doe \n", email: '   JOHN.doe@email.com', password: '123123123' }

    user_count = ::User.count

    # Act
    result = UserCreation.call(**input)

    # Assert
    assert_equal(user_count + 1, ::User.count)

    assert result.success?(:user_created)

    user = result.value.fetch(:user)

    assert_match(TestUtils::UUID_REGEX, user.uuid)
    assert_equal('John Doe', user.name)
    assert_equal('john.doe@email.com', user.email)

    assert BCrypt::Password.new(user.password_digest).is_password?(input[:password])
  end

  test 'failure (invalid_input)' do
    # Arrange
    input = { name: '     ', email: 'John', password: '123123' }

    # Act
    result = UserCreation.call(**input)

    # Assert
    assert result.failure?(:invalid_input)
  end

  test 'failure (email_already_taken)' do
    # Arrange
    input = { name: 'John Doe', email: 'john.doe@email.com', password: '123123123' }

    UserCreation.new.call(**input)

    # Act
    result = UserCreation.new.call(**input)

    # Assert
    assert result.failure?(:email_already_taken)
  end
end
