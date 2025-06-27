class CreateCommandLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :command_logs do |t|
      t.references :device, null: false, foreign_key: true
      t.string :command, null: false
      t.jsonb :args, default: {}, null: false
      t.string :status, default: 'pending', null: false
      t.timestamps
    end
  end
end