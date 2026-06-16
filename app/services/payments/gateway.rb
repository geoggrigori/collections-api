module Payments
  # Abstrai o provedor de pagamento. Usa Stripe de verdade quando
  # STRIPE_SECRET_KEY esta presente; caso contrario, um gateway fake
  # deterministico para rodar a demo sem credenciais reais.
  module Gateway
    module_function

    def enabled?
      ENV["STRIPE_SECRET_KEY"].present?
    end

    # Cria um PaymentIntent e retorna { id:, status: }.
    def create_intent(amount_cents:, currency:, customer_ref:, method: "ach")
      return fake_intent unless enabled?

      types = method.to_s == "card" ? ["card"] : ["us_bank_account"]
      intent = Stripe::PaymentIntent.create(
        amount: amount_cents,
        currency: currency.downcase,
        payment_method_types: types,
        metadata: { customer_ref: customer_ref }
      )
      { id: intent.id, status: intent.status }
    end

    def fake_intent
      { id: "pi_fake_#{SecureRandom.hex(8)}", status: "requires_confirmation" }
    end
  end
end
