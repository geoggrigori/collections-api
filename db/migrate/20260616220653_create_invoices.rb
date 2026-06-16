class CreateInvoices < ActiveRecord::Migration[7.2]
  def change
    create_table :invoices do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :invoice_number, null: false
      t.bigint :amount_cents, null: false
      t.bigint :balance_cents, null: false, comment: "Saldo em aberto; comeca igual a amount_cents"
      t.string :currency, null: false, default: "USD"
      t.date :issued_on, null: false
      t.date :due_date, null: false
      t.integer :status, null: false, default: 0
      t.string :external_ref, comment: "ID do documento no ERP"

      t.timestamps
    end

    add_index :invoices, %i[customer_id invoice_number], unique: true
    add_index :invoices, %i[customer_id status]
    add_index :invoices, :due_date
    add_index :invoices, :status
    add_check_constraint :invoices, "amount_cents >= 0", name: "amount_non_negative"
    add_check_constraint :invoices, "balance_cents >= 0 AND balance_cents <= amount_cents", name: "balance_within_amount"
  end
end
