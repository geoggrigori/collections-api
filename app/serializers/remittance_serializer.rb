module RemittanceSerializer
  module_function

  def call(remittance)
    {
      id: remittance.id,
      customer_id: remittance.customer_id,
      amount_cents: remittance.amount_cents,
      raw_text: remittance.raw_text,
      status: remittance.status,
      confidence: remittance.confidence,
      match_source: remittance.match_source,
      matched_invoice_numbers: remittance.matched_invoice_numbers,
      payment_id: remittance.payment_id,
      created_at: remittance.created_at.iso8601
    }
  end
end
