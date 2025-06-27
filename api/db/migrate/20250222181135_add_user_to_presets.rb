class AddUserToPresets < ActiveRecord::Migration[7.1]
  def change
    add_reference :presets, :user, foreign_key: true, null: true # Null for predefined presets
  end
end