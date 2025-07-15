class AddDisplayNameToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :display_name, :string, limit: 50
    add_index :users, :display_name # Optional: for faster searches
  end
end