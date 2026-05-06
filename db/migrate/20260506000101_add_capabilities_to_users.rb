class AddCapabilitiesToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :can_create_vault, :boolean, null: false, default: true
    add_column :users, :bkc_access, :boolean, null: false, default: false
    add_column :users, :is_beta_tester, :boolean, null: false, default: false
  end
end
