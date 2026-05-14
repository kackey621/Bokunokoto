class AddActorRoleToAuditLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_logs, :actor_role, :string
    add_index :audit_logs, :actor_role
  end
end
