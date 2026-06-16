class Remittance < ApplicationRecord
  belongs_to :customer
  belongs_to :payment, optional: true

  enum :status, { received: 0, matched: 1, needs_review: 2 }, default: :received

  validates :raw_text, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }
end
