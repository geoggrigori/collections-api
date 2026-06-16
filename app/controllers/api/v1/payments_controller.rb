module Api
  module V1
    class PaymentsController < BaseController
      # GET /api/v1/payments?customer_id=1&status=succeeded
      def index
        scope = Payment.all
        scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        render_collection(scope.order(created_at: :desc), PaymentSerializer)
      end

      # GET /api/v1/payments/:id
      def show
        render_resource(Payment.find(params[:id]), PaymentSerializer)
      end

      # POST /api/v1/payments
      # Cria um PaymentIntent no gateway e registra o pagamento como pending.
      def create
        customer = Customer.find(payment_params[:customer_id])
        method = payment_params[:payment_method].presence || "ach"
        intent = Payments::Gateway.create_intent(
          amount_cents: payment_params[:amount_cents].to_i,
          currency: "USD",
          customer_ref: customer.external_ref || customer.id.to_s,
          method: method
        )
        payment = customer.payments.create!(
          amount_cents: payment_params[:amount_cents],
          payment_method: method,
          status: :pending,
          external_ref: intent[:id]
        )
        render_resource(payment, PaymentSerializer, status: :created)
      end

      # POST /api/v1/payments/:id/settle
      # Simula a liquidacao e dispara a conciliacao. Disponivel apenas quando
      # o Stripe NAO esta configurado (em producao isso vem pelo webhook).
      def settle
        if Payments::Gateway.enabled?
          return render json: {
            error: { code: "forbidden", message: "Com Stripe ativo, a liquidacao vem pelo webhook." }
          }, status: :forbidden
        end

        payment = Payment.find(params[:id])
        Payments::Applicator.call(payment)
        render_resource(payment.reload, PaymentSerializer)
      end

      private

      def payment_params
        params.require(:payment).permit(:customer_id, :amount_cents, :payment_method)
      end
    end
  end
end
