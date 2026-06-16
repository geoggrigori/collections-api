class CreateRemittances < ActiveRecord::Migration[7.2]
  def change
    create_table :remittances do |t|
      t.references :customer, null: false, foreign_key: true
      t.text :raw_text, null: false
      t.bigint :amount_cents, null: false
      t.integer :status, null: false, default: 0
      t.float :confidence
      t.references :payment, null: true, foreign_key: true
      t.string :match_source
      t.jsonb :matched_invoice_numbers, null: false, default: []

      t.timestamps
    end

    add_index :remittances, %i[customer_id status]
    add_check_constraint :remittances, "amount_cents > 0", name: "remittance_amount_positive"
  end
end
