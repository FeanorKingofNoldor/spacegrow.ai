class AddMessageToCommandLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :command_logs, :message, :string
  end
end