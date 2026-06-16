class CreateCustomers < ActiveRecord::Migration[7.2]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :email
      t.string :external_ref, comment: "ID do cliente no ERP (NetSuite/Sage/Acumatica)"
      t.bigint :credit_limit_cents, null: false, default: 0
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :customers, :external_ref, unique: true, where: "external_ref IS NOT NULL"
    add_index :customers, :status
    add_check_constraint :customers, "credit_limit_cents >= 0", name: "credit_limit_non_negative"
  end
end
