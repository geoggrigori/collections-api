namespace :etl do
  desc "Sincroniza faturas do ERP enfileirando jobs de import. Ex: rake 'etl:sync[5000,500]'"
  task :sync, %i[count batch_size] => :environment do |_t, args|
    count = (args[:count] || 5_000).to_i
    batch_size = (args[:batch_size] || 500).to_i
    customer_ids = Customer.ids
    raise "Nenhum cliente. Rode rails db:seed primeiro." if customer_ids.empty?

    feed = Erp::InvoiceFeed.new(customer_ids: customer_ids)
    tag = "SYNC#{Time.current.to_i}"
    feed.fetch(count: count, batch_tag: tag).each_slice(batch_size) do |batch|
      ErpInvoiceImportJob.perform_later(batch)
    end
    puts "Enfileirados #{(count.to_f / batch_size).ceil} lotes (#{count} faturas) na fila :etl."
  end

  desc "Marca faturas vencidas como overdue"
  task sweep_overdue: :environment do
    puts "Faturas marcadas como overdue: #{OverdueSweepJob.perform_now}"
  end
end
