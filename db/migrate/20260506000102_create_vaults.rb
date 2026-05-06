class CreateVaults < ActiveRecord::Migration[8.1]
  def change
    create_table :vaults do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :display_name
      t.text :bio

      t.timestamps
    end
  end
end
