module Api
  module V1
    module Customers
      # Faturas aninhadas em um cliente: GET /api/v1/customers/:customer_id/invoices
      class InvoicesController < BaseController
        def index
          customer = Customer.find(params[:customer_id])
          scope = customer.invoices
          scope = scope.where(status: params[:status]) if params[:status].present?
          render_collection(scope.order(due_date: :asc), InvoiceSerializer)
        end
      end
    end
  end
end
