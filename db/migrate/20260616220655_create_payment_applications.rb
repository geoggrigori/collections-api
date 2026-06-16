class CreatePaymentApplications < ActiveRecord::Migration[7.2]
  def change
    create_table :payment_applications do |t|
      t.references :payment, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true
      t.bigint :amount_cents, null: false

      t.timestamps
    end

    add_index :payment_applications, %i[payment_id invoice_id], unique: true
    add_check_constraint :payment_applications, "amount_cents > 0", name: "application_amount_positive"
  end
end
