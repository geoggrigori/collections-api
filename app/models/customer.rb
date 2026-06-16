class Customer < ApplicationRecord
  has_many :invoices, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error

  enum :status, { active: 0, on_hold: 1, delinquent: 2 }, default: :active

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :external_ref, uniqueness: true, allow_nil: true
  validates :credit_limit_cents, numericality: { greater_than_or_equal_to: 0 }

  scope :with_open_balance, lambda {
    where(id: Invoice.unpaid.select(:customer_id))
  }

  # Soma do saldo em aberto de todas as faturas do cliente (em centavos).
  def outstanding_balance_cents
    invoices.unpaid.sum(:balance_cents)
  end

  # Quanto ainda pode ser faturado antes de estourar o limite de credito.
  def available_credit_cents
    credit_limit_cents - outstanding_balance_cents
  end
end
