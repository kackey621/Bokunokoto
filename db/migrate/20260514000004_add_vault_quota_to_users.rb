class AddVaultQuotaToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :vault_quota, :integer, default: 3, null: false
  end
end
