class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :vault, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      # Intentionally no FK constraint on content_id — AuditLog rows are
      # immutable, so we cannot nullify or cascade when a Content is deleted.
      # Treat content_id as a denormalized reference; reconcile in queries.
      t.references :content, null: true

      t.string :action, null: false
      t.string :ip_address
      t.string :user_agent
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :face_snapshot_url
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :audit_logs, [ :vault_id, :occurred_at ]
    add_index :audit_logs, [ :user_id, :occurred_at ]
    add_index :audit_logs, :action
  end
end
