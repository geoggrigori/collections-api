class Invoice < ApplicationRecord
  belongs_to :customer
  has_many :payment_applications, dependent: :restrict_with_error
  has_many :payments, through: :payment_applications

  enum :status, { open: 0, partially_paid: 1, paid: 2, overdue: 3, void: 4 }, default: :open

  validates :invoice_number, presence: true,
                             uniqueness: { scope: :customer_id }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :balance_cents, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: ->(inv) { inv.amount_cents }
  }
  validates :currency, presence: true
  validates :issued_on, :due_date, presence: true

  before_validation :set_initial_balance, on: :create

  scope :unpaid, -> { where(status: %i[open partially_paid overdue]) }
  scope :past_due, -> { unpaid.where(due_date: ...Date.current) }

  # Aplica um valor (em centavos) a esta fatura, abatendo o saldo e
  # atualizando o status. Retorna o valor efetivamente aplicado.
  def apply_payment_cents(amount)
    applied = [amount, balance_cents].min
    self.balance_cents -= applied
    self.status = balance_cents.zero? ? :paid : :partially_paid
    applied
  end

  # "Efetivamente vencida": tem saldo em aberto e ja passou do vencimento.
  # Diferente do status :overdue (atualizado em lote pelo OverdueSweepJob);
  # aqui usamos o predicado de enum overdue? para evitar recursao.
  def past_due?
    unpaid? && due_date < Date.current
  end

  # Possui saldo em aberto (qualquer status exceto paid/void).
  def unpaid?
    open? || partially_paid? || overdue?
  end

  private

  def set_initial_balance
    self.balance_cents ||= amount_cents
  end
end
