require "rails_helper"

RSpec.describe "API V1 Payments" do
  let(:customer) { create(:customer) }

  describe "POST /api/v1/payments e settle" do
    it "cria o pagamento e concilia ao liquidar" do
      create(:invoice, customer: customer, amount_cents: 100_00, due_date: Date.current - 5)

      post "/api/v1/payments", params: {
        payment: { customer_id: customer.id, amount_cents: 100_00, payment_method: "ach" }
      }
      expect(response).to have_http_status(:created)
      payment_id = response.parsed_body.dig("data", "id")

      post "/api/v1/payments/#{payment_id}/settle"
      expect(response).to have_http_status(:ok)
      body = response.parsed_body["data"]
      expect(body["status"]).to eq("succeeded")
      expect(body["applied_cents"]).to eq(100_00)
    end
  end

  describe "POST /api/v1/remittances" do
    it "concilia uma remessa em texto livre" do
      create(:invoice, customer: customer, invoice_number: "INV-X9", amount_cents: 100_00)

      post "/api/v1/remittances", params: {
        remittance: { customer_id: customer.id, amount_cents: 100_00,
                      raw_text: "pagamento da INV-X9" }
      }

      expect(response).to have_http_status(:created)
      body = response.parsed_body["data"]
      expect(body["status"]).to eq("matched")
      expect(body["matched_invoice_numbers"]).to include("INV-X9")
    end
  end

  describe "validacao" do
    it "retorna 422 com envelope de erro" do
      post "/api/v1/customers", params: { customer: { email: "x@y.com" } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("unprocessable_entity")
    end
  end
end
