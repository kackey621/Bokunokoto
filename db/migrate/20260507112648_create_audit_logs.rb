class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :content, null: false, foreign_key: true
      t.string  :action,      null: false
      t.string  :ip_address
      t.text    :user_agent
      t.decimal :latitude,    precision: 10, scale: 7
      t.decimal :longitude,   precision: 10, scale: 7
      t.string  :face_snapshot_url
      t.datetime :occurred_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.timestamps null: false
    end

    add_index :audit_logs, [ :user_id, :occurred_at ]
    add_index :audit_logs, [ :content_id, :occurred_at ]
  end
end
