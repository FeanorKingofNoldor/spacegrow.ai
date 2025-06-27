# db/migrate/XXXXXX_create_device_activation_tokens.rb
class CreateDeviceActivationTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :device_activation_tokens do |t|
      t.references :device_type, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :device, null: true, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :activated_at

      t.timestamps

      t.index :token, unique: true
      t.index :expires_at
    end
  end
end