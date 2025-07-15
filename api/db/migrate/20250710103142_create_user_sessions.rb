class CreateUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :jti, null: false, index: { unique: true }
      t.text :device_info
      t.string :ip_address
      t.datetime :created_at, null: false
      t.datetime :last_active_at, null: false
      t.datetime :expires_at, null: false
      t.boolean :is_current, default: false
      
      t.index [:user_id, :is_current]
      t.index [:expires_at]
      t.index [:last_active_at]
      t.index [:ip_address]
    end
  end
end