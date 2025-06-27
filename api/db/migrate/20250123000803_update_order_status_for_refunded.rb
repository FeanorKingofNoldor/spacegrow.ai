class UpdateOrderStatusForRefunded < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE orders SET status = 'refunded' WHERE status = 'cancelled';
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE orders SET status = 'cancelled' WHERE status = 'refunded';
        SQL
      end
    end
  end
end
