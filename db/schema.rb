# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_06_16_220655) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email"
    t.string "external_ref", comment: "ID do cliente no ERP (NetSuite/Sage/Acumatica)"
    t.bigint "credit_limit_cents", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_ref"], name: "index_customers_on_external_ref", unique: true, where: "(external_ref IS NOT NULL)"
    t.index ["status"], name: "index_customers_on_status"
    t.check_constraint "credit_limit_cents >= 0", name: "credit_limit_non_negative"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "invoice_number", null: false
    t.bigint "amount_cents", null: false
    t.bigint "balance_cents", null: false, comment: "Saldo em aberto; comeca igual a amount_cents"
    t.string "currency", default: "USD", null: false
    t.date "issued_on", null: false
    t.date "due_date", null: false
    t.integer "status", default: 0, null: false
    t.string "external_ref", comment: "ID do documento no ERP"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "invoice_number"], name: "index_invoices_on_customer_id_and_invoice_number", unique: true
    t.index ["customer_id", "status"], name: "index_invoices_on_customer_id_and_status"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["due_date"], name: "index_invoices_on_due_date"
    t.index ["status"], name: "index_invoices_on_status"
    t.check_constraint "amount_cents >= 0", name: "amount_non_negative"
    t.check_constraint "balance_cents >= 0 AND balance_cents <= amount_cents", name: "balance_within_amount"
  end

  create_table "payment_applications", force: :cascade do |t|
    t.bigint "payment_id", null: false
    t.bigint "invoice_id", null: false
    t.bigint "amount_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_payment_applications_on_invoice_id"
    t.index ["payment_id", "invoice_id"], name: "index_payment_applications_on_payment_id_and_invoice_id", unique: true
    t.index ["payment_id"], name: "index_payment_applications_on_payment_id"
    t.check_constraint "amount_cents > 0", name: "application_amount_positive"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "amount_cents", null: false
    t.integer "payment_method", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "external_ref", comment: "ID do PaymentIntent no Stripe"
    t.datetime "received_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "status"], name: "index_payments_on_customer_id_and_status"
    t.index ["customer_id"], name: "index_payments_on_customer_id"
    t.index ["external_ref"], name: "index_payments_on_external_ref", unique: true, where: "(external_ref IS NOT NULL)"
    t.check_constraint "amount_cents > 0", name: "payment_amount_positive"
  end

  add_foreign_key "invoices", "customers"
  add_foreign_key "payment_applications", "invoices"
  add_foreign_key "payment_applications", "payments"
  add_foreign_key "payments", "customers"
end
