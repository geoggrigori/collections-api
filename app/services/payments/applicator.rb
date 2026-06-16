module Payments
  # Concilia um pagamento liquidado com faturas em aberto do cliente.
  # Por padrao aplica do vencimento mais antigo para o mais novo (FIFO) -- o
  # padrao de "cash application" em contas a receber. Um `scope` opcional
  # restringe a faturas especificas (ex.: as identificadas em uma remessa).
  # Idempotente: aplica apenas o saldo ainda nao alocado; roda em transacao
  # com row locks.
  class Applicator
    def self.call(payment, scope: nil)
      new(payment, scope).call
    end

    def initialize(payment, scope = nil)
      @payment = payment
      @scope = scope
    end

    def call
      ActiveRecord::Base.transaction do
        remaining = @payment.unapplied_cents
        invoices = (@scope || @payment.customer.invoices.unpaid).order(:due_date).lock(true)

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
