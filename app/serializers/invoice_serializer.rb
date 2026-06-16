module InvoiceSerializer
  module_function

  def call(invoice)
    {
      id: invoice.id,
      customer_id: invoice.customer_id,
      invoice_number: invoice.invoice_number,
      amount_cents: invoice.amount_cents,
      balance_cents: invoice.balance_cents,
      currency: invoice.currency,
      status: invoice.status,
      issued_on: invoice.issued_on.iso8601,
      due_date: invoice.due_date.iso8601,
      overdue: invoice.past_due?,
      external_ref: invoice.external_ref,
      created_at: invoice.created_at.iso8601
    }
  end
end
