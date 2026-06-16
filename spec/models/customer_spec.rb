require "rails_helper"

RSpec.describe Customer do
  it "soma o saldo em aberto das faturas" do
    customer = create(:customer, credit_limit_cents: 1_000_00)
    create(:invoice, customer: customer, amount_cents: 300_00)
    create(:invoice, customer: customer, amount_cents: 200_00)

    expect(customer.outstanding_balance_cents).to eq(500_00)
    expect(customer.available_credit_cents).to eq(500_00)
  end

  it "credito disponivel fica negativo ao estourar o limite" do
    customer = create(:customer, credit_limit_cents: 100_00)
    create(:invoice, customer: customer, amount_cents: 250_00)
    expect(customer.available_credit_cents).to eq(-150_00)
  end
end
