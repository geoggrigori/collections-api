require "rails_helper"

RSpec.describe Invoice do
  it "define balance_cents igual a amount_cents na criacao" do
    invoice = create(:invoice, amount_cents: 500_00)
    expect(invoice.balance_cents).to eq(500_00)
  end

  describe "#apply_payment_cents" do
    it "abate parcialmente e marca como partially_paid" do
      invoice = create(:invoice, amount_cents: 200_00)
      applied = invoice.apply_payment_cents(50_00)
      expect(applied).to eq(50_00)
      expect(invoice.balance_cents).to eq(150_00)
      expect(invoice).to be_partially_paid
    end

    it "nao aplica mais que o saldo e marca como paid" do
      invoice = create(:invoice, amount_cents: 100_00)
      applied = invoice.apply_payment_cents(150_00)
      expect(applied).to eq(100_00)
      expect(invoice.balance_cents).to eq(0)
      expect(invoice).to be_paid
    end
  end

  describe "#past_due?" do
    it "e true quando em aberto e vencida" do
      expect(create(:invoice, due_date: Date.current - 1)).to be_past_due
    end

    it "e false quando quitada" do
      invoice = create(:invoice, amount_cents: 100_00, due_date: Date.current - 1)
      invoice.apply_payment_cents(100_00)
      invoice.save!
      expect(invoice).not_to be_past_due
    end
  end

  it "valida unicidade de invoice_number por cliente" do
    invoice = create(:invoice)
    dup = build(:invoice, customer: invoice.customer, invoice_number: invoice.invoice_number)
    expect(dup).not_to be_valid
  end
end
