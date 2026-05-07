class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions do |t|
      t.references :vault, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :granted_level, null: false, default: 0
      t.string :status, null: false, default: "active"
      t.text :relationship_context
      t.text :owner_notes

      t.timestamps
    end

    add_index :permissions, [ :vault_id, :user_id ], unique: true
  end
end
