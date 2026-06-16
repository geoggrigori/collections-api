module Api
  module V1
    class RemittancesController < BaseController
      CONFIDENCE_THRESHOLD = 0.5

      # GET /api/v1/remittances?customer_id=1&status=needs_review
      def index
        scope = Remittance.all
        scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        render_collection(scope.order(created_at: :desc), RemittanceSerializer)
      end

      # GET /api/v1/remittances/:id
      def show
        render_resource(Remittance.find(params[:id]), RemittanceSerializer)
      end

      # POST /api/v1/remittances
      # Recebe um aviso de remessa em texto livre, concilia com as faturas em
      # aberto (LLM ou heuristica) e, se confiante, cria o pagamento e aplica.
      def create
        customer = Customer.find(remittance_params[:customer_id])
        remittance = Remittance.create!(
          customer: customer,
          raw_text: remittance_params[:raw_text],
          amount_cents: remittance_params[:amount_cents]
        )

        result = RemittanceMatcher.call(
          customer: customer,
          raw_text: remittance.raw_text,
          amount_cents: remittance.amount_cents
        )
        reconcile(remittance, result)

        render_resource(remittance.reload, RemittanceSerializer, status: :created)
      end

      private

      def reconcile(remittance, result)
        remittance.assign_attributes(
          matched_invoice_numbers: result.invoice_numbers,
          confidence: result.confidence,
          match_source: result.source
        )

        scope = remittance.customer.invoices.unpaid
                          .where(invoice_number: result.invoice_numbers)

        if result.confidence >= CONFIDENCE_THRESHOLD && scope.exists?
          payment = remittance.customer.payments.create!(
            amount_cents: remittance.amount_cents,
            payment_method: :ach,
            status: :pending,
            external_ref: "remit_#{remittance.id}"
          )
          Payments::Applicator.call(payment, scope: scope)
          remittance.payment = payment
          remittance.status = :matched
        else
          remittance.status = :needs_review
        end

        remittance.save!
      end

      def remittance_params
        params.require(:remittance).permit(:customer_id, :raw_text, :amount_cents)
      end
    end
  end
end
