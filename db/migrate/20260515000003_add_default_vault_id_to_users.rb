class AddDefaultVaultIdToUsers < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:users, :default_vault_id)
      add_column :users, :default_vault_id, :bigint
      add_index :users, :default_vault_id
      add_foreign_key :users, :vaults, column: :default_vault_id, on_delete: :nullify
    end
  end
end
