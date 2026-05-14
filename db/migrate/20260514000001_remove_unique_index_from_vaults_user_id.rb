class RemoveUniqueIndexFromVaultsUserId < ActiveRecord::Migration[8.1]
  def up
    remove_index :vaults, :user_id
    add_index :vaults, :user_id
  end

  def down
    remove_index :vaults, :user_id
    add_index :vaults, :user_id, unique: true
  end
end
