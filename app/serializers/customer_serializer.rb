# Serializer simples (PORO) - sem dependencia externa, facil de versionar.
module CustomerSerializer
  module_function

  def call(customer)
    {
      id: customer.id,
      name: customer.name,
      email: customer.email,
      external_ref: customer.external_ref,
      status: customer.status,
      credit_limit_cents: customer.credit_limit_cents,
      outstanding_balance_cents: customer.outstanding_balance_cents,
      available_credit_cents: customer.available_credit_cents,
      created_at: customer.created_at.iso8601
    }
  end
end
