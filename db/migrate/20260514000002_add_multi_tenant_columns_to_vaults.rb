class AddMultiTenantColumnsToVaults < ActiveRecord::Migration[8.1]
  def change
    add_column :vaults, :slug, :string
    add_column :vaults, :kind, :string, default: "personal", null: false
    add_column :vaults, :archived_at, :datetime

    add_index :vaults, :slug, unique: true, where: "slug IS NOT NULL"
    add_index :vaults, :archived_at
  end
end
