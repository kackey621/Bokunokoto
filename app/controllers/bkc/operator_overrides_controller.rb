module Bkc
  class OperatorOverridesController < BaseController
    skip_before_action :ensure_vault_accessible!
    before_action :require_operator!

    def new
      @vaults = Vault.active.order(:display_name)
    end

    def create
      p = override_params

      if p[:reason].blank?
        return redirect_to bkc_dashboard_path, alert: "reason is required to open an operator override."
      end

      vault = Vault.active.find(p[:vault_id])

      # Close any currently active override before opening a new one
      current_user.operator_overrides.active.each(&:close!)

      override = OperatorOverride.open!(
        operator: current_user,
        vault: vault,
        reason: p[:reason],
        duration: p[:duration_minutes]&.to_i&.minutes || OperatorOverride::DEFAULT_DURATION
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

      redirect_to bkc_dashboard_path,
        notice: "Operator override active for #{vault.display_name}. Expires in #{(override.expires_at - Time.current).ceil / 60} min."
    end

    def destroy
      override = current_user.operator_overrides.active.first

      if override
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

        redirect_to bkc_dashboard_path,
          notice: "Operator override closed for #{vault.display_name}."
      else
        redirect_to bkc_dashboard_path, alert: "No active override to close."
      end
    end

    private

    def require_operator!
      unless current_user.platform_operator?
        redirect_to bkc_dashboard_path, alert: "Only platform operators can open an override."
      end
    end

    def override_params
      params.permit(:vault_id, :reason, :duration_minutes)
    end
  end
end
