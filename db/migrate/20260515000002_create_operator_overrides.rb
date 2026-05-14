class CreateOperatorOverrides < ActiveRecord::Migration[8.1]
  def change
    create_table :operator_overrides do |t|
      t.references :operator, null: false, foreign_key: { to_table: :users }
      t.references :vault, null: false, foreign_key: true
      t.string :reason, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :operator_overrides, [ :operator_id, :expires_at ]
  end
end
