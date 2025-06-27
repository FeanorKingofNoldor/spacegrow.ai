class CreateDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :devices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :api_token
      t.string :status, default: 'pending'
      t.datetime :last_connection
      t.jsonb :configuration, default: {}

      t.timestamps
    end

    add_index :devices, [:user_id, :name], unique: true
    add_index :devices, :api_token, unique: true
    add_index :devices, :status
    add_index :devices, :last_connection
  end
end