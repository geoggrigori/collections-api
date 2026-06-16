# Importa um lote de faturas vindas do ERP de forma idempotente.
# Usa upsert_all com chave [customer_id, invoice_number], entao reprocessar
# o mesmo lote nao gera duplicatas — essencial para ETL confiavel.
class ErpInvoiceImportJob < ApplicationJob
  queue_as :etl

  def perform(rows)
    rows = rows.map { |r| r.symbolize_keys }
    Invoice.upsert_all(rows, unique_by: %i[customer_id invoice_number])
  end
end
