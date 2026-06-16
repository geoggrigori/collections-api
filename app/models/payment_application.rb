class PaymentApplication < ApplicationRecord
  belongs_to :payment
  belongs_to :invoice

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :payment_id, uniqueness: { scope: :invoice_id }

  validate :same_customer
  validate :within_payment_amount

  private

  def same_customer
    return if payment.nil? || invoice.nil?
    return if payment.customer_id == invoice.customer_id

    errors.add(:invoice, "pertence a outro cliente diferente do pagamento")
  end

  def within_payment_amount
    return if payment.nil? || amount_cents.nil?
    return if amount_cents <= payment.unapplied_cents + (amount_cents_was || 0)

    errors.add(:amount_cents, "excede o valor disponivel do pagamento")
  end
end
