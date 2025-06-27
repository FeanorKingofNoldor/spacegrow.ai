class RemoveApiTokenFromDevices < ActiveRecord::Migration[7.1]
  def change
    remove_column :devices, :api_token, :string
    add_reference :devices, :activation_token, foreign_key: { to_table: :device_activation_tokens }
  end
end
