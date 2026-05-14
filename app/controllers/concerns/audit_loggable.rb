module AuditLoggable
  extend ActiveSupport::Concern

  private

  def log_audit!(action:, vault:, content: nil, user: nil, actor_role: nil)
    user ||= current_user
    return unless user && vault

    AuditLog.create!(
      vault: vault,
      user: user,
      content: content,
      action: action,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      occurred_at: Time.current,
      actor_role: actor_role
    )
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.warn("AuditLog write failed: #{e.message}")
  end
end
