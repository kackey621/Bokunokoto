module Bkc
  class OperatorOverridesController < BaseController
    skip_before_action :ensure_vault_accessible!

    def create
      unless current_user.platform_operator?
        redirect_back fallback_location: bkc_dashboard_path,
          alert: "Only platform operators can open an override."
        return
      end

      vault = Vault.find_by(id: params[:vault_id])
      unless vault
        redirect_back fallback_location: bkc_dashboard_path, alert: "Vault not found."
        return
      end

      reason = params[:reason].to_s.strip
      if reason.blank?
        redirect_back fallback_location: bkc_dashboard_path, alert: "A reason is required to open an override."
        return
      end

      # Close any currently active override before opening a new one
      current_user.operator_overrides.active.each(&:close!)

      current_user.operator_overrides.create!(
        vault: vault,
        reason: reason,
        expires_at: Time.current + 30.minutes
      )

      AuditLog.create!(
        vault: vault,
        user: current_user,
        action: "operator_override",
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        occurred_at: Time.current,
        actor_role: "operator"
      )

      redirect_back fallback_location: bkc_dashboard_path,
        notice: "Operator override opened for #{vault.display_name}. Expires in 30 minutes."
    end

    def destroy
      override = current_user.operator_overrides.active.first

      unless override
        redirect_back fallback_location: bkc_dashboard_path, alert: "No active override to close."
        return
      end

      vault = override.vault
      override.close!

      AuditLog.create!(
        vault: vault,
        user: current_user,
        action: "operator_override_closed",
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        occurred_at: Time.current,
        actor_role: "operator"
      )

      redirect_back fallback_location: bkc_dashboard_path,
        notice: "Operator override closed for #{vault.display_name}."
    end
  end
end
