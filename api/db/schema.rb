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

ActiveRecord::Schema[7.1].define(version: 2025_06_27_211318) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "command_logs", force: :cascade do |t|
    t.bigint "device_id", null: false
    t.string "command", null: false
    t.jsonb "args", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "message"
    t.index ["device_id"], name: "index_command_logs_on_device_id"
  end

  create_table "device_activation_tokens", force: :cascade do |t|
    t.bigint "device_type_id", null: false
    t.bigint "order_id", null: false
    t.bigint "device_id"
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "activated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_device_activation_tokens_on_device_id"
    t.index ["device_type_id"], name: "index_device_activation_tokens_on_device_type_id"
    t.index ["expires_at"], name: "index_device_activation_tokens_on_expires_at"
    t.index ["order_id"], name: "index_device_activation_tokens_on_order_id"
    t.index ["token"], name: "index_device_activation_tokens_on_token", unique: true
  end

  create_table "device_sensors", force: :cascade do |t|
    t.bigint "device_id", null: false
    t.bigint "sensor_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "consecutive_missing_readings", default: 0, null: false
    t.string "current_status"
    t.index ["consecutive_missing_readings"], name: "index_device_sensors_on_consecutive_missing_readings"
    t.index ["device_id", "sensor_type_id"], name: "index_device_sensors_on_device_id_and_sensor_type_id", unique: true
    t.index ["device_id"], name: "index_device_sensors_on_device_id"
    t.index ["sensor_type_id"], name: "index_device_sensors_on_sensor_type_id"
  end

  create_table "device_types", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.jsonb "configuration", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["configuration"], name: "index_device_types_on_configuration", using: :gin
    t.index ["name"], name: "index_device_types_on_name", unique: true
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "status", default: "pending"
    t.datetime "last_connection"
    t.jsonb "configuration", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "device_type_id"
    t.string "alert_status", default: "normal"
    t.bigint "activation_token_id"
    t.bigint "order_id"
    t.bigint "current_preset_id"
    t.index ["activation_token_id"], name: "index_devices_on_activation_token_id"
    t.index ["alert_status"], name: "index_devices_on_alert_status"
    t.index ["current_preset_id"], name: "index_devices_on_current_preset_id"
    t.index ["device_type_id", "status"], name: "index_devices_on_device_type_id_and_status"
    t.index ["device_type_id"], name: "index_devices_on_device_type_id"
    t.index ["last_connection"], name: "index_devices_on_last_connection"
    t.index ["status"], name: "index_devices_on_status"
    t.index ["user_id", "alert_status"], name: "index_devices_on_user_id_and_alert_status"
    t.index ["user_id", "name"], name: "index_devices_on_user_id_and_name", unique: true
    t.index ["user_id", "status"], name: "index_devices_on_user_id_and_status"
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "line_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_line_items_on_order_id_and_product_id"
    t.index ["order_id"], name: "index_line_items_on_order_id"
    t.index ["product_id"], name: "index_line_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "stripe_monthly_price_id"
    t.string "stripe_yearly_price_id"
    t.integer "device_limit", null: false
    t.decimal "monthly_price", precision: 10, scale: 2, null: false
    t.decimal "yearly_price", precision: 10, scale: 2, null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_monthly_price_id"], name: "index_plans_on_stripe_monthly_price_id", unique: true
    t.index ["stripe_yearly_price_id"], name: "index_plans_on_stripe_yearly_price_id", unique: true
  end

  create_table "presets", force: :cascade do |t|
    t.bigint "device_type_id", null: false
    t.string "name", null: false
    t.jsonb "settings", default: {}, null: false
    t.boolean "is_user_defined", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "device_id"
    t.index ["device_id"], name: "index_presets_on_device_id"
    t.index ["device_type_id", "device_id", "name", "user_id"], name: "index_presets_on_type_device_name_user", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["device_type_id", "name", "user_id"], name: "index_presets_on_device_type_name_user", unique: true, where: "(user_id IS NOT NULL)"
    t.index ["device_type_id", "name"], name: "index_presets_on_device_type_and_name_predefined", unique: true, where: "(user_id IS NULL)"
    t.index ["device_type_id"], name: "index_presets_on_device_type_id"
    t.index ["user_id"], name: "index_presets_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "stripe_price_id"
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.bigint "device_type_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stock_quantity", default: 0, null: false
    t.boolean "featured", default: false, null: false
    t.text "detailed_description"
    t.integer "low_stock_threshold", default: 5, null: false
    t.index ["active"], name: "index_products_on_active"
    t.index ["device_type_id"], name: "index_products_on_device_type_id"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["stock_quantity"], name: "index_products_on_stock_quantity"
  end

  create_table "sensor_data", force: :cascade do |t|
    t.bigint "device_sensor_id", null: false
    t.datetime "timestamp", null: false
    t.float "value", null: false
    t.boolean "is_valid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "zone"
    t.index ["device_sensor_id", "timestamp", "is_valid"], name: "idx_sensor_data_device_time_valid"
    t.index ["device_sensor_id", "timestamp"], name: "idx_sensor_data_device_time"
    t.index ["device_sensor_id", "zone"], name: "index_sensor_data_on_device_sensor_and_zone"
    t.index ["device_sensor_id"], name: "index_sensor_data_on_device_sensor_id"
    t.index ["is_valid", "timestamp"], name: "idx_sensor_data_validity_time"
    t.index ["timestamp"], name: "idx_sensor_data_timestamp"
    t.index ["timestamp"], name: "index_sensor_data_on_timestamp"
  end

  create_table "sensor_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "unit", null: false
    t.float "min_value", null: false
    t.float "max_value", null: false
    t.float "error_low_min", null: false
    t.float "error_low_max", null: false
    t.float "error_high_min", null: false
    t.float "error_high_max", null: false
    t.float "warning_low_min", null: false
    t.float "warning_low_max", null: false
    t.float "warning_high_min", null: false
    t.float "warning_high_max", null: false
    t.float "normal_min", null: false
    t.float "normal_max", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sensor_types_on_name", unique: true
  end

  create_table "subscription_devices", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.bigint "device_id", null: false
    t.decimal "monthly_cost", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_subscription_devices_on_device_id"
    t.index ["subscription_id", "device_id"], name: "index_subscription_devices_on_subscription_id_and_device_id", unique: true
    t.index ["subscription_id"], name: "index_subscription_devices_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plan_id", null: false
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "status"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.string "interval", default: "month"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "additional_device_slots", default: 0, null: false
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_customer_id"], name: "index_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "role", default: 0, null: false
    t.integer "devices_count", default: 0
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "timezone", default: "UTC", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["timezone"], name: "index_users_on_timezone"
  end

  add_foreign_key "command_logs", "devices"
  add_foreign_key "device_activation_tokens", "device_types"
  add_foreign_key "device_activation_tokens", "devices"
  add_foreign_key "device_activation_tokens", "orders"
  add_foreign_key "device_sensors", "devices"
  add_foreign_key "device_sensors", "sensor_types"
  add_foreign_key "devices", "device_activation_tokens", column: "activation_token_id", on_delete: :nullify
  add_foreign_key "devices", "device_types"
  add_foreign_key "devices", "presets", column: "current_preset_id"
  add_foreign_key "devices", "users"
  add_foreign_key "line_items", "orders"
  add_foreign_key "line_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "presets", "device_types"
  add_foreign_key "presets", "devices"
  add_foreign_key "presets", "users"
  add_foreign_key "products", "device_types"
  add_foreign_key "sensor_data", "device_sensors"
  add_foreign_key "subscription_devices", "devices"
  add_foreign_key "subscription_devices", "subscriptions"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "users"
end
