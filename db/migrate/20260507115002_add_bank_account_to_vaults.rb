class AddBankAccountToVaults < ActiveRecord::Migration[8.0]
  def change
    add_column :vaults, :bank_account_info, :text
  end
end
