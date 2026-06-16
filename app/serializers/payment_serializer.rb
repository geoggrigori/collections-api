module PaymentSerializer
  module_function

  def call(payment)
    {
      id: payment.id,
      customer_id: payment.customer_id,
      amount_cents: payment.amount_cents,
      applied_cents: payment.applied_cents,
      unapplied_cents: payment.unapplied_cents,
      payment_method: payment.payment_method,
      status: payment.status,
      external_ref: payment.external_ref,
      received_at: payment.received_at&.iso8601,
      created_at: payment.created_at.iso8601,
      applications: payment.payment_applications.map do |app|
        { invoice_id: app.invoice_id, amount_cents: app.amount_cents }
      end
    }
  end
end
