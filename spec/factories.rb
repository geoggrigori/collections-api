FactoryBot.define do
  factory :customer do
    sequence(:name) { |n| "Distribuidora #{n}" }
    sequence(:external_ref) { |n| "ERP-#{n}" }
    credit_limit_cents { 1_000_000 }
    status { :active }
  end

  factory :invoice do
    customer
    sequence(:invoice_number) { |n| "INV-#{n}" }
    amount_cents { 100_00 }
    currency { "USD" }
    issued_on { Date.current - 30 }
    due_date { Date.current - 10 }
    status { :open }
    # balance_cents e definido automaticamente (= amount_cents) no callback.
  end

  factory :payment do
    customer
    amount_cents { 100_00 }
    payment_method { :ach }
    status { :pending }
  end
end
