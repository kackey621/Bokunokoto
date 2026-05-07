class AllowNullContentIdInAuditLogs < ActiveRecord::Migration[8.1]
  def change
    change_column_null :audit_logs, :content_id, true
  end
end
