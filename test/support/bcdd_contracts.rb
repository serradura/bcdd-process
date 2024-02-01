# frozen_string_literal: true

module BCDD::Contracts
  HasSize = ->(min, max) { ->(val) { val.size.between?(min, max) or "must be >= #{min} and <= #{max} chars" } }

  is_str = ::BCDD::Contract[::String]
  is_email = ->(val) { val.match?(::URI::MailTo::EMAIL_REGEXP) or '%p must be an email' }
  is_present = ->(val) { val.present? or '%p must be present' }
  is_persisted = ->(val) { val.persisted? or '%p must be persisted' }

  ::BCDD::Contract.register(
    is_str: is_str,
    is_email: is_str & is_email,
    is_present: is_present,
    is_password: is_str & is_present & HasSize[8, 72],
    is_persisted: is_persisted
  )

  EmptyHash = ::BCDD::Contract[::Hash] & ->(value) { value.empty? }

  ::BCDD::Contract.register(
    empty_hash: EmptyHash
  )
end
