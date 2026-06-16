module Erp
  # Simula um feed de faturas vindo de um ERP (NetSuite/Sage/Acumatica).
  # Em producao isto seria um client HTTP/SOAP paginando o ERP; aqui geramos
  # linhas realistas e deterministicas (seed do RNG) prontas para upsert.
  class InvoiceFeed
    AMOUNT_RANGE = (50_00..9_500_00).freeze
    TERMS_DAYS = [15, 30, 45, 60].freeze

    def initialize(customer_ids:, seed: 42)
      @customer_ids = customer_ids
      @rng = Random.new(seed)
    end

    # Retorna `count` linhas de fatura (hashes) prontas para insert_all/upsert_all.
    def fetch(count:, batch_tag:)
      now = Time.current
      Array.new(count) do |i|
        amount = @rng.rand(AMOUNT_RANGE)
        issued = Date.current - @rng.rand(0..90)
        {
          customer_id: @customer_ids.sample(random: @rng),
          invoice_number: "#{batch_tag}-#{i}",
          amount_cents: amount,
          balance_cents: amount,
          currency: "USD",
          issued_on: issued,
          due_date: issued + TERMS_DAYS.sample(random: @rng),
          status: 0,
          external_ref: "ERPDOC-#{batch_tag}-#{i}",
          created_at: now,
          updated_at: now
        }
      end
    end
  end
end
