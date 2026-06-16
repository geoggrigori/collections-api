require "rails_helper"

RSpec.describe RemittanceMatcher do
  let(:customer) { create(:customer) }

  before do
    create(:invoice, customer: customer, invoice_number: "INV-R1")
    create(:invoice, customer: customer, invoice_number: "INV-R2")
  end

  it "casa numeros de fatura citados no texto (heuristica)" do
    result = described_class.call(
      customer: customer,
      raw_text: "Pagamento da fatura INV-R1, obrigado.",
      amount_cents: 100_00
    )

    expect(result.source).to eq("heuristic")
    expect(result.invoice_numbers).to contain_exactly("INV-R1")
    expect(result.confidence).to be > 0
  end

  it "retorna confianca zero quando nada e reconhecido" do
    result = described_class.call(
      customer: customer,
      raw_text: "Segue pagamento referente ao mes passado.",
      amount_cents: 100_00
    )

    expect(result.invoice_numbers).to be_empty
    expect(result.confidence).to eq(0.0)
  end
end
