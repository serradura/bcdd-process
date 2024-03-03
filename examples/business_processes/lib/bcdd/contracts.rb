# frozen_string_literal: true

module BCDD::Contract
  factory!(
    name: :presence,
    guard: ->(val, _) { val.present? },
    reserve: true
  )

  factory!(
    name: :persisted,
    guard: ->(val, _) { val.respond_to?(:persisted?) && val.persisted?},
    reserve: true
  )

  register!(:uuid, type: String, presence: true, format: /\A[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}\z/)

  register!(:email, type: String, presence: true, format: URI::MailTo::EMAIL_REGEXP)

  register!(:password, type: String, presence: true, length: { in: 8..72 })

  register!(:errors_by_attribute, {
    type: Hash,
    pairs: {
      key: { type: Symbol },
      value: { type: Array, schema: { type: ::String } }
    }
  })
end
