module Api
  module V1
    class CustomersController < BaseController
      # GET /api/v1/customers?status=delinquent&q=acme
      def index
        scope = Customer.all
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where("name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
        scope = scope.with_open_balance if params[:with_open_balance] == "true"
        render_collection(scope.order(:id), CustomerSerializer)
      end

      # GET /api/v1/customers/:id
      def show
        customer = Customer.find(params[:id])
        render_resource(customer, CustomerSerializer)
      end

      # POST /api/v1/customers
      def create
        customer = Customer.create!(customer_params)
        render_resource(customer, CustomerSerializer, status: :created)
      end

      private

      def customer_params
        params.require(:customer).permit(
          :name, :email, :external_ref, :status, :credit_limit_cents
        )
      end
    end
  end
end
