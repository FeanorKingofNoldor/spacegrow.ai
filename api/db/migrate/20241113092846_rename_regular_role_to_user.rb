# db/migrate/[timestamp]_rename_regular_role_to_user.rb
class RenameRegularRoleToUser < ActiveRecord::Migration[7.1]
  def up
    User.where(role: 'regular').update_all(role: 'user')
  end

  def down
    User.where(role: 'user').update_all(role: 'regular')
  end
end