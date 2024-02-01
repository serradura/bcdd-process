# frozen_string_literal: true

module BCDD::Contracts
  HasSize = ->(min, max) { ->(val) { val.size.between?(min, max) or "must be >= #{min} and <= #{max} chars" } }

  is_str = ::BCDD::Contract[::String]
  is_uuid = ->(val) { val.match?(/\A[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}\z/) or '%p must be an UUID' }
  is_email = ->(val) { val.match?(::URI::MailTo::EMAIL_REGEXP) or '%p must be an email' }
  is_present = ->(val) { val.present? or '%p must be present' }
  is_persisted = ->(val) { val.persisted? or '%p must be persisted' }

  ::BCDD::Contract.register(
    is_str: is_str,
    is_uuid: is_str & is_present & is_uuid,
    is_email: is_str & is_present& is_email,
    is_present: is_present,
    is_password: is_str & is_present & HasSize[8, 72],
    is_persisted: is_persisted
  )

  EmptyHash = ::BCDD::Contract[::Hash] & ->(value) { value.empty? }
  ErrorMessages = ::BCDD::Contract[errors: [::String]]
  ErrorsByAttribute = ::BCDD::Contract.pairs(::Symbol => [::String])

  ::BCDD::Contract.register(
    empty_hash: EmptyHash,
    error_messages: ErrorMessages,
    errors_by_attribute: ErrorsByAttribute
  )
end
