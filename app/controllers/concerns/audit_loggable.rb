module AuditLoggable
  extend ActiveSupport::Concern

  private

  def log_audit!(action:, vault:, content: nil, user: nil)
    user ||= current_user
    return unless user && vault

    AuditLog.create!(
      vault: vault,
      user: user,
      content: content,
      action: action,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      occurred_at: Time.current
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("AuditLog write failed: #{e.message}")
  end
end
