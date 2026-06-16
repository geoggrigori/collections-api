# Seed de demonstracao: gera um dataset grande para exercitar consultas,
# indices e o pipeline de ETL. Configuravel por env:
#   SEED_CUSTOMERS (default 500)  SEED_INVOICES (default 50_000)
require "benchmark"

NUM_CUSTOMERS = Integer(ENV.fetch("SEED_CUSTOMERS", 500))
NUM_INVOICES  = Integer(ENV.fetch("SEED_INVOICES", 50_000))

puts "Limpando dados existentes..."
PaymentApplication.delete_all
Payment.delete_all
Invoice.delete_all
Customer.delete_all

now = Time.current
credit_tiers = [100_000, 500_000, 1_000_000, 5_000_000].freeze

puts "Criando #{NUM_CUSTOMERS} clientes..."
customers = Array.new(NUM_CUSTOMERS) do |i|
  {
    name: "Distribuidora #{i + 1}",
    email: "ap#{i + 1}@example.com",
    external_ref: "ERP-#{100_000 + i}",
    credit_limit_cents: credit_tiers.sample,
    status: 0,
    created_at: now, updated_at: now
  }
end
Customer.insert_all(customers)
customer_ids = Customer.ids

puts "Gerando #{NUM_INVOICES} faturas via feed do ERP..."
feed = Erp::InvoiceFeed.new(customer_ids: customer_ids)
elapsed = Benchmark.realtime do
  feed.fetch(count: NUM_INVOICES, batch_tag: "SEED").each_slice(5_000) do |batch|
    Invoice.insert_all(batch)
  end
end
puts "  inseridas em #{elapsed.round(2)}s"

puts "Marcando faturas vencidas como overdue..."
OverdueSweepJob.perform_now

puts "Seed pronto: #{Customer.count} clientes, #{Invoice.count} faturas " \
     "(#{Invoice.overdue.count} overdue)."
