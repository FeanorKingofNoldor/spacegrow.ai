class AddAlertStatusToDevices < ActiveRecord::Migration[7.1]
  def change
    add_column :devices, :alert_status, :string, default: 'normal'
    add_index :devices, :alert_status
  end
end