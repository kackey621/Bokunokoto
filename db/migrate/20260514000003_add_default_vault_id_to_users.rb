class AddDefaultVaultIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :default_vault_id, :bigint
    add_index :users, :default_vault_id
    add_foreign_key :users, :vaults, column: :default_vault_id, on_delete: :nullify
  end
end
