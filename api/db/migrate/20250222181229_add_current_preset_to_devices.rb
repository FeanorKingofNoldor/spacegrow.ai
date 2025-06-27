class AddCurrentPresetToDevices < ActiveRecord::Migration[7.1]
  def change
    add_reference :devices, :current_preset, foreign_key: { to_table: :presets }, null: true
  end
end