class CreateIncidents < ActiveRecord::Migration[8.0]
  def change
    create_table :incidents do |t|
      t.references :vault, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :incident_type, null: false
      t.text :description
      t.integer :severity, default: 0
      t.json :context
      t.boolean :resolved, default: false
      t.datetime :resolved_at
      t.timestamps
    end

    add_index :incidents, :incident_type
    add_index :incidents, :severity
    add_index :incidents, [ :vault_id, :created_at ]
  end
end
