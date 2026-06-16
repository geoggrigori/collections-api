# Varre as faturas em aberto/parciais que ja venceram e as marca como overdue.
# Roda em massa via update_all (uma unica query) para escalar com milhoes de linhas.
class OverdueSweepJob < ApplicationJob
  queue_as :default

  def perform
    count = Invoice
            .where(status: %i[open partially_paid])
            .where(due_date: ...Date.current)
            .update_all(status: Invoice.statuses[:overdue], updated_at: Time.current)
    Rails.logger.info("OverdueSweepJob: #{count} faturas marcadas como overdue")
    count
  end
end
