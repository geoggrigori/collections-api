require "rails_helper"

RSpec.describe Payments::Applicator do
  let(:customer) { create(:customer) }

  it "aplica o pagamento por FIFO (vencimento mais antigo primeiro)" do
    a = create(:invoice, customer: customer, amount_cents: 100_00, due_date: Date.current - 30)
    b = create(:invoice, customer: customer, amount_cents: 200_00, due_date: Date.current - 10)
    c = create(:invoice, customer: customer, amount_cents: 300_00, due_date: Date.current + 10)
    payment = create(:payment, customer: customer, amount_cents: 250_00)

    described_class.call(payment)

    expect(a.reload).to be_paid
    expect(b.reload.balance_cents).to eq(50_00)
    expect(b.reload).to be_partially_paid
    expect(c.reload).to be_open
    expect(payment.reload).to be_succeeded
  end

  it "restringe a aplicacao a um scope de faturas" do
    a = create(:invoice, customer: customer, amount_cents: 100_00, due_date: Date.current - 30)
    b = create(:invoice, customer: customer, amount_cents: 200_00, due_date: Date.current - 10)
    payment = create(:payment, customer: customer, amount_cents: 100_00)

    described_class.call(payment, scope: customer.invoices.where(invoice_number: b.invoice_number))

    expect(a.reload).to be_open
    expect(b.reload.balance_cents).to eq(100_00)
  end
end
