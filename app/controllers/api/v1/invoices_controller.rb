module Api
  module V1
    class InvoicesController < BaseController
      # GET /api/v1/invoices?status=overdue&customer_id=1&overdue=true
      def index
        scope = Invoice.all
        scope = scope.where(customer_id: params[:customer_id]) if params[:customer_id].present?
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.past_due if params[:overdue] == "true"
        render_collection(scope.order(due_date: :asc), InvoiceSerializer)
      end

      # GET /api/v1/invoices/:id
      def show
        invoice = Invoice.find(params[:id])
        render_resource(invoice, InvoiceSerializer)
      end

      # POST /api/v1/invoices
      def create
        invoice = Invoice.create!(invoice_params)
        render_resource(invoice, InvoiceSerializer, status: :created)
      end

      private

      def invoice_params
        params.require(:invoice).permit(
          :customer_id, :invoice_number, :amount_cents,
          :currency, :issued_on, :due_date, :external_ref
        )
      end
    end
  end
end
