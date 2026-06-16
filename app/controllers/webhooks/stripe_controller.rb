module Webhooks
  # Recebe webhooks do Stripe. Verifica a assinatura quando o segredo esta
  # configurado; ao receber payment_intent.succeeded, concilia o pagamento.
  class StripeController < ActionController::API
    def create
      event = parse_event(request.body.read)
      return head :bad_request unless event

      if event["type"] == "payment_intent.succeeded"
        intent_id = event.dig("data", "object", "id")
        payment = Payment.find_by(external_ref: intent_id)
        Payments::Applicator.call(payment) if payment && !payment.succeeded?
      end

      head :ok
    end

    private

    def parse_event(payload)
      secret = ENV["STRIPE_WEBHOOK_SECRET"]
      if secret.present?
        Stripe::Webhook.construct_event(payload, request.env["HTTP_STRIPE_SIGNATURE"], secret)
      else
        JSON.parse(payload)
      end
    rescue JSON::ParserError, Stripe::SignatureVerificationError
      nil
    end
  end
end
