class UpdateActivationTokenForeignKeyOnDevices < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :devices, :device_activation_tokens
    add_foreign_key :devices, :device_activation_tokens, column: :activation_token_id, on_delete: :nullify
  end
end
