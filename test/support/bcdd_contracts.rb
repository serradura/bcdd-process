# frozen_string_literal: true

module BCDD::Contract
  factory!(
    name: :presence,
    guard: ->(val, _) { val.present? },
    reserve: true
  )

  factory!(
    name: :persisted,
    guard: ->(val, _) { val.respond_to?(:persisted?) && val.persisted? },
    reserve: true
  )

  register!(:email, type: String, format: URI::MailTo::EMAIL_REGEXP)

  register!(:password, type: String, length: { in: 8..72 })
end
