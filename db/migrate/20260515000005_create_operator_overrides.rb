class CreateOperatorOverrides < ActiveRecord::Migration[7.2]
  def change
    create_table :operator_overrides do |t|
      t.references :operator, null: false, foreign_key: { to_table: :users }
      t.references :vault, null: false, foreign_key: true
      t.text :reason, null: false
      t.datetime :expires_at, null: false
      t.datetime :closed_at
      t.timestamps
    end

    add_index :operator_overrides, [ :vault_id, :expires_at ]
    add_index :operator_overrides, [ :operator_id, :closed_at ]
  end
end
