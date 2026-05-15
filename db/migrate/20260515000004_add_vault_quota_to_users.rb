class AddVaultQuotaToUsers < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:users, :vault_quota)
      add_column :users, :vault_quota, :integer, default: 3, null: false
    end
  end
end
