module Payments
  # Concilia um pagamento liquidado com as faturas em aberto do cliente,
  # do vencimento mais antigo para o mais novo (FIFO) -- o padrao de
  # "cash application" em contas a receber. Idempotente: so aplica o saldo
  # ainda nao alocado e roda dentro de uma transacao com row locks.
  class Applicator
    def self.call(payment)
      new(payment).call
    end

    def initialize(payment)
      @payment = payment
    end

    def call
      ActiveRecord::Base.transaction do
        remaining = @payment.unapplied_cents
        invoices = @payment.customer.invoices.unpaid.order(:due_date).lock(true)

        invoices.each do |invoice|
          break if remaining <= 0

          applied = invoice.apply_payment_cents(remaining)
          next if applied <= 0

          invoice.save!
          PaymentApplication.create!(payment: @payment, invoice: invoice, amount_cents: applied)
          remaining -= applied
        end

        @payment.update!(status: :succeeded, received_at: Time.current)
      end
      @payment
    end
  end
end
