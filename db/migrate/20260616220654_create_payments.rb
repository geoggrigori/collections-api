class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :customer, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.integer :payment_method, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :external_ref, comment: "ID do PaymentIntent no Stripe"
      t.datetime :received_at

      t.timestamps
    end

    add_index :payments, :external_ref, unique: true, where: "external_ref IS NOT NULL"
    add_index :payments, %i[customer_id status]
    add_check_constraint :payments, "amount_cents > 0", name: "payment_amount_positive"
  end
end
