class Payment < ApplicationRecord
  belongs_to :customer
  has_many :payment_applications, dependent: :destroy
  has_many :invoices, through: :payment_applications

  enum :payment_method, { ach: 0, card: 1, check: 2, wire: 3 }, default: :ach
  enum :status, { pending: 0, succeeded: 1, failed: 2, refunded: 3 }, default: :pending

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :external_ref, uniqueness: true, allow_nil: true

  scope :settled, -> { where(status: :succeeded) }

  # Soma ja alocada a faturas (em centavos).
  def applied_cents
    payment_applications.sum(:amount_cents)
  end

  # Valor ainda nao conciliado com nenhuma fatura.
  def unapplied_cents
    amount_cents - applied_cents
  end
end
